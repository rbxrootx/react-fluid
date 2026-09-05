# React Flow compatibility API

React Fluid preserves these upstream React Flow 0.5.0 APIs and their engine.
New composed effects can use [useMotion](../FLUID.md) instead.
Install [React Fluid](installation.md) to use this fork; an upstream Wally
ReactFlow dependency does not install it. In these historical examples,
`ReactFlow` is your import of the fork, and `createElement` is
`React.createElement`.

Adapted from the upstream documentation by OutOfBears and GreenDeno, under the
[original MIT license](../LICENSE.md).

### `useSpring`

Creates spring-based physics animations with React bindings. Springs provide natural, bouncy motion that reacts to changes dynamically.

**Arguments:**
- **config:** A configuration table with the following properties:
  - **start:** Initial value of the animation (required)
  - **target:** Target value to animate toward (optional)
  - **speed:** Spring stiffness - higher values create faster motion (default: 10)
  - **damper:** Damping ratio - higher values reduce bouncing (default: 1)

**Returns:**  
A binding that updates as the animation progresses, and an update function to modify the animation.

**Example:**
```lua
local useSpring = ReactFlow.useSpring

-- Inside your component:
local position, updatePosition = useSpring({
    start = UDim2.fromScale(0, 0),           -- Initial Value (required)
    target = UDim2.fromScale(0.5, 0.5),      -- Target value (optional)

    speed = 20,
    damper = 0.8,
})

-- Later, update the spring with new parameters:
updatePosition({
    target = UDim2.fromScale(0.5, 0.5),

    speed = 15,
    damper = 0.7,
})

-- Use in your component:
return createElement("Frame", {
    Position = position, -- Use binding directly in property
})
```

---

### `useTween`

Creates tween-based animations that follow a specific timing curve. Ideal for animations that need precise timing or easing effects.

**Arguments:**
- **config:** A configuration table with the following properties:
  - **start:** Initial value of the animation (required)
  - **target:** Target value to animate toward (optional)
  - **info:** TweenInfo instance (required)

**Returns:**  
A binding that updates as the animation progresses, and an update function to modify the animation.

**Example:**
```lua
local useTween = ReactFlow.useTween

-- Inside your component:
local transparency, updateTransparency = useTween({
    start = 1,      -- Initial value (required)
    target = 0,     -- Target value (optional)

    -- TweenInfo - controls duration, easing style, and behavior
    info = TweenInfo.new(
        0.5,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out, 
    )
})

-- Later, update the tween:
updateTransparency({
    target = 0,     -- New target value

    -- Optional: update tween configuration
    info = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut),
})

-- Use in your component:
return createElement("Frame", {
    BackgroundTransparency = transparency,
})
```

---

### `useSpringValue`

