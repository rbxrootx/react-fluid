# Contributing to React Fluid

Make the interaction and expected behavior concrete: describe what triggers the
motion, what happens when it reverses, and when it should stop or complete.

## Project map

| Path | Responsibility |
| --- | --- |
| `src/Fluid/` | Persistent controllers, runtime, math, easing, paths and emitters |
| `src/Components/Primitives/Reveal.luau` | The clipped reveal component |
| `src/Hooks/` and `src/Animations/` | Upstream compatibility APIs |
| `src/Fluid/MotionTokens.luau` | Default tuning; applications may supply their own tokens |
| `tests/` | Deterministic checks, benchmark and standalone Studio fixture |
| `docs/` | Installation, recipes, migration, compatibility and branding |

Preserve upstream attribution and the MIT license. Keep legacy behavior stable;
document any change to cancellation, completion, supported types or allocation.
Avoid adding per-frame React state updates, one timer per child, or unbounded
visual allocation. Include cleanup behavior in examples.

For a code change, the existing developer checks are documented in
[FLUID.md](FLUID.md#runtime-and-performance). Run only the checks appropriate to
the work and authorized by the current task. A docs/logo update does not require
starting Studio, running benchmarks or changing gameplay. State which checks
were actually run; historical results are not new validation.

Keep installation instructions aligned with the package's release status.
Do not advertise a Wally version until it is actually published.
