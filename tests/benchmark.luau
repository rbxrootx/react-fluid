-- Reproducible CPU comparison against the unchanged upstream scalar engine.
-- This is not a GPU, UI-layout, or end-to-end frame-rate benchmark.
local load = require("./loader")("src", { ["Promise"] = {}, ["Types"] = {} })
local UpstreamSpring = load("Utility/SpringValue")
local Runtime = load("Fluid/Runtime")
local Controller = load("Fluid/Controller")
local GROUPS, PROPERTIES, FRAMES = 500, 6, 300
local function noop() end
local function trial()
	local baseline = {}
	for _ = 1, GROUPS * PROPERTIES do
		local spring = UpstreamSpring(0, 20, 0.01)
		spring:setGoal(1)
		table.insert(baseline, spring)
	end
	local runtime = Runtime.new()
	for _ = 1, GROUPS do
		local motion = Controller.new({ a = 0, b = 0, c = 0, d = 0, e = 0, f = 0 }, runtime, noop)
		motion:spring({ a = 1, b = 1, c = 1, d = 1, e = 1, f = 1 }, { speed = 20, damper = 0.01 })
	end
	local before = os.clock()
	for _ = 1, FRAMES do
		for _, spring in baseline do
			spring:update(1 / 60)
			noop(spring:getValue())
		end
	end
	local upstreamTime = (os.clock() - before) * 1000 / FRAMES
	before = os.clock()
	for _ = 1, FRAMES do
		runtime:step(1 / 60)
	end
	local fluidTime = (os.clock() - before) * 1000 / FRAMES
	return upstreamTime, fluidTime
end
trial() -- warm-up
local upstream, fluid = {}, {}
for _ = 1, 5 do
	local a, b = trial()
	table.insert(upstream, a)
	table.insert(fluid, b)
end
table.sort(upstream)
table.sort(fluid)
print(`500 groups x 6 scalar properties; 300 frames; median of 5 warm trials`)
print(
	string.format(
		"Upstream 0.5.0: %.3f ms/frame; Fluid: %.3f ms/frame; ratio %.2fx",
		upstream[3],
		fluid[3],
		upstream[3] / fluid[3]
	)
)
print("Scope: numeric stepping + value publication. No React, instances, layout, rendering or GC attribution.")
