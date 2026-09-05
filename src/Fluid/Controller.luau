--!nonstrict
local LinearValue = require("../Utility/LinearValue")
local SpringMath = require("./SpringMath")
local Tokens = require("./MotionTokens")
local Easing = require("./Easing")

local Controller = {}
Controller.__index = Controller
local SUPPORTED = { number = true, Vector2 = true, Vector3 = true, UDim = true, UDim2 = true, Color3 = true }

local function finite(value, label)
	assert(type(value) == "number" and math.abs(value) < math.huge, label .. " must be finite")
	return value
end

local function encode(value)
	assert(SUPPORTED[typeof(value)], "Fluid supports number, Vector2, Vector3, UDim, UDim2 and Color3")
	local linear = LinearValue(value)
	for _, component in linear.values do
		finite(component, "motion value")
	end
	return linear
end

local function transition(config)
	config = config or Tokens.Spring.smooth
	local result = table.clone(config)
	result.delay = finite(config.delay or 0, "delay")
	assert(result.delay >= 0, "delay must be non-negative")
	if config.duration ~= nil then
		result.duration = finite(config.duration, "duration")
		assert(result.duration >= 0, "duration must be non-negative")
		result.ease = config.ease or Easing.standard
		assert(type(result.ease) == "function", "ease must be a function")
	else
		result.speed = config.speed or Tokens.Spring.smooth.speed
		result.damper = if config.damper == nil then Tokens.Spring.smooth.damper else config.damper
		SpringMath.coefficients(result.speed, result.damper, 0)
		result.positionThreshold = finite(config.positionThreshold or Tokens.Precision.position, "positionThreshold")
		result.velocityThreshold = finite(config.velocityThreshold or Tokens.Precision.velocity, "velocityThreshold")
		assert(result.positionThreshold > 0 and result.velocityThreshold > 0, "rest thresholds must be positive")
	end
	return result
end

