# phx Module

## Purpose

**Phoenix engine Lua bindings layer** — loads FFI wrappers from `libphx/script/`, registers C types, and provides engine-level utilities (Application framework, caching, rendering helpers).

This module bridges the C engine DLL and game code. After `require('phx.phx')`, engine types like `Window`, `Mesh`, `Physics`, `Draw`, `Input` are available as globals.

## Structure

```
phx/
├── phx.lua           # Main loader
└── util/             # 20 utility files
    ├── Application.lua
    ├── ApplicationBindings.lua
    ├── Cache.lua
    ├── Preload.lua
    ├── Renderer.lua
    ├── Distribution.lua
    ├── CType.lua
    └── ...
```

## Key Files

| File | Responsibility |
|------|----------------|
| `phx.lua` | Loads FFI + extensions, registers types, injects globals |
| `util/Application.lua` | **`Application` base class** — window, main loop, profiler, hot-reload |
| `util/ApplicationBindings.lua` | Global key bindings (exit, profiler, screenshot, reload) |
| `util/Preload.lua` | Registry of init-time preload callbacks (after GL context exists) |
| `util/Cache.lua` | Lazy-loaded asset cache (fonts, shaders, textures) |
| `util/Distribution.lua` | Weighted random sampling |
| `util/Renderer.lua` | Deferred/world rendering helpers |
| `util/CType.lua`, `CArray.lua`, `CPointer.lua` | C interop helpers |
| `util/Wrapper.lua` | Generic FFI object wrapper utilities |
| `util/ScreenCap.lua` | Screenshot capture |
| `util/Type.lua` | Custom type registry for opaque/struct FFI types |

## phx.lua Loading Sequence

```lua
PHX.Ext  = requireAll('ffiext')   -- register onDef_* hooks
PHX.Lib  = require('ffi.libphx')   -- load libphx64.dll
PHX.FFI  = requireAll('ffi')       -- all ffi/*.lua modules
Namespace.Inline(PHX.FFI)          -- Window, Mesh, etc. → _G
PHX.Util = requireAll('phx.util')
Namespace.Inline(PHX.Util)
```

Also registers opaque pointer types and struct types with the `Type`/`CType` system for use in game code.

## Application Framework

`Application:run()` lifecycle:

1. Create window with `getDefaultSize()`, `getTitle()`, `getWindowMode()`
2. Set vsync from `Config.render.vsync`
3. Run `Preload.Run()` — eager asset loading
4. Load gamepad database
5. Call `onInit()`, `onResize()`
6. Main loop until `self.exit`:
   - `Engine.Update()` — poll input
   - Resize check → `onResize()`
   - `onInput()`
   - Fixed-timestep update → `onUpdate(dt)`
   - `onDraw()` inside window begin/end draw
7. Call `onExit()`

Virtual methods default to no-ops; apps override as needed.

### Hot Reload

`ApplicationBindings` registers a reload key that calls `Engine.Reload()` — re-executes `script/Main.lua` without restarting the process (development convenience).

## Cache

Central asset loading with memoization:

```lua
Cache.Font('Share', 14)
Cache.Shader('wvp', 'material/metal')   -- vertex + fragment
Cache.Tex2D('icon/gamepad')
```

Assets resolve through the engine resource system (`res/` paths).

## Preload

```lua
Preload.Add(function ()
  -- Called once after GL context is ready, before onInit
  Cache.Shader('wvp', 'material/metal')
end)
```

## Dependencies

- **env**: Namespace, Log, Config, class
- **libphx/script/**: FFI bindings (external to `script/phx/`)

Used by all other script modules.
