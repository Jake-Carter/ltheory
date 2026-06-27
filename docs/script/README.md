# Script Layer Overview

The `script/` folder is the **game layer** for Limit Theory: Lua gameplay, UI, procedural generation, and app entry points on top of LibPHX.

## Bootstrap Flow

```
bin/lt64.exe → script/Main.lua
  → env.env          (stdlib extensions, class(), requireAll)
  → phx.phx          (FFI bindings, engine globals)
  → GlobalRestrict.On()
  → Config.App.lua (+ optional Config.Local.lua)
  → Namespace.Load: Util, UI, WIP, Gen
  → Namespace.LoadInline: Game  (all Game.* → globals)
  → jit.opt.start(Config.jit.tune.*)
  → require('App.' .. Config.app):run()
```

## Root Files

| File | Role |
|------|------|
| `Main.lua` | Entry point; sets `package.path`, bootstraps modules, launches app |
| `Config.App.lua` | Game/app configuration (debug, gen, game, render, UI) |
| `Config.Local.lua` | Optional local overrides (not in repo) |

## Module Index

| Module | Doc | Global access | Role |
|--------|-----|---------------|------|
| `App/` | [App.md](App.md) | Loaded on demand | Runnable application entry points |
| `env/` | [env.md](env.md) | Inlined utilities | Lua runtime foundation |
| `phx/` | [phx.md](phx.md) | `PHX.*` + globals | Engine binding glue |
| `Game/` | [Game.md](Game.md) | **All inlined to `_G`** | Core gameplay simulation |
| `Gen/` | [Gen.md](Gen.md) | `Gen.*` table | Procedural content generation |
| `UI/` | [UI.md](UI.md) | `UI.*` table | Custom widget toolkit |
| `Util/` | [Util.md](Util.md) | Inlined | Camera utilities |
| `jit/` | [jit.md](jit.md) | Via env | Vendored LuaJIT tooling |
| `WIP/` | [WIP.md](WIP.md) | `WIP.*` table | Experimental code |

## Cross-Cutting Patterns

| Pattern | Location | Usage |
|---------|----------|-------|
| **`class()` / `subclass()`** | `env/util/Class.lua` | OOP with chained constructors |
| **`requireAll(path)`** | `env/ext/GlobalEx.lua` | Loads every `.lua` in a directory tree |
| **`Namespace.Load` / `LoadInline`** | `env/util/Namespace.lua` | Module → global registration |
| **`GlobalRestrict`** | `env/util/GlobalRestrict.lua` | Errors on undefined globals during app run |
| **Event bus** | `Game/Entity.lua`, `Game/Event.lua` | Entity event registration and broadcast |
| **Component mixins** | `Game/Components/*.lua` | `Entity:addHealth()` etc. |
| **Action stack** | `Game/Action.lua` | AI behavior push/pop stack |
| **`Application:run()`** | `phx/util/Application.lua` | Window loop lifecycle |

## Dependency Graph

```
Main → env → phx → App
              ↓
         Game ← Gen
              ↓
             UI
```

- **env** has no dependencies (loaded first)
- **phx** depends on env; provides engine globals
- **Game** depends on phx, Gen, UI, Config
- **Gen** depends on phx, Game entity types
- **App** depends on phx, Game, UI, Gen

## Directory Tree

```
script/
├── App/                    (13 apps, flat)
├── env/
│   ├── ext/                (4 files)
│   └── util/               (16 files)
├── Game/
│   ├── Actions/            (9)
│   ├── Components/         (28)
│   ├── Controls/           (10)
│   ├── Entities/           (14)
│   ├── GUI/                (3)
│   └── Jobs/               (2)
├── Gen/
│   ├── Nebula/             (2)
│   ├── ShapeLib/           (12)
│   ├── ShipLib/            (4)
│   └── System/             (2)
├── phx/
│   └── util/               (20 files)
├── UI/                     (25 files, flat)
├── Util/                   (4 files, flat)
├── jit/                    (20 files, flat)
├── WIP/                    (2 files, flat)
├── Main.lua
├── Config.App.lua
└── Config.Local.lua
```
