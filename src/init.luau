local Animations = require(script.Animations)
local SharedRuntime = require(script.Fluid.SharedRuntime)
local Controller = require(script.Fluid.Controller)
local Collect = require(script.Fluid.Collect)
local FluidTypes = require(script.Fluid.Types)

export type Motion = FluidTypes.Motion
export type MotionValue = FluidTypes.Value
export type Transition = FluidTypes.Transition
export type Cue = FluidTypes.Cue
export type Runtime = FluidTypes.Runtime
export type Emitter = FluidTypes.Emitter

return {
	-- Persistent motion API. Legacy React Flow exports remain available below.
	useMotion = require(script.Fluid.useMotion),
	useReveal = require(script.Fluid.useReveal),
	Easing = require(script.Fluid.Easing),
	Path = require(script.Fluid.Path),
	stagger = require(script.Fluid.Stagger),
	MotionTokens = require(script.Fluid.MotionTokens),
	SpringMath = require(script.Fluid.SpringMath),
	createRuntime = require(script.Fluid.Runtime).new,
	createMotion = function(initial: FluidTypes.Goals, options: FluidTypes.MotionOptions?): FluidTypes.Motion
		options = options or {}
		return Controller.new(initial, options.runtime or SharedRuntime, options.onChange)
	end,
	createCollect = function(options: FluidTypes.CollectOptions): FluidTypes.Emitter
		return Collect(options.runtime or SharedRuntime, options)
	end,
	Reveal = require(script.Components.Primitives.Reveal),
	Tween = Animations.Tween.definition,
	Spring = Animations.Spring.definition,

	useAnimation = require(script.Hooks.useAnimation),
	useGroupAnimation = require(script.Hooks.useGroupAnimation),
	useSequenceAnimation = require(script.Hooks.useSequenceAnimation),

	useSpring = require(script.Hooks.useSpring),
	useTween = require(script.Hooks.useTween),

	useSpringValue = require(script.Hooks.useSpringValue),
	useTweenValue = require(script.Hooks.useTweenValue),

	useBindings = require(script.Hooks.useBindings),
	useTransparencyModifier = require(script.Hooks.useTransparencyModifier),

	TransitionFragment = require(script.Components.TransitionFragment),
	DynamicList = require(script.Components.DynamicList),
}
