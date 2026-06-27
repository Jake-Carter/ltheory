# Limit Theory — System Design

Limit Theory is an open-world space simulation game built as a **thin C executable + shared engine library + Lua gameplay layer**. The original project was cancelled; this repository preserves the second-generation codebase where all gameplay migrated from C++/LTSL to C and LuaJIT.

For the older C++/LTSL codebase, see [ltheory-old](https://github.com/JoshParnell/ltheory-old).

## Design Goals

The architecture reflects several deliberate choices visible in the code:

1. **Script-first gameplay** — The executable does almost nothing except bootstrap Lua. All game logic, UI, and procedural generation live in `script/`.
2. **FFI over C bindings** — Engine APIs are exposed as plain C functions (`PHX_API`), bound from Lua via LuaJIT FFI rather than hand-written Lua C modules.
3. **Performance in C** — Rendering, physics, audio, spatial queries, and asset I/O stay in LibPHX (`libphx/`).
4. **Moddability** — Multiple apps under `script/App/` can be launched via CLI; configuration is layered and overridable.

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  lt64.exe  (src/Main.cpp)                                        │
│  Engine_Init → Lua state → script/Main.lua                       │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│  script/  — Game Layer                                           │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │  App/   │ │  Game/  │ │  Gen/   │ │  UI/    │ │  env/   │  │
│  │ entry   │ │ sim     │ │ proc    │ │ widgets │ │ runtime │  │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘  │
│       └───────────┴───────────┴───────────┴───────────┘         │
│                           phx/ (binding glue)                    │
└────────────────────────────┬─────────────────────────────────────┘
                             │ LuaJIT FFI
┌────────────────────────────▼─────────────────────────────────────┐
│  libphx/  — LibPHX Engine (C/C++)                                │
│  Rendering · Physics · Audio · Input · Resources · Lua host      │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│  Third-party: SDL2 · OpenGL/GLEW · Bullet · FMOD · FreeType      │
│               LuaJIT · LZ4 · stb                                 │
└──────────────────────────────────────────────────────────────────┘
```

## Repository Layout

| Path | Role |
|------|------|
| `src/Main.cpp` | Minimal host executable; sets Lua globals, runs `script/Main.lua` |
| `libphx/` | Engine submodule — C sources, headers, FFI scripts, vendored deps |
| `script/` | All gameplay, UI, generation, and app entry points |
| `res/` | Runtime assets: shaders, textures, sounds, meshes, grammars |
| `bin/` | Build output: executable, engine DLL, copied third-party DLLs |
| `CMakeLists.txt` | Root CMake project (configure with `cmake -S . -B build`) |
| `build/` | Generated CMake/MSBuild files (not committed) |

## Startup Sequence

```
lt64.exe
  │
  ├─ Engine_Init(2, 1)          OpenGL 2.1 compatibility context
  ├─ Lua_Create()
  ├─ Set globals: __debug__, __embedded__, __checklevel__, __app__
  └─ Lua_DoFile("./script/Main.lua")
       │
       ├─ require('env.env')         Class system, stdlib extensions
       ├─ require('phx.phx')          Load libphx64.dll, inject engine globals
       ├─ GlobalRestrict.On()         Guard against accidental globals
       ├─ dofile Config.App.lua       Game configuration
       ├─ Namespace.Load(Util, UI, WIP, Gen)
       ├─ Namespace.LoadInline(Game) Inject all Game.* into _G
       ├─ jit.opt.start(...)          Tune LuaJIT trace compiler
       └─ require('App.' .. app):run()
            │
            └─ Application:run()      Window loop until exit
```

Working directory: `Main.cpp` expects `./script/Main.lua`. If not found (e.g. when launched from `bin/`), it `chdir`s to the parent directory so the repo root becomes CWD. All asset paths resolve relative to the repo root.

## Layer Responsibilities

### Host (`src/`)

- Initialize SDL subsystems and OpenGL via the engine
- Create a LuaJIT state with standard libraries
- Pass compile-time flags and optional app name to Lua
- No game logic

### Engine (`libphx/`)

LibPHX provides the stable C API surface. Major subsystems:

| Subsystem | Key modules | Purpose |
|-----------|-------------|---------|
| Platform | `Engine`, `Window`, `OS` | SDL init, GL context, timing |
| Rendering | `Draw`, `Shader`, `RenderState`, `RenderTarget` | Legacy GL + GLSL pipeline |
| Geometry | `Mesh`, `LodMesh`, `Tex2D/3D/Cube`, `SDF` | GPU assets and procedural mesh tools |
| Spatial | `BSP`, `Octree`, `KDTree`, `BoxTree` | Acceleration structures for queries |
| Physics | `Physics`, `RigidBody`, `CollisionShape` | Bullet Physics wrapper |
| Audio | `Audio`, `Sound`, `SoundDesc` | FMOD 3D audio |
| Input | `Input`, `Keyboard`, `Mouse`, `Gamepad` | Unified device model |
| Resources | `Resource`, `File`, `Directory` | Typed asset path resolution |
| UI (engine) | `Font`, `ImGui`, `HmGui`, `UIRenderer` | FreeType + immediate-mode GUIs |
| Script host | `Lua`, `LuaScheduler` | VM lifecycle, timed callbacks |

See [libphx.md](libphx.md) for full module reference.

### FFI Binding Layer (`libphx/script/` + `script/phx/`)

- `libphx/script/ffi/libphx.lua` loads the DLL and declares shared C types
- One Lua file per C module in `ffi/` — declares functions, builds metatypes
- `ffiext/` adds ergonomic Lua sugar (operators, helpers) via `onDef_*` hooks
- `script/phx/phx.lua` bulk-loads everything and injects engine types as globals (`Window`, `Mesh`, `Physics`, …)

### Game Script Layer (`script/`)

| Module | Global access | Role |
|--------|---------------|------|
| `env/` | Inlined utilities | OOP (`class`), Namespace, Config base, logging |
| `phx/` | `PHX.*` + inlined util | Application framework, asset cache, render helpers |
| `Game/` | **All inlined to `_G`** | Entity/component sim, AI, controls, in-game GUI |
| `Gen/` | `Gen.*` table | Procedural ships, stations, systems, nebulae |
| `UI/` | `UI.*` table | Widget toolkit used by controls and debug panels |
| `Util/` | Inlined | Camera controllers |
| `App/` | Loaded on demand | Runnable programs (`LTheory`, test harnesses) |

See [script/README.md](script/README.md) and per-module docs.

## Game Architecture

### Entity–Component (Mixin Style)

There is no formal ECS framework. Instead, components are Lua modules that add methods directly to the base `Entity` class:

```lua
-- Components/Health.lua adds Entity:addHealth(max, regen)
local Ship = subclass(Entity, function (self, proto)
  self:addHealth(100, 10)
  self:addRigidBody(true, proto.mesh)
  self:addThrustController()
end)
```

Entities communicate via a lightweight **event bus** (`Event.Update`, `Event.Damaged`, `Event.Render`, …) with parent→child broadcast through `Components/Children.lua`.

### Action Stack AI

Non-player ships use a **stack of Action objects** (`Game/Action.lua`). The top action receives `onUpdateActive`; lower actions are passive. Built-in actions include `MoveTo`, `Attack`, `Escort`, `DockAt`, `MineAt`, `Think`, `Wait`.

### World Hierarchy

```
System (root entity)
  ├─ Player (non-physical owner, controls a ship)
  ├─ Ship(s) — player and NPC
  ├─ Station(s)
  ├─ AsteroidField
  ├─ Planet(s)
  ├─ Nebula, Dust (ambient visuals)
  └─ Physics world (Bullet, zero gravity)
```

`Entities/System.lua` owns the physics world, starfield, nebula/dust, and the per-frame update loop.

### Procedural Generation

Generators register with `Gen.Generator.Add(type, weight, fn)` at load time. When spawning content, `Generator.Get(type, rng)` picks a weighted implementation. System layout, ship meshes, station geometry, and nebula volumes are all procedurally generated from seeded RNG.

### Rendering Pipeline (Game View)

`Game/GUI/GameView.lua` drives the 3D viewport:

- Deferred-style lighting passes using cached shaders from `res/shader/`
- Camera from `Util/Camera.lua` with chase/orbit modes
- World entities render via `Event.Render` handlers on components like `VisibleMesh`, `VisibleLodMesh`, `Light`

### UI Architecture

Two UI systems coexist:

1. **Custom widget tree** (`script/UI/`) — hierarchical layout used by game controls and HUD
2. **Engine ImGui/HmGui** — immediate-mode debug panels (`Game/GUI/DebugWindow.lua`)

The main game wires `UI.Canvas` as the root, containing `GameView` and `MasterControl`.

## Configuration

Configuration is layered:

| Source | Contents |
|--------|----------|
| `env/util/Config.lua` | JIT tuning defaults |
| `script/Config.App.lua` | App name, debug, generation, game balance, render, UI |
| `script/Config.Local.lua` | Optional developer overrides (not in repo) |
| CLI argument to `lt64.exe` | Sets `__app__` global to select `script/App/<name>.lua` |

Note: `Config.debug` controls in-game debug UI and physics wireframes. It is **separate** from `__debug__`, which selects the engine DLL variant at load time.

## Asset Pipeline

Assets live in `res/` and are resolved at runtime by resource type:

| Type | Search paths (examples) |
|------|-------------------------|
| Shader | `./res/shader/<name>.glsl` |
| Texture | `./res/tex2d/<name>.png`, `.jpg` |
| Mesh | `./res/mesh/<name>.obj`, `.bin` |
| Sound | `./res/sound/<name>.ogg`, `.wav`, `.mp3` |
| Font | `./res/font/<name>.ttf` |
| Script | `./res/script/<name>.lua` |

Shaders use `#include` from `res/shader/include/`. The `Cache` utility (`script/phx/util/Cache.lua`) lazily loads and retains fonts, shaders, and textures.

Large binary assets (images, meshes, audio) are tracked via **Git LFS**.

## Extension Points

| Extension | Mechanism |
|-----------|-----------|
| New runnable app | Add `script/App/MyApp.lua` returning an `Application` subclass; run with `lt64.exe MyApp` |
| New entity type | Add `script/Game/Entities/MyEntity.lua`; auto-loaded via `requireAll('Game.Entities')` |
| New component | Add `script/Game/Components/MyComponent.lua` with `Entity:addMyComponent()` |
| New generator | Call `Generator.Add('Type', weight, fn)` in a Gen module |
| New engine binding | Add C functions in libphx, mirror in `libphx/script/ffi/`, optional `ffiext/` sugar |
| Mod content | `Game/Content.lua` has placeholder hooks for item/production registration |

## Technology Stack Summary

| Layer | Technology |
|-------|------------|
| Language (engine) | C/C++11, no exceptions, no RTTI |
| Language (game) | LuaJIT 2.1 (Lua 5.1 API) |
| Window/Input | SDL 2.0.14 |
| Graphics | OpenGL 2.1 + GLEW 2.0 + GLSL 1.30 |
| Physics | Bullet 2.87 |
| Audio | FMOD Studio 1.10 |
| Fonts | FreeType 2.8 |
| Compression | LZ4 1.7.5 |
| Build | CMake 3.5+, MSVC (Windows primary) |

See [build-and-maintenance.md](build-and-maintenance.md) for dependency details and build configuration.

## Known State of the Project

This is an **abandoned work-in-progress**. Expect incomplete systems:

- Economy (`TestEcon.lua`, `Jobs/`, `Components/Market.lua`) is partially implemented
- `Game/Content.lua` is a stub for mod-style content registration
- Linux build paths exist in CMake but are incomplete (`# TODO`)
- Font files referenced in config (`Share`, `Exo2Bold`, `NovaMono`) may not be present in all checkouts
- Many test apps under `script/App/` exist for isolated engine feature validation

The default app `LTheory.lua` generates a star system with a player ship, escorts, a station, and an asteroid field — enough to fly around and test core systems.
