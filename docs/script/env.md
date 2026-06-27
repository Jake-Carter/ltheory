# env Module

## Purpose

**Lua runtime foundation** — extensions to the standard library, core utilities, and bootstrap for everything else. Loaded first via `require('env.env')` before any game code.

## Structure

```
env/
├── env.lua           # Bootstrap entry
├── ext/              # Standard library extensions
│   ├── GlobalEx.lua  # requireAll, ffi/jit setup, printf
│   ├── IOEx.lua      # I/O extensions
│   ├── StringEx.lua  # String helpers
│   └── TableEx.lua   # Table helpers
└── util/             # Core utilities (16 files)
    ├── Class.lua
    ├── Namespace.lua
    ├── Config.lua
    ├── GlobalRestrict.lua
    ├── Log.lua
    ├── Settings.lua
    └── ...
```

## Key Files

| File | Responsibility |
|------|----------------|
| `env.lua` | Bootstraps `Env.Ext`, `Env.Util`; defines `Env.Call(fn)` with xpcall error handling |
| `util/Class.lua` | `class(ctor)` and `subclass(base, ctor)` — project-wide OOP |
| `util/Namespace.lua` | `Load`, `LoadInline`, `Inject` — module → global registration with shadow warnings |
| `util/Config.lua` | Base `Config` table (JIT profiling/dump/tuning defaults) |
| `util/GlobalRestrict.lua` | Metatable on `_G` that errors on undefined globals during app run |
| `util/Log.lua` | Logging with levels |
| `util/Settings.lua` | Runtime-tweakable settings registry (debug UI, render options) |
| `util/List.lua`, `Map.lua`, `Copy.lua`, `Ref.lua` | Data structure utilities |
| `util/ErrorHandler.lua` | Stack trace formatter for xpcall |
| `util/Event.lua`, `EventManager.lua` | Generic event utilities |
| `util/Jit.lua` | Wrappers for LuaJIT profiling/dump/verbose |
| `ext/GlobalEx.lua` | Sets up `ffi`, `jit`, math globals, **`requireAll()`** |

## Patterns

### class / subclass

```lua
local MyClass = class(function (self, arg)
  self.value = arg
end)

function MyClass:method() ... end

local Child = subclass(MyClass, function (self, arg)
  MyClass.__init(self, arg)
  self.extra = true
end)
```

Constructors chain via `__init`. Metatables provide method dispatch.

### requireAll

Scans a directory on `package.path`, recursively requires all `.lua` files, returns a table keyed by filename (without extension):

```lua
local entities = requireAll('Game.Entities')
-- entities.Ship, entities.Station, ...
```

### Namespace

```lua
Namespace.Load('UI')           -- Creates global UI = { Widget = ..., Canvas = ... }
Namespace.LoadInline('Game')     -- Injects Game.* symbols directly into _G
Namespace.Inject(target, prefix, source, sourcePrefix)
```

`LoadInline` is used for Game so `Entities`, `Actions`, `Event` etc. are available as globals without prefix.

### GlobalRestrict

Enabled during app execution in `Main.lua`. Any read/write to an undefined global raises an error, catching typos early.

### Env.Call

Wraps the entire app startup:

```lua
Env.Call(function ()
  -- app bootstrap; errors caught and printed
end)
```

## Dependencies

None — this is the first layer. Everything else depends on `env`.
