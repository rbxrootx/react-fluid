-- Parent this LocalScript inside the isolated ReactFluidValidation fixture.
local RS = game:GetService("ReplicatedStorage")
local React = require(RS.Packages.React)
local ReactRoblox = require(RS.Packages.ReactRoblox)
local Fluid = require(RS.ReactFluidValidation.ReactFluid)
local upstream = RS.Packages:FindFirstChild("ReactFlow")
local Flow = if upstream then require(upstream) else Fluid
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Tokens = Fluid.MotionTokens

local function check(condition, message)
	assert(condition, "ReactFluidValidation: " .. message)
end

local values, legacySpring, legacyTween, declarative, motion, renders, setOpen
renders = 0
local function Probe()
	renders += 1
	local spring, setSpring = Flow.useSpring({ start = 0, speed = Tokens.Spring.smooth.speed, damper = 1 })
	local tween, setTween = Flow.useTween({ start = 0, target = 0, info = TweenInfo.new(Tokens.Duration.reveal) })
	local declarativeSpring =
		Flow.useSpringValue({ start = 0, target = 1, speed = Tokens.Spring.smooth.speed, damper = 1 })
	local state, controller = Fluid.useMotion({ x = 0, position = Vector2.zero })
	local open, updateOpen = React.useState(false)
	setOpen = updateOpen
	values, motion = state, controller
	legacySpring, legacyTween, declarative = spring, tween, declarativeSpring
	React.useEffect(function()
		setSpring({ target = 1 })
		setTween({ target = 1 })
		controller:spring({ x = 1, position = Vector2.new(20, 30) })
	end, {})
	return React.createElement(Fluid.Reveal, {
		open = open,
		height = 100,
		width = UDim.new(0, 200),
		ZIndex = 2,
	})
end

local function run()
	local target = Instance.new("Folder")
	target.Name = "ReactFluidProbe"
	target.Parent = Players.LocalPlayer.PlayerGui
	local root = ReactRoblox.createRoot(target)
	root:render(React.createElement(Probe))
	local waited = 0
	repeat
		waited += RunService.PreRender:Wait()
	until legacySpring and legacyTween and declarative and values and motion and waited >= Tokens.Duration.reveal * 4
	check(
		math.abs(legacySpring:getValue() - 1) < 0.02,
		`0.5.0 spring did not settle: {legacySpring:getValue()}, rendered dt {waited}, renders {renders}`
	)
	check(math.abs(legacyTween:getValue() - 1) < 0.02, "0.5.0 tween did not settle")
	check(math.abs(declarative:getValue() - 1) < 0.02, "0.5.0 declarative spring did not settle")
	check(values.x:getValue() == 1, "Fluid scalar did not settle exactly")
	check((values.position:getValue() - Vector2.new(20, 30)).Magnitude < 0.001, "Fluid Vector2 did not settle")
	local steadyRenders = renders
	motion:spring({ x = -1 })
	RunService.PreRender:Wait()
	local before = motion:get("x")
	local velocity = motion:getVelocity("x")
	motion:spring({ x = 2 })
	check(motion:get("x") == before and motion:getVelocity("x") == velocity, "retarget lost continuity")
	task.wait(Tokens.Duration.reveal * 4)
	check(values.x:getValue() == 2, "retarget did not settle")
	check(renders == steadyRenders, "binding animation caused React renders")
	local reveal = target:FindFirstChild("FluidReveal")
	check(reveal ~= nil and reveal.Size.Y.Offset == 0, "reveal did not start closed")
	setOpen(true)
	task.wait(Tokens.Duration.reveal * 0.25)
	check(reveal.Size.Y.Offset > 0 and reveal.Size.Y.Offset < 100, "reveal did not unfold")
	setOpen(false)
	task.wait(Tokens.Duration.reveal * 4)
	check(reveal.Size.Y.Offset == 0, "interrupted reveal did not close")
	setOpen(true)
	task.wait(Tokens.Duration.reveal * 4)
	check(reveal.Size.Y.Offset == 100, "reveal did not finish opening")
	motion:spring({ x = 100 })
	root:unmount()
	task.wait(Tokens.Duration.stagger)
	check(not motion:_isActive(), "unmount left motion running")
	target:Destroy()
	return {
		ok = true,
		legacyVersion = "0.5.0",
		hookRenders = renders,
		checks = "legacy spring/tween/declarative hooks, Fluid bindings, Vector2, velocity continuity, no per-frame renders, unmount cleanup",
	}
end

local ok, result = pcall(run)
if not ok then
	result = { ok = false, error = tostring(result) }
end
RS.ReactFluidValidation.Report:FireServer(result)
