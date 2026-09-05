# Migrating from React Flow

React Fluid preserves the React Flow 0.5.0 exports. Adopting the package does not
require replacing every existing hook. Start with an [installation](installation.md)
that gives the fork access to the same React and Promise instances as your game.

## Keep compatibility while adopting the new API

| Existing pattern | For new composed effects |
| --- | --- |
| `useSpring({start, target, speed, damper})` | `useMotion({value = initial})`, then `motion:spring({value = target}, preset)` |
| `useTween` with TweenInfo | `motion:to(goals, {duration = seconds, ease = curve})` |
| `useGroupAnimation` plus chained states | One persistent controller with `sequence` cues |
| A delayed task for each row | `stagger` feeding keyed child components |
| A React child created for each pickup | Fixed visuals connected to `createCollect` slots |

Legacy `Spring`/`Tween` definitions and `TransitionFragment` still use the
original engine. Passing through the fork does not automatically convert them
to the new runtime. The [compatibility guide](legacy-api.md) retains their docs.

## Contracts that matter

- Define every property in `useMotion(initial)`. That initial shape is read once.
- Use colon syntax for controller and emitter methods. Start commands in effects
  or event handlers; do not call hooks in loops or conditional branches.
- Spring retargets carry velocity. Eased retargets keep position and restart
  their easing curve. Use springs where input can interrupt the animation.
- New animation commands cancel the previous sequence/completion callback;
  unrelated property channels continue. A cancelled command does not complete.
- `stop` freezes values and retains velocity. `set` clears velocity for its
  specified properties. `finish` reaches final goals and calls completion.
- CFrame stays on compatibility hooks. The new controller accepts number,
  Vector2, Vector3, UDim, UDim2 and Color3.
- `useMotion` and `useReveal` accept `reducedMotion`. Imperative controllers
  use `setReducedMotion`. Emitters need application policy: stop emitting and
  clear/destroy them when reduced motion is enabled.
- `Reveal` animates its outer height. To keep scrolling layout stable, reserve
  a full-height wrapper or build a mask with `useReveal`. Clipping requires
  unrotated ancestors.

## BeeGame integration

BeeGame vendors runtime commit `387b5a64a7437c7ffcac49fe0830eede629031a4`
under `Packages.ReactFlow` and aliases `Packages.ReactFluid` to the same module.
Its runtime snapshot is hashed; branding and documentation updates in this
repository do not silently upgrade that runtime.

The game uses `createCollect` for cash/honey trails, `useMotion` for window
transitions, and a `ShopRevealRow` primitive with fixed row heights and a clipped
aperture. Its imperative Motion adapter translates the old uppercase method
names to the fork's existing lowercase SpringValue methods.

Arrival-pulse consistency and Reduced Motion closing still have unresolved live
checks. Historical library checks do not establish that these integration cases
are complete. Testing was paused at the user's request.
