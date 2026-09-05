--!nonstrict
local Path = require("./Path")
local Easing = require("./Easing")
local Tokens = require("./MotionTokens")

-- Presentation-independent, bounded emitter. A pooled slot can own an image,
-- binding, or world part. onUpdate receives position/progress; no React render
-- or task.delay is needed per frame or particle. Coordinates must share a space.
return function(runtime, options)
	assert(type(options.onUpdate) == "function", "collect needs onUpdate")
	local capacity = options.capacity or 64
	assert(capacity >= 1 and capacity % 1 == 0 and capacity <= 10000, "invalid collect capacity")
	local slots, free = {}, {}
	for index = 1, capacity do
		slots[index] = { active = false }
		free[index] = capacity - index + 1
	end
	local emitter = { count = 0, runtime = runtime }
	local function release(index, slot, arrived)
		slot.active = false
		slot.path = nil
		emitter.count -= 1
		table.insert(free, index)
		if options.onRelease then
			options.onRelease(index, arrived)
		end
	end
	function emitter:_step(dt)
		self.frame = (self.frame or 0) + 1
		for index, slot in slots do
			if not slot.active or slot.bornFrame == self.frame then
				continue
			end
			slot.elapsed += dt
			if slot.elapsed < 0 then
				continue
			end
			local alpha = math.min(1, slot.elapsed / slot.duration)
			local generation = slot.generation
			options.onUpdate(index, slot.path(slot.ease(alpha)), alpha)
			if alpha == 1 and slot.active and slot.generation == generation then
				release(index, slot, true)
			end
		end
		return self.count > 0
	end
	function emitter:emit(spec)
		assert(not self.destroyed, "collect emitter was destroyed")
		if self.clearing then
			return 0
		end
		local duration = spec.duration or Tokens.Duration.collect
		local interval = spec.stagger or Tokens.Duration.stagger
		local count = spec.count or 4
		assert(
			duration > 0 and duration < math.huge and interval >= 0 and interval < math.huge,
			"invalid collect timing"
		)
		assert(count >= 0 and count % 1 == 0 and count < math.huge, "invalid collect count")
		assert(typeof(spec.from) == typeof(spec.to), "collect endpoints must have the same type")
		local origin = spec.from
		local destination = spec.to
		assert(
			typeof(origin) == "Vector2" or typeof(origin) == "Vector3",
			"collect requires Vector2 or Vector3 endpoints"
		)
		local up = spec.arc or (if typeof(origin) == "Vector2" then Vector2.new(0, -90) else Vector3.new(0, 4, 0))
		local spread = spec.spread or (if typeof(origin) == "Vector2" then Vector2.new(16, 0) else Vector3.new(1, 0, 0))
		local accepted = math.min(count, #free)
		for i = 1, accepted do
			local index = table.remove(free)
			local slot = slots[index]
			slot.active = true
			slot.bornFrame = self.frame or 0
			slot.generation = (slot.generation or 0) + 1
			slot.elapsed = -(i - 1) * interval
			slot.duration = duration
			slot.ease = spec.ease or Easing.cubicIn
			local lateral = spread * (i - (accepted + 1) * 0.5)
			slot.path = Path.cubic(origin, origin + up + lateral, destination + up * 0.35 + lateral, destination)
			self.count += 1
			if options.onAcquire then
				options.onAcquire(index, origin)
			end
		end
		if self.count > 0 then
			runtime:add(self)
		end
		return accepted -- excess particles are deliberately dropped, never queued
	end
	function emitter:clear()
		if self.clearing then
			return
		end
		self.clearing = true
		for index, slot in slots do
			if slot.active then
				release(index, slot, false)
			end
		end
		runtime:remove(self)
		self.clearing = false
	end
	function emitter:destroy()
		if self.destroyed then
			return
		end
		self.destroyed = true
		self:clear()
	end
	return emitter
end
