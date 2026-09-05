# Motion recipes

These examples use `Fluid = require(ReplicatedStorage.Packages.ReactFluid)` and
`Tokens = Fluid.MotionTokens`. In a game with its own motion tokens, substitute
those presets. Components such as Button and Panel are your application's
primitives; React Fluid supplies motion bindings, not a themed widget library.

## A spring that survives repeated input

```lua
local values, motion = Fluid.useMotion({ scale = 1 }, {
    reducedMotion = reducedMotion,
})

React.useEffect(function()
    local goal = if pressed then 0.96 elseif hovered then 1.06 else 1
    motion:spring({ scale = goal }, Tokens.Spring.responsive)
end, { pressed, hovered, motion })

-- Feed values.scale into your button's UIScale property.
```

The scale targets describe the design. Speed and damping come from a shared
token. Repeated input changes the goal without recreating the spring or resetting
its velocity. Define all animated property names in the initial table.

## Overlap cues without waiting for each one to finish

```lua
motion:sequence({
    {
        at = 0,
        to = { scale = 1.06 },
        transition = Tokens.Spring.responsive,
    },
    {
        at = Tokens.Duration.reveal * 0.5,
        to = { scale = 1 },
        transition = Tokens.Spring.smooth,
    },
})
```

The second cue begins at its offset even if the first spring has not settled.
Calling `spring`, `to`, `set`, `sequence` or `stop` replaces the prior command's
timeline and completion callback. `impulse` instead adds velocity to the selected
channels. Use a new spring goal to redirect an interactive sequence.

## Unfold a group of tabs

```lua
local delayFor = Fluid.stagger(Tokens.Duration.stagger, {
    from = "first",
    maxDelay = Tokens.Duration.reveal * 0.5,
})

local children = {}
for index, tab in tabs do
    children[tab.id] = React.createElement(Fluid.Reveal, {
        open = open,
        height = tab.height,
        delay = delayFor(index, #tabs),
        spring = Tokens.Spring.smooth,
        reducedMotion = reducedMotion,
        LayoutOrder = index,
        ZIndex = 10 + index,
    }, tab.content)
end

return React.createElement(props.Container, nil, children)
```

Each keyed child owns its hook, so changing the list does not change the parent's
hook order. Stagger distributes a bounded start spread across the whole list.
It does not leave a long tail of tabs opening seconds later.

`Reveal` changes its own outer height, so a UIListLayout will reflow. For a shop
whose scroll position must stay fixed, reserve each row's height in a wrapper
and animate an inner aperture using `useReveal`:

```lua
local progress = Fluid.useReveal(open, {
    delay = delay,
    spring = Tokens.Spring.smooth,
    reducedMotion = reducedMotion,
})
local apertureSize = progress:map(function(value)
    return UDim2.new(1, 0, 0, rowHeight * math.clamp(value, 0, 1))
end)
-- Your primitive owns a fixed row-height wrapper, a ClipsDescendants aperture
-- using apertureSize, and full-height content inside that aperture.
```

Keep clipping ancestors unrotated. This produces a 2D shutter-like reveal;
it does not simulate a 3D slat rotating in perspective. BeeGame's `ShopRevealRow`
uses this fixed-layout composition with the controller's eased `to` transition.

## Send collectible icons along a continuous curve

Allocate your visuals once, then connect emitter slots to their binding setters.
The following adapter functions are supplied by your pool; they must not create
a new React child in every `onUpdate` call.

```lua
local emitter = Fluid.createCollect({
    capacity = 24,
    onAcquire = function(slot, origin)
        pool:show(slot, origin)
    end,
    onUpdate = function(slot, position, progress)
        pool:update(slot, position, progress)
    end,
    onRelease = function(slot, arrived)
        pool:hide(slot)
        if arrived then
            onVisualArrival(slot)
        end
    end,
})

local accepted = emitter:emit({
    from = pickupPosition,
    to = counterPosition,
    count = 4,
    duration = Tokens.Duration.collect,
    stagger = Tokens.Duration.stagger,
    arc = Vector2.new(0, -90),
    spread = Vector2.new(16, 0),
    ease = Fluid.Easing.cubicIn,
})
-- accepted can be smaller than count when the pool is full.
```

Both endpoints must use the same coordinate space. For a screen overlay, convert
the world pickup and the counter's actual icon bounds into that overlay's local
coordinates. Targets are captured at emission, so this version does not follow
a moving counter. `onUpdate` receives uneased 0–1 progress separately from the
position sampled using your easing curve.

Create emitters in an effect or an explicit owner lifecycle. Disconnect the
pickup subscription and call `emitter:destroy()` during cleanup. Disabling motion
should stop new emissions and clear existing particles. `clear()` releases slots
with `arrived = false`; an arrival callback is a visual event, never a reward grant.
Arrival callbacks run per particle; decide in the caller whether to pulse once
per accepted burst or per icon, and cap accumulated spring velocity.

## Follow a path with roughly constant travel speed

```lua
local path = React.useMemo(function()
    return Fluid.Path.uniform(Fluid.Path.spline(points))
end, { points })
local values, motion = Fluid.useMotion({ progress = 0 })
local position = values.progress:map(function(value)
    return path(value)
end)

React.useEffect(function()
    motion:set({ progress = 0 })
    motion:to({ progress = 1 }, {
        duration = Tokens.Duration.collect,
        ease = Fluid.Easing.linear,
    })
end, { path, motion })
```

Memoize stable control points or replace the points table when the path changes.
`Path.uniform` builds a sampled arc-length map; it approximates constant speed.
Applying non-linear easing intentionally changes speed along that path.
