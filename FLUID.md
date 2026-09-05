# React Fluid (experimental)

A fork of [React Flow](https://github.com/OutOfBears/react-flow), based on
`a7975e9ce3f36ec54e576a87a079921c73db531a` (0.5.0). Original MIT license and
attribution are retained. The existing React Flow API remains available.

The new API keeps each property's current value and velocity alive across
animation changes. Use springs for interactive state, one continuous path for
travel, and overlapping start offsets for choreography. More keyframes alone
do not make motion more fluid.

## One controller for a component

```lua
local values, motion = Fluid.useMotion({ scale = 1, offset = Vector2.zero })

-- In an event handler or effect:
motion:spring({ scale = 1.08 }, Fluid.MotionTokens.Spring.responsive)
motion:spring({ scale = 1 }) -- carries velocity; does not reset to initial

-- Feed values.scale directly to a UIScale primitive, or map values.offset
-- to UDim2. Per-frame binding writes do not re-render the component.
```

Methods use colon syntax. Declare all property names in `initial`; it is read
once. Supported values: number, Vector2, Vector3, UDim, UDim2, Color3. CFrame
continues to be supported by the legacy hooks; the new API does not yet promise
correct angular-velocity retargeting.

`to(goals, transition)` accepts either `speed` / `damper`, or `duration` / `ease`.
`spring` accepts spring configuration only. Both support `delay`, `immediate`,
and `onComplete`. Spring configurations can set `positionThreshold` and
`velocityThreshold`; offsets and scale values may need different thresholds.
For separate property configurations call `to` with one subset at a time.
Existing properties outside that subset continue animating.

`set` jumps the specified properties and clears their velocity. `stop` freezes
all properties and cancels queued cues/completion; a subsequent spring keeps the
frozen velocity. `impulse` adds velocity. `finish` applies the final queued goals
and completes. `destroy` releases the controller permanently. Each new command
cancels the prior timeline and its completion callback. Completion callbacks
run once after settling, not after cancellation. Callbacks may retarget motion.
The hook stops its controller on unmount.

## Springs and easing

Seven spring presets: `gentle`, `responsive`, `smooth`, `bouncy`, `soft`, `stiff`,
`slow`. Pass your game's MotionTokens instead when integrating with a design
system. `Fluid.SpringMath.physical(stiffness, damping, mass)` converts physical
parameters to the same analytic solver. Damper 0 oscillates indefinitely;
1 is critically damped; values above 1 are overdamped. Speed must be positive.

`Fluid.Easing` provides linear, smoothstep, smootherstep, standard, and In / Out /
InOut forms of quad, cubic, quart, quint, sine, expo, circ, back, elastic, bounce.
It also provides `bezier(x1,y1,x2,y2)`, `steps(count, jumpStart)`, `reverse(curve)`,
and `inOut(curve)`. Custom easing functions are accepted.

```lua
motion:to({ offset = Vector2.zero }, {
    duration = Fluid.MotionTokens.Duration.reveal,
    ease = Fluid.Easing.bezier(0.16, 1, 0.3, 1),
})
```

Eased retargets preserve position, but restart their velocity curve. Use a spring
when user input can interrupt the movement. Overshooting curves are appropriate
for scale/position; clamp a mapped binding for transparency or clipping.

## Overlapping choreography

```lua
motion:sequence({
    { at = 0, to = { scale = 1.08 }, transition = Tokens.Spring.responsive },
    { at = Tokens.Duration.fast, to = { scale = 1 }, transition = Tokens.Spring.smooth },
}, { onComplete = finished })
```

Offsets are seconds from the sequence start, not a wait for the previous spring
to settle. A frame crossing a cue boundary is split exactly at that boundary.
Same-property spring cues preserve velocity; simultaneous cues retain list order.
`useMotion(initial, { reducedMotion = true })` skips travel. Changing that option
while running finishes current/queued goals and preserves completion behavior.

## Tabs unfolding like blinds

```lua
local delayFor = Fluid.stagger(Tokens.Duration.stagger, {
    from = "first", -- also last, center, or a one-based numeric origin
    maxDelay = Tokens.Duration.reveal,
})

-- In a parent, render keyed Reveal components (not hooks in a variable loop).
children[tab.id] = React.createElement(Fluid.Reveal, {
    open = isOpen,
    height = 64,
    delay = delayFor(index, #tabs),
    spring = Tokens.Spring.smooth,
    LayoutOrder = index,
    ZIndex = 10 + index,
}, tabContent)
```

Reveal opens a clipped aperture from the top while keeping content at its full
pixel height. Siblings overlap in time; long lists cap their total start spread.
It reverses mid-flight when closed. This is a 2D unfolding reveal, not a 3D
perspective rotation or a replicated subtree for every shutter slat. Use an
unrotated container because Roblox clipping does not support rotated ancestors.
`useReveal(open, options)` exposes the same progress binding for custom masks.

## Coin and honey pickups

```lua
local emitter = Fluid.createCollect({
    capacity = 64,
    onAcquire = function(slot, origin) showPooledIcon(slot, origin) end,
    onUpdate = function(slot, position, progress)
        positionSetters[slot](UDim2.fromOffset(position.X, position.Y))
        opacitySetters[slot](math.clamp((progress - 0.85) / 0.15, 0, 1))
    end,
    onRelease = function(slot, arrived)
        hidePooledIcon(slot)
        if arrived then pulseCounter() end
    end,
})

emitter:emit({
    from = pickupScreenPosition,
    to = counterScreenPosition,
    count = 4,
    duration = Tokens.Duration.collect,
    stagger = Tokens.Duration.stagger,
    arc = Vector2.new(0, -90),
    spread = Vector2.new(16, 0),
})
-- Effect cleanup: emitter:destroy()
```

Supply positions in the same coordinate space. Destinations are captured on emit;
this version does not home to a moving target. `emit` returns the accepted count;
the capacity cap drops overflow. Slots and their visuals can be reused. `clear`
and `destroy` release slots with `arrived=false`, so cancellation cannot grant a
visual arrival event. Rewards remain server-owned. The emitter also accepts
Vector3 world paths; apply world positions with your existing BulkMoveTo system.

For custom effects use `Path.quadratic`, `Path.cubic`, `Path.spline(points, tension)`
or `Path.uniform(curve, samples)`. Spline segments share tangents; uniform caches
an approximate arc-length map to remove speed changes from uneven control points.

## Runtime and performance

`createMotion(initial, { onChange = function(key, value) ... end })` works outside
React. `createRuntime()` makes a manual runtime; pass it in options, then call
`runtime:step(dt)` once from your renderer. Do not manually step the shared runtime.

The new API uses a dense active controller list, one shared frame connection,
in-place numeric component arrays, reusable spring coefficients, and no Promise
or coroutine per property or delayed cue. Its connection shuts down at rest.
Upstream 0.5.0 already pools frame connections; pooling is not a new claim.
Legacy APIs retain the upstream engine and behavior.

Run `lune run tests/core` and `lune run tests/benchmark`. The benchmark compares
numeric stepping/publication for 500 groups of six scalar values against the
unchanged upstream SpringValue. It is not evidence of a corresponding game FPS
gain. Roblox layout, bindings, transparency overdraw, images, and low-end device
performance still require Studio/device profiling.

For the standalone Studio regression fixture, build
`rojo build fluid-test.project.json -o FluidValidation.rbxl`, open that place,
and press Play. Output reports a JSON result. When injected into BeeGame the
fixture checks its installed React Flow package; standalone it checks the
fork's preserved compatibility hooks. `tests/studio.client.luau` contains the
assertions. This fixture checks behavior, not the aesthetic quality of a design.

This branch is experimental and is not published to the Wally registry. BeeGame
uses upstream 0.5.0; adopting the fork is a separate migration.

For a portable local Roblox model, run `wally install`, then
`rojo build fluid.project.json -o ReactFluid.rbxm`. Insert that model and require
its `ReactFluid` child. The sibling dependency aliases are included. In a game
that already uses React, point both the model and your UI at the same React
package; do not mount hooks from a second React copy under an existing renderer.

Validation on September 5, 2026: 271 deterministic assertions passed; live Studio
play checks passed for the game's 0.5.0 spring/tween/declarative hooks, new scalar
and Vector2 bindings, velocity-preserving retargeting, reveal reversal, no extra
React renders from animation, and unmount cleanup. The measured scalar benchmark
was 3.306 ms/frame upstream vs 2.294 ms/frame Fluid (1.44x) on this development
machine. This is a limited CPU workload, not a game FPS or device guarantee.
