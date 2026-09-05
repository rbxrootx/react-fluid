# Installing React Fluid

React Fluid 0.6.0 is experimental and has not been published to Wally. The upstream
`outofbears/react-flow@0.5.0` package does not include this fork's new APIs.

## Existing Rojo game

Fetch a reviewed revision, then keep its `src` folder and `LICENSE.md` in a
vendor directory. For example, the first merged implementation is pinned here:

```bash
git clone https://github.com/rbxrootx/react-fluid.git
git -C react-fluid checkout 387b5a64a7437c7ffcac49fe0830eede629031a4
```

Copy that checkout's `src` and `LICENSE.md` into your game's
`vendor/react-fluid/`. Record the commit alongside the copy. The runtime pin
above deliberately stays reproducible as newer documentation is published.

Install React, ReactRoblox and Promise with your game's normal package manager:

```toml
[dependencies]
React = "jsdotlua/react@17.2.1"
ReactRoblox = "jsdotlua/react-roblox@17.2.1"
Promise = "evaera/promise@4.0.0"
```

Merge this fragment into your Rojo project's `ReplicatedStorage` node:

```json
"Packages": {
  "$path": "Packages",
  "ReactFluid": { "$path": "vendor/react-fluid/src" }
}
```

The required DataModel layout is:

```text
ReplicatedStorage
└── Packages
    ├── React
    ├── ReactRoblox
    ├── Promise
    └── ReactFluid
        ├── Fluid
        ├── Hooks
        └── ...
```

The root module, its children, React and Promise must remain in this arrangement.
Use the **same React package** as the application's ReactRoblox renderer.

```lua
local Fluid = require(game:GetService("ReplicatedStorage").Packages.ReactFluid)
```

For existing `Packages.ReactFlow` call sites, mount the source under that name
instead, remove the upstream ReactFlow Wally dependency, and optionally create
a sibling `ReactFluid` ModuleScript returning
`require(script.Parent.ReactFlow)`. Both imports then share one module. Do not
install two source copies to provide the two names. See [migration](migration.md).

## Standalone Studio model

From this repository's checkout:

```bash
wally install
rojo build fluid.project.json -o ReactFluid.rbxm
```

Insert the model into Studio and require its `ReactFluid` child. This portable
model includes dependency aliases and its own installed packages. For an existing
React application, prefer the shared-package layout above; a second React copy
cannot supply hooks to a root created with the first copy.

Building a model does not publish a Wally release or publish your game.
