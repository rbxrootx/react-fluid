# Changelog

## Unreleased — documentation and branding

- Rebuilt the README around React Fluid and replaced the upstream logo with a
  new RF identity derived from it.
- Added installation, recipes, migration, compatibility and branding guides.
- Corrected package-install instructions and documented BeeGame's pinned adoption.
- Kept experimental limitations and unresolved integration checks explicit.
- No animation runtime or game dependency pin changed in this update.

## 0.6.0 experimental — first merged implementation

Merged in [PR #1](https://github.com/rbxrootx/react-fluid/pull/1), based on upstream
React Flow 0.5.0. This is a source version, not a published Wally release.

- Persistent motion controllers and React bindings with velocity-preserving springs.
- Seven spring presets, physical spring conversion, custom easing and Bezier curves.
- Overlapping timeline cues, capped staggers and reversible 2D clipped reveals.
- Continuous paths and bounded reusable collectible emitters.
- Shared scheduling that sleeps at rest, plus manual runtimes.
- Preserved React Flow compatibility hooks and original MIT attribution.

See [validation history and limitations](FLUID.md#runtime-and-performance) for
the scope of earlier checks and benchmark measurements.
