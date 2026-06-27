# App Module

## Purpose

**Application entry points** — each file is a standalone runnable program selected by `Config.app` or the CLI argument to `lt64.exe`.

```bash
bin/lt64.exe                  # default: LTheory
bin/lt64.exe PhysicsTest      # specific app
```

## Files (13)

| File | Responsibility |
|------|----------------|
| `LTheory.lua` | **Main game** — generates star system, spawns player ship/escorts/stations/asteroids, wires GameView + MasterControl |
| `PhysicsTest.lua` | Physics/collision sandbox |
| `TestEcon.lua` | Economy/system simulation test |
| `BSPTest.lua` | BSP spatial query test |
| `CoordTest.lua` | Coordinate system test |
| `InputTest.lua` | Input device test |
| `FMODTest.lua` | Audio test |
| `GenTex2D.lua` | Texture generation test |
| `TestIcon.lua` | Icon rendering test |
| `TestStrMap.lua` | String map test |
| `TestHmGui.lua` | HmGui integration test |
| `TestImGui.lua` | ImGui integration test |
| `Todo.lua` | Scratch/notes app |

## Entry Point Pattern

Every app follows this structure:

```lua
local MyApp = Application()  -- class from phx.util.Application

function MyApp:onInit()   ... end   -- setup after window/GL created
function MyApp:onInput()  ... end   -- per-frame input
function MyApp:onUpdate(dt) ... end -- simulation step
function MyApp:onDraw()   ... end   -- rendering

return MyApp  -- Main.lua calls :run()
```

`Application:run()` (in `phx/util/Application.lua`) creates the window, runs Preload, loads gamepad DB, then loops: `Engine.Update()` → resize check → input → update → draw → swap.

## LTheory.lua (Main Game)

The canonical reference implementation:

1. **`generate()`** — Creates a seeded `Entities.System`, spawns player ship with 100 escorts, 1 station, 1 asteroid field.
2. **`onInit()`** — Creates player entity, calls generate, sets up `GUI.GameView` inside `UI.Canvas` with `Controls.MasterControl`.
3. **`onUpdate(dt)`** — Updates player root entity tree and UI canvas.
4. **`onDraw()`** — Draws UI canvas (which includes the 3D game view).

## Dependencies

- **phx**: `Application()`, engine types
- **Game** (globals): `Entities`, `Actions`, `Controls`, `GUI`
- **UI**: `UI.Canvas`
- **Config**: `Config.gen`, `Config.game`, etc.

Some test apps mutate `Config` before `:run()` for app-specific settings.
