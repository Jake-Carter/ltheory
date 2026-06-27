# Gen Module

## Purpose

**Procedural content generation** — procedural meshes, star systems, ships, stations, nebulae, and asteroids. Generators register with a weighted registry and are consumed by Game entities at spawn time.

Registered via `Namespace.Load('Gen')` — accessed as `Gen.Generator`, `Gen.SystemGenerator`, etc., and also inlined where modules self-register.

## Structure

```
Gen/
├── Generator.lua         # Weighted registry API
├── SystemGenerator.lua   # System builder wrapper
├── Ship.lua              # Ship facade (fighter/capital dispatch)
├── ShipFighter.lua       # Fighter ship generator
├── ShipCapital.lua       # Capital ship generator
├── Station.lua           # Station generator
├── StationOld.lua        # Legacy station generator
├── Asteroid.lua          # SDF-based asteroid generator
├── Starfield.lua         # Background star field
├── Primitive.lua         # Basic mesh primitives
├── GenUtil.lua           # Shared generation utilities
├── MathUtil.lua          # Math helpers for generation
├── MeshUtil.lua          # Mesh manipulation helpers
├── DiffuseMap.lua        # Diffuse texture generation
├── ColorLUT.lua          # Color lookup tables
├── UVMap.lua             # UV mapping utilities
├── Boxes.lua             # Box layout utilities
├── Sandbox.lua           # Generation sandbox/experiments
├── ShapeLib/             (12) Procedural mesh building blocks
├── ShipLib/              (4)  Ship part generators
├── System/               (2)  System-level generators
└── Nebula/               (2)  Nebula generators
```

## Generator Registry

`Generator.lua` provides the core API:

```lua
Generator.Add(type, weight, fn)   -- Register a generator
Generator.Get(type, rng)          -- Pick weighted generator, call it
```

Generators self-register at module load time:

```lua
-- System/SystemBasic.lua
Generator.Add('System', 1.0, generateSystemBasic)

-- Nebula/Nebula1.lua
Generator.Add('Nebula', 1.0, generateNebulaIFS)
```

Selection uses `Distribution` from `phx/util/Distribution.lua` for weighted random choice.

## SystemGenerator

Builder wrapping `Game.Entities.System` with RNG:

```lua
local gen = SystemGenerator(rng)
gen:add('Station', ...)       -- Add entity via generator
gen:addZone(...)              -- Add spatial zone
gen:finalize()                -- Complete system setup
```

Used by `System/SystemBasic.lua` to populate star systems with fields, stations, planets, and asteroid belts based on `Config.gen` parameters.

## ShapeLib (12 files)

Procedural mesh building blocks for ship/station construction:

| File | Role |
|------|------|
| `Shape.lua` | Core poly mesh CSG operations (verts, polys, merge, validity) |
| `Joint.lua` | Joint connections between shapes |
| `Cluster.lua` | Shape clustering |
| `Module.lua` | Modular ship/station sections |
| `Parametric.lua` | Parametric surface generation |
| `Scaffolding.lua` | Structural scaffolding |
| `BasicShapes.lua` | Primitives (box, cylinder, etc.) |
| `RandomShapes.lua` | Randomized shape generation |
| `Style.lua` | Visual style parameters |
| `Warp.lua` | Mesh warping/deformation |
| `JointField.lua` | Field-based joint placement |

## ShipLib (4 files)

Ship part generators for capital ships:

| File | Role |
|------|------|
| `ShipCapitalHull.lua` | Capital ship hull generation |
| `ShipCapitalCockpit.lua` | Cockpit section |
| `ShipDetail.lua` | Surface detail elements |
| `ShipWarps.lua` | Warp engine/nacelle geometry |

## System Generators (2 files)

| File | Role |
|------|------|
| `SystemBasic.lua` | Basic star system — fields, stations, planets, belts |
| `AsteroidField.lua` | Asteroid field placement |

## Nebula Generators (2 files)

| File | Role |
|------|------|
| `Nebula1.lua` | IFS-based nebula volume |
| `Nebula2.lua` | Light transport nebula |

## Key Generators

### Ships

`Ship.lua` dispatches to `ShipFighter` or `ShipCapital` based on type. Produces `LodMesh` with materials for use by `Entities.Ship`.

### Stations

`Station.lua` generates station geometry using ShapeLib modules. Scale controlled by `Config.game.stationScale`.

### Asteroids

`Asteroid.lua` uses SDF-based LOD mesh generation — creates signed distance fields, converts to meshes at multiple detail levels.

### Starfield

`Starfield.lua` generates background star positions/count from `Config.gen.nStars`.

## Configuration

Generation parameters in `Config.gen` (`Config.App.lua`):

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `seedGlobal` | nil | Force deterministic global RNG |
| `seedSystem` | nil | Force deterministic system generation |
| `origin` | (0,0,0) | World origin offset |
| `nFields` | 20 | Number of spatial fields in system |
| `nStations` | 0 | Stations per system (generator may override) |
| `nPlanets` | 1 | Planets per system |
| `nStars` | fn | Star count (function of RNG) |
| `shipRes` | 8 | Ship mesh resolution |
| `nebulaRes` | 1024 | Nebula texture resolution |
| `scalePlanet` | 2000 | Planet size scale |
| `playerShipSize` | 4 | Player ship scale |

## Dependencies

- **phx**: `Cache`, `Mesh`, `SDF`, `LodMesh`, `RNG`, shaders
- **Game**: Entity types used as generation output (`System`, `Station`, `Planet`, `Asteroid`)
- **Config**: `Config.gen.*` parameters

## Usage in Game

`Entities/System.lua` spawn methods call generators:

```lua
function System:spawnShip(rng)
  local mesh, lodMesh, material = Gen.Ship(rng, Config.gen.playerShipSize)
  return Entities.Ship({ mesh = mesh, lodMesh = lodMesh, material = material })
end
```

`LTheory.lua` calls `self.system:spawnShip()`, `spawnStation()`, `spawnAsteroidField()` during world generation.
