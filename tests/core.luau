-- Run from the fork root: lune run tests/core
local load = require("./loader")("src", { ["Promise"] = {}, ["Types"] = {} })
local Runtime = load("Fluid/Runtime")
local Controller = load("Fluid/Controller")
local Easing = load("Fluid/Easing")
local Path = load("Fluid/Path")
local Stagger = load("Fluid/Stagger")
local SpringMath = load("Fluid/SpringMath")
local Collect = load("Fluid/Collect")
local Vector2 = require("@lune/roblox").Vector2
local checked = 0
local function near(a, b, epsilon)
	assert(math.abs(a - b) <= (epsilon or 1e-7), `{a} != {b}`)
	checked += 1
end
local function expectError(fn)
	assert(not pcall(fn), "expected validation failure")
	checked += 1
end
local function runtime()
	return Runtime.new(nil, function(err)
		error(err)
	end)
end

-- Frame-rate independence in all three damping regimes, including a hitch.
for _, damper in { 0, 0.4, 0.999999999, 1, 1.000000001, 2, 100 } do
	local reference
	for _, fps in { 30, 60, 144 } do
		local r = runtime()
		local m = Controller.new({ x = 0 }, r)
		m:spring({ x = 1 }, { speed = 12, damper = damper })
		for _ = 1, fps do
			r:step(1 / fps)
		end
		if reference then
			near(m:get("x"), reference, 1e-6)
		else
			reference = m:get("x")
		end
		m:destroy()
		near(r:count(), 0)
	end
	local r = runtime()
	local m = Controller.new({ x = 0 }, r)
	m:spring({ x = 1 }, { speed = 12, damper = damper })
	r:step(1)
	near(m:get("x"), reference, 1e-6)
end

do
	local r = runtime()
	local completed = 0
	local m = Controller.new({ x = 0, y = 0 }, r)
	m:spring({ x = 1 })
	r:step(0.1)
	local x, velocity = m:get("x"), m:getVelocity("x")
	m:spring({ x = -1 }, {
		onComplete = function()
			completed += 1
		end,
	})
	near(m:get("x"), x)
	near(m:getVelocity("x"), velocity)
	for _ = 1, 300 do
		r:step(1 / 60)
	end
	near(m:get("x"), -1)
	near(completed, 1)
	near(r:count(), 0)
	m:sequence({
		{ at = 0, to = { x = 0 }, transition = { duration = 1, ease = Easing.linear } },
		{ at = 0.25, to = { y = 2 }, transition = { duration = 0.5, ease = Easing.linear } },
	})
	r:step(0.5)
	near(m:get("x"), -0.5)
	near(m:get("y"), 1)
	m:stop()
	r:step(1)
	near(m:get("x"), -0.5)
	near(r:count(), 0)
	m:spring({ x = 1 }, { delay = 0.1 })
	r:step(0.05)
	near(m:get("x"), -0.5)
	r:step(0.1)
	assert(m:get("x") > -0.5)
	m:setReducedMotion(true)
	near(m:get("x"), 1)
	near(r:count(), 0)
	m:spring({ x = 20 })
	near(m:get("x"), 20)
	expectError(function()
		m:spring({ missing = 1 })
	end)
	expectError(function()
		m:spring({ x = 0 / 0 })
	end)
	expectError(function()
		m:spring({ x = 1 }, { speed = 0 })
	end)
	expectError(function()
		m:to({ x = 1 }, { duration = -1 })
	end)
	expectError(function()
		m:spring({ x = Vector2.new() })
	end)
	m:destroy()
	expectError(function()
		m:spring({ x = 2 })
	end)
end