Declarative variant of [`useSpring`](#usespring). Instead of returning an update function, the hook watches the `target`, `speed`, and `damper` props on each render and re-targets the spring automatically when they change. Use this when your spring goal is a direct function of React state and you don't need imperative control.

The `start` prop seeds the initial value only — it is **not** re-applied on subsequent renders, so the spring smoothly retargets from its current value rather than snapping back to the start.

**Arguments:**
- **config:** A configuration table with the following properties:
  - **start:** Initial value of the animation (used only on mount)
  - **target:** Current goal — changes between renders are followed automatically
  - **speed:** Spring stiffness (live-updatable)
  - **damper:** Damping ratio (live-updatable)

**Returns:**  
A binding that updates as the animation progresses. No update or stop function — control is purely via props.

**Example:**
```lua
local useSpringValue = ReactFlow.useSpringValue

-- Inside your component:
local hovered, setHovered = React.useState(false)

local color = useSpringValue({
    start = Color3.fromRGB(150, 150, 150),
    target = if hovered then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(150, 150, 150),

    speed = 20,
    damper = 0.8,
})

return createElement("TextButton", {
    BackgroundColor3 = color,
    [React.Event.MouseEnter] = function() setHovered(true) end,
    [React.Event.MouseLeave] = function() setHovered(false) end,
})
```

---

### `useTweenValue`

Declarative variant of [`useTween`](#usetween). The hook watches the `target` prop on each render and replays the tween from the binding's current value to the new target. Use this when your tween goal is driven by React state.

As with `useSpringValue`, the `start` prop is only used on mount — re-renders tween from the current animated value, not from `start`.

**Arguments:**
- **config:** A configuration table with the following properties:
  - **start:** Initial value of the animation (used only on mount)
  - **target:** Current goal — changes between renders trigger a replay
  - **info:** `TweenInfo` instance
  - **delay:** Optional delay before the tween starts

**Returns:**  
A binding that updates as the animation progresses.

**Example:**
```lua
local useTweenValue = ReactFlow.useTweenValue

-- Inside your component:
local visible, setVisible = React.useState(false)

local transparency = useTweenValue({
    start = 1,
    target = if visible then 0 else 1,
    info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
})

return createElement("Frame", {
    BackgroundTransparency = transparency,
})
```

---

### `useGroupAnimation`

Creates a group of animations that are managed together as a single entity. With `useGroupAnimation`, you can define multiple animation states by combining the following animation primitives: `useAnimation`, `useSpringAnimation`, `useSequenceAnimation`, and `useTweenAnimation`. This allows you to define complex animation states and switch between them seamlessly at runtime, providing an elegant way to handle UI state transitions.

**Arguments:**
- **animations:** A table mapping state names (e.g., "active", "inactive") to their animation definitions. Each definition can mix multiple animation types.
- **defaults:** A table providing the default initial values for each animation property.

**Returns:**  
A table of bindings for each animation property, and a function (commonly named `playAnimation`) that accepts a state name to switch between the defined animation groups.

**Example:**

```lua
local useGroupAnimation = ReactFlow.useGroupAnimation
local useSequenceAnimation = ReactFlow.useSequenceAnimation
local useAnimation = ReactFlow.useAnimation

local Spring = ReactFlow.Spring
local Tween = ReactFlow.Tween

-- Inside your component:
local animations, playAnimation = useGroupAnimation({
    enable = useSequenceAnimation({
        {
            timestamp = 0,
            transparency = Tween({target = 0, info = TweenInfo.new(0.2)}),
        },
        {
            timestamp = 0.2,
            position = Spring({target = UDim2.fromScale(0.5, 0.5), speed = 20}),
        },
    }),
    disable = useAnimation({
        transparency = Tween({target = 1, info = TweenInfo.new(0.1)}),
        position = Spring({target = UDim2.fromScale(0.5, 1), speed = 25}),
    }),
}, {
    transparency = 1,
    position = UDim2.fromScale(0.5, 1),
})

-- Respond to state after React commits, rather than starting work in render:
React.useEffect(function()
    if enabled then
        playAnimation("enable")
    else
        playAnimation(
            "disable",
            true -- Optional second argument to play animation immediately
        )
    end
end, { enabled, playAnimation })

-- Use the animation bindings in your component:
return createElement("Frame", {
    Size = UDim2.new(0, 100, 0, 100),
    BackgroundTransparency = animations.transparency,
    Position = animations.position,
})
```

---

### `useTransparencyModifier`

Composes a transparency binding with a modifier so transparency values can be uniformly faded toward fully transparent. Useful for hover, disabled, or fade-in/out states that need to dim a whole element (or subtree) without rewriting every individual transparency value.

The modifier is applied multiplicatively against visibility: a modifier of `0` leaves transparency untouched, a modifier of `1` makes the element fully transparent, and values in between blend smoothly. Both plain `number` transparencies and `NumberSequence` transparencies (e.g. for `UIGradient.Transparency`) are supported, as are static values and bindings.

**Arguments:**
- **modifier:** A binding holding a `number` between `0` and `1` representing the additional transparency to apply. A value of `0` is a no-op; `1` fully hides the target.

**Returns:**  
A function that takes a transparency value and returns a binding with the modifier applied. The returned function can be called repeatedly for each property you want to modify, and accepts:
- A `number` (e.g. `BackgroundTransparency = 0.2`)
- A `NumberSequence` (e.g. for `UIGradient.Transparency`)
- A `Binding` of either of the above (animated transparency continues to update with the modifier applied)
- `nil` (treated as `0`)

**Example:**
```lua
local useTransparencyModifier = ReactFlow.useTransparencyModifier
local useSpring = ReactFlow.useSpring

-- Inside your component:
local fade = useSpring({
    start = 1,                  -- Start fully hidden
    target = visible and 0 or 1,-- 0 = fully visible, 1 = fully hidden

    speed = 18,
    damper = 1,
})

local modifyTransparency = useTransparencyModifier(fade)

return createElement("Frame", {
    BackgroundTransparency = modifyTransparency(0.2),
}, {
    label = createElement("TextLabel", {
        BackgroundTransparency = 1,
        TextTransparency = modifyTransparency(0),
    }),
    gradient = createElement("UIGradient", {
        Transparency = modifyTransparency(NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.5),
        })),
    }),
})
```

---

### `TransitionFragment`

`TransitionFragment` is a component that allows elements to be animated on transition in and out by preserving their presence in a cached fragment during enter and leave operations. When children are added or removed, the component maintains them in the Roblox instance tree while injecting transition state props, enabling easy enter and exit animations.

The component automatically injects the following props into child elements:

- **entering**: `boolean` - True when the element is being added
- **exiting**: `boolean` - True when the element is being removed
- **onEnterComplete**: `() -> ()` - Callback when enter animation completes
- **onExitComplete**: `() -> ()` - Callback when exit animation completes

This allows child components to respond to transition states and perform appropriate animations while `TransitionFragment` handles the lifecycle management.

**Arguments:**

- **children**: A table containing the elements to be managed with transitions. Elements are automatically cached and transitioned when added or removed.

**Returns:**

A `TransitionFragment` component that handles the transition lifecycle and injects transition props into its children.

**Example:**

```lua
local function Entry(props: {
    entering: boolean,
    exiting: boolean,
    onEnterComplete: () -> (),
    onExitComplete: () -> ()
})
    useEffect(function()
        if props.entering then
            -- Play enter animation and wait for animation to complete
            props.onEnterComplete()
        end
    end, {props.entering})

    useEffect(function()
        if props.exiting then
            -- Play enter animation and wait for animation to complete
            props.onExitComplete()
        end
    end, {props.exiting})

    return ...
end

return createElement(ExampleContainer, {}, {
    entries = createElement(TransitionFragment, {}, {
        -- list of Entries
    })
})
```