function Controller.new(initial, runtime, listener)
	local self = setmetatable({
		channels = {},
		ordered = {},
		runtime = runtime,
		listener = listener,
		generation = 0,
		queue = {},
		cursor = 1,
		time = 0,
		reducedMotion = false,
	}, Controller)
	for key, value in initial do
		local linear = encode(value)
		local channel = {
			key = key,
			kind = typeof(value),
			current = linear,
			goal = table.clone(linear.values),
			origin = table.clone(linear.values),
			velocity = table.create(#linear.values, 0),
			active = false,
			dirty = false,
		}
		self.channels[key] = channel
		table.insert(self.ordered, channel)
	end
	assert(#self.ordered > 0, "motion needs at least one property")
	return self
end

function Controller:_validate(goals)
	local encoded = {}
	for key, value in goals do
		local channel = self.channels[key]
		assert(channel, `unknown motion property {key}; declare it in initial values`)
		assert(typeof(value) == channel.kind, `type changed for motion property {key}`)
		encoded[key] = encode(value).values
	end
	return encoded
end

function Controller:_apply(encoded, config)
	for key, values in encoded do
		local channel = self.channels[key]
		channel.config = config
		channel.elapsed = 0
		channel.remainingDelay = config.delay
		channel.active = true
		for i, value in values do
			channel.origin[i] = channel.current.values[i]
			channel.goal[i] = value
			-- Spring retargets preserve the existing velocity. An eased track
			-- deliberately starts a new curve; use a spring for interruptions.
			if config.duration ~= nil then
				channel.velocity[i] = 0
			end
		end
	end
end

function Controller:_flush()
	local generation = self.generation
	for _, channel in self.ordered do
		if channel.dirty then
			channel.dirty = false
			if self.listener then
				local value = if channel.kind == "number" then channel.current.values[1] else channel.current:toValue()
				self.listener(channel.key, value)
			end
			if generation ~= self.generation then
				break
			end
		end
	end
end

function Controller:_advance(dt)
	for _, channel in self.ordered do
		if not channel.active then
			continue
		end
		local elapsed = dt
		if channel.remainingDelay > 0 then
			local consumed = math.min(elapsed, channel.remainingDelay)
			channel.remainingDelay -= consumed
			elapsed -= consumed
			if elapsed <= 0 then
				continue
			end
		end
		local config = channel.config
		local current, goal, velocity = channel.current.values, channel.goal, channel.velocity
		local settled = true
		if config.duration ~= nil then
			channel.elapsed += elapsed
			local alpha = if config.duration == 0 then 1 else math.min(1, channel.elapsed / config.duration)
			local eased = config.ease(alpha)
			finite(eased, "easing result")
			for i, value in current do
				local position = channel.origin[i] + (goal[i] - channel.origin[i]) * eased
				velocity[i] = if elapsed > 0 then (position - value) / elapsed else 0
				current[i] = position
			end
			settled = alpha == 1
		else
			-- Share coefficients across properties with the same transition.
			if config.dt ~= elapsed then
				config.dt = elapsed
				config.a, config.b, config.c, config.d = SpringMath.coefficients(config.speed, config.damper, elapsed)
			end
			for i, value in current do
				local displacement = value - goal[i]
				local position = goal[i] + config.a * displacement + config.b * velocity[i]
				local speed = config.c * displacement + config.d * velocity[i]
				current[i], velocity[i] = position, speed
				if
					math.abs(position - goal[i]) > config.positionThreshold
					or math.abs(speed) > config.velocityThreshold
				then
					settled = false
				end
			end
		end
		if settled then
			channel.active = false
			for i, value in goal do
				current[i], velocity[i] = value, 0
			end
		end
		channel.dirty = true
	end
end

function Controller:_isActive()
	if self.cursor <= #self.queue then
		return true
	end
	for _, channel in self.ordered do
		if channel.active then
			return true
		end
	end
	return false
end

function Controller:_step(dt)
	local endTime = self.time + dt
	while self.cursor <= #self.queue do
		local cue = self.queue[self.cursor]
		if cue.at > endTime then
			break
		end
		self:_advance(math.max(0, cue.at - self.time))
		self.time = cue.at
		self.cursor += 1
		self:_apply(cue.goals, cue.config)
	end
	self:_advance(math.max(0, endTime - self.time))
	self.time = endTime
	local generation = self.generation
	self:_flush()
	if generation == self.generation and not self:_isActive() then
		local callback = self.onComplete
		self.onComplete = nil
		if callback then
			callback()
		end
	end
	return self:_isActive()
end

function Controller:_begin(onComplete)
	assert(not self.destroyed, "motion controller was destroyed")
	self.generation += 1
	table.clear(self.queue)
	self.cursor, self.time = 1, 0
	self.onComplete = onComplete
end

function Controller:to(goals, config)
	local encoded = self:_validate(goals)
	local resolved = transition(config)
	self:_begin(resolved.onComplete)
	if self.reducedMotion or resolved.immediate then
		local generation = self.generation + 1 -- set begins one new command
		self:set(goals)
		if resolved.onComplete and self.generation == generation then
			resolved.onComplete()
		end
		return self
	end
	self:_apply(encoded, resolved)
	self.runtime:add(self)
	return self
end

function Controller:spring(goals, config)
	assert(not config or config.duration == nil, "spring does not accept duration; use to for eased motion")
	return self:to(goals, config)
end

function Controller:sequence(cues, options)
	-- Explicit start offsets allow overlap without waiting for springs to rest.
	-- Compile and validate the entire timeline before changing live animation.
	local compiled = {}
	for index, cue in cues do
		local at = finite(cue.at or 0, "cue at")
		assert(at >= 0, "cue at must be non-negative")
		table.insert(
			compiled,
			{ at = at, order = index, goals = self:_validate(cue.to), config = transition(cue.transition) }
		)
	end
	table.sort(compiled, function(a, b)
		return if a.at == b.at then a.order < b.order else a.at < b.at
	end)
	self:_begin(options and options.onComplete)
	self.queue = compiled
	if self.reducedMotion then
		for _, cue in compiled do
			for key, values in cue.goals do
				local channel = self.channels[key]
				channel.active, channel.dirty = false, true
				for i, value in values do
					channel.current.values[i], channel.goal[i], channel.velocity[i] = value, value, 0
				end
			end
		end
		self.cursor = #compiled + 1
	end
	self.runtime:add(self)
	return self
end

function Controller:set(goals)
	local encoded = self:_validate(goals)
	self:_begin(nil)
	for key, values in encoded do
		local channel = self.channels[key]
		channel.active, channel.dirty = false, true
		for i, value in values do
			channel.current.values[i], channel.goal[i], channel.velocity[i] = value, value, 0
		end
	end
	self:_flush()
	if not self:_isActive() then
		self.runtime:remove(self)
	end
	return self
end

function Controller:impulse(forces)
	local encoded = self:_validate(forces)
	self:_begin(nil)
	for key, values in encoded do
		local channel = self.channels[key]
		if not channel.config or channel.config.duration ~= nil then
			channel.config = transition(nil)
		end
		channel.active, channel.remainingDelay = true, 0
		for i, value in values do
			channel.velocity[i] += value
		end
	end
	self.runtime:add(self)
	return self
end

function Controller:get(key)
	assert(self.channels[key], `unknown motion property {key}`)
	return self.channels[key].current:toValue()
end

function Controller:getVelocity(key)
	local channel = self.channels[key]
	assert(channel, `unknown motion property {key}`)
	local constructor = channel.current.ccstr
	return if constructor then constructor(unpack(channel.velocity)) else channel.velocity[1]
end

function Controller:stop()
	self:_begin(nil)
	for _, channel in self.ordered do
		channel.active = false
	end
	self.runtime:remove(self)
	return self
end

function Controller:finish()
	assert(not self.destroyed, "motion controller was destroyed")
	for index = self.cursor, #self.queue do
		for key, values in self.queue[index].goals do
			for i, value in values do
				self.channels[key].goal[i] = value
			end
		end
	end
	self.cursor = #self.queue + 1
	for _, channel in self.ordered do
		channel.active, channel.dirty = false, true
		for i, value in channel.goal do
			channel.current.values[i], channel.velocity[i] = value, 0
		end
	end
	local callback = self.onComplete
	self.onComplete = nil
	self.generation += 1
	local generation = self.generation
	self.runtime:remove(self)
	self:_flush()
	if callback and self.generation == generation then
		callback()
	end
	return self
end

function Controller:setReducedMotion(enabled)
	self.reducedMotion = enabled
	if enabled then
		self:finish()
	end
end

function Controller:destroy()
	if self.destroyed then
		return
	end
	self:stop()
	self.listener = nil
	self.destroyed = true
end

return Controller