-- Callbacks can stop earlier/later jobs, retarget themselves and add jobs.
do
	local r = runtime()
	local first = Controller.new({ x = 0 }, r)
	local third = Controller.new({ x = 0 }, r)
	local fourth = Controller.new({ x = 0 }, r)
	local second = Controller.new({ x = 0 }, r, function()
		first:stop()
		third:stop()
		fourth:spring({ x = 1 })
	end)
	first:spring({ x = 1 })
	second:spring({ x = 1 })
	third:spring({ x = 1 })
	r:step(0.1)
	near(third:get("x"), 0)
	near(fourth:get("x"), 0)
	near(r:count(), 2)
	second:stop()
	r:step(0.1)
	assert(fourth:get("x") > 0)
	local m
	m = Controller.new({ x = 0 }, r)
	m:to({ x = 1 }, {
		duration = 0.1,
		onComplete = function()
			m:spring({ x = 2 })
		end,
	})
	r:step(0.1)
	for _ = 1, 200 do
		r:step(1 / 60)
	end
	near(m:get("x"), 2)
	near(r:count(), 0)
end

-- Connections shut down immediately at rest; one bad consumer is isolated.
do
	local connections, disconnected, errors = 0, 0, 0
	local r = Runtime.new(function()
		connections += 1
		return {
			Disconnect = function()
				disconnected += 1
			end,
		}
	end, function()
		errors += 1
	end)
	local bad = Controller.new({ x = 0 }, r, function()
		error("intentional")
	end)
	local good = Controller.new({ x = 0 }, r)
	bad:spring({ x = 1 })
	good:to({ x = 1 }, { duration = 0.1 })
	r:step(0.1)
	near(errors, 1)
	near(good:get("x"), 1)
	near(connections, 1)
	near(disconnected, 1)
	near(r:count(), 0)
end

for _, name in { "quad", "cubic", "quart", "quint", "sine", "expo", "circ", "back", "elastic", "bounce" } do
	for _, direction in { "In", "Out", "InOut" } do
		local curve = Easing[name .. direction]
		near(curve(0), 0)
		near(curve(1), 1)
		for i = 0, 100 do
			assert(math.abs(curve(i / 100)) < math.huge)
		end
	end
end
local bezier = Easing.bezier(0.25, 0.25, 0.75, 0.75)
for i = 0, 100 do
	near(bezier(i / 100), i / 100, 1e-6)
end
expectError(function()
	Easing.bezier(-1, 0, 1, 1)
end)
near(Stagger(0.04)(3, 4), 0.08)
near(Stagger(0.04, { from = "last" })(4, 4), 0)
near(Stagger(0.04, { from = "center" })(2, 4), 0)
near(Stagger(0.04, { from = "center" })(3, 4), 0)
near(Stagger(0.04, { maxDelay = 0.2 })(100, 100), 0.2)

local spline = Path.spline({ 0, 1, 3, 4 })
near(spline(0), 0)
near(spline(1), 4)
local h = 1e-5
near((spline(1 / 3) - spline(1 / 3 - h)) / h, (spline(1 / 3 + h) - spline(1 / 3)) / h, 0.001)
local uniform = Path.uniform(Path.cubic(0, 0, 1, 10), 512)
near(uniform(0.5), 5, 0.0001)
local physical = SpringMath.physical(400, 28, 1)
near(physical.speed, 20)
near(physical.damper, 0.7)

do
	local r = runtime()
	local acquired, released, arrived = 0, 0, 0
	local emitter = Collect(r, {
		capacity = 8,
		onAcquire = function()
			acquired += 1
		end,
		onUpdate = function(_, position, alpha)
			if alpha == 1 then
				near(position.X, 100)
				near(position.Y, 20)
			end
		end,
		onRelease = function(_, complete)
			released += 1
			if complete then
				arrived += 1
			end
		end,
	})
	local spec = { from = Vector2.new(0, 0), to = Vector2.new(100, 20), count = 100, duration = 0.5, stagger = 0 }
	near(emitter:emit(spec), 8)
	near(emitter:emit(spec), 0)
	r:step(0.5)
	near(acquired, 8)
	near(released, 8)
	near(arrived, 8)
	near(r:count(), 0)
	near(emitter:emit(spec), 8)
	emitter:destroy()
	near(emitter.count, 0)
	near(released, 16)
	near(arrived, 8)
	near(r:count(), 0)
end
print(`React Fluid: {checked} assertions passed (math, interruption, sequences, cleanup, curves, paths, emitters).`)
