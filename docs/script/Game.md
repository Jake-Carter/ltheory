# Game Module

## Purpose

**Core gameplay simulation** — entity/component architecture, AI actions, economy hooks, input controls, in-game GUI, and world entities (ships, stations, asteroids, systems).

Loaded with **`Namespace.LoadInline('Game')`**, so `Entities`, `Actions`, `Controls`, `GUI`, `Event`, etc. are globals without a prefix.

## Structure

```
Game/
├── Entity.lua, Action.lua, Event.lua, Flow.lua    # Core abstractions
├── Item.lua, Job.lua, Production.lua, Content.lua  # Economy (partial)
├── Material.lua, Socket.lua, SocketType.lua        # Asset/type defs
├── ShipType.lua, SystemMap.lua, DebugContext.lua   # Game data
├── Actions/          (9)   AI behavior types
├── Components/       (28)  Entity capability mixins
├── Controls/         (10)  Input control schemes
├── Entities/         (14)  Concrete entity types
├── GUI/              (3)   In-game UI panels
└── Jobs/             (2)   Economy job actions
```

## Core Abstractions

### Entity (`Entity.lua`)

Base class for all game objects:

- Unique ID assignment
- Event handler registry: `register(eventType, handler)`, `send(event)`
- `delete()` for cleanup

### Event (`Event.lua`)

Factory functions for event types:

| Event | Purpose |
|-------|---------|
| `Event.Update` | Per-frame simulation tick |
| `Event.UpdatePost` | Post-physics update |
| `Event.Broadcast` | Propagate to all children |
| `Event.Render` | Draw this entity |
| `Event.Damaged` | Health changed |
| `Event.ChildAdded` | Hierarchy change |
| `Event.Debug` | Debug overlay draw |

### Action (`Action.lua`)

Base AI action with virtual lifecycle:

- `clone()` — copy for new entity
- `onStart()`, `onStop()` — push/pop transitions
- `onUpdateActive(dt)` — called when action is on top of stack
- `onUpdatePassive(dt)` — called when action is below top

Shared helper `flyToward(ship, target, offset)` implements basic steering.

### Flow (`Flow.lua`)

Simple value object: item + rate + location (economy flow representation). Used by production/market systems (incomplete).

## Components (28)

Components are mixin modules that add methods to `Entity`. Entities call `add*` methods in their constructors.

| Component | Adds | Key behavior |
|-----------|------|--------------|
| `Actions` | `addActions()` | Action stack push/pop/clear/update |
| `Health` | `addHealth(max, regen)` | Damage, healing, death |
| `RigidBody` | `addRigidBody(dynamic, mesh)` | Physics body wrapper |
| `ThrustController` | `addThrustController()` | Ship thrust and rotation |
| `VisibleMesh` | `addVisibleMesh(mesh, mat)` | Static mesh rendering |
| `VisibleLodMesh` | `addVisibleLodMesh(lodMesh, mat)` | LOD mesh rendering |
| `Light` | `addLight(...)` | Point/ambient light source |
| `Children` | `addChildren()` | Parent/child tree + broadcast |
| `Sockets` | `addSockets(...)` | Hardpoint attachment points |
| `Projectiles` | `addProjectiles()` | Weapon firing |
| `Inventory` | `addInventory()` | Item storage |
| `Factory` | `addFactory()` | Production chains |
| `Market` | `addMarket()` | Trading |
| `Trader` | `addTrader()` | AI trading behavior |
| `Credits` | `addCredits()` | Currency |
| `Capacitor` | `addCapacitor()` | Energy pool for boost/weapons |
| `Name` | `addName()` | Display name |
| `Messages` | `addMessages()` | In-game message queue |
| `Dispositions` | `addDispositions()` | Faction relationships |
| `Explodable` | `addExplodable()` | Death explosion effect |
| `Flows` | `addFlows()` | Economy flow tracking |

## Entities (14)

| Entity | Description |
|--------|-------------|
| `System` | **Root world entity** — physics world, starfield, nebula/dust, spawn helpers, update loop |
| `Ship` | Player/NPC ship — actions, health, rigid body, thrust, sockets, mesh |
| `Player` | Non-physical owner; `setControlling(ship)` |
| `Station` | Space station with docking |
| `Asteroid` | Procedurally generated asteroid |
| `Planet` | Planetary body |
| `Nebula` | Volumetric nebula visual |
| `Dust` | Ambient dust particles |
| `Pulse` | Projectile/pulse weapon effect |
| `Thruster` | Engine exhaust visual |
| `Turret` | Weapon turret |
| `Trigger` | Physics trigger volume |
| `Zone` | Spatial zone marker |

`System` is the central hub — it owns the Bullet physics world (zero gravity), manages child entities, and runs the per-frame update sequence.

### System Update Loop

```
1. Send Event.Update to players
2. Send Event.Update to self
3. Broadcast Event.Update to all children
4. Run physics step
5. Send Event.UpdatePost
```

## Actions (9)

| Action | Behavior |
|--------|----------|
| `MoveTo` | Fly to a target position |
| `Attack` | Engage a hostile target |
| `Escort` | Follow and protect a ship at offset |
| `DockAt` | Approach and dock at station |
| `Undock` | Leave dock |
| `MineAt` | Mine an asteroid |
| `Think` | Pause/decision delay |
| `Wait` | Timed wait |
| `Repeat` | Repeat a sub-action |

## Controls (10)

Input control schemes, typically inheriting from `UI.Container`:

| Control | Role |
|---------|------|
| `MasterControl` | Switches between Ship/HUD/Command/Dock modes |
| `ShipBindings` | Flight controls (thrust, pitch, yaw, boost, fire) |
| `HUDControl` | Heads-up display interactions |
| `CommandControl` | Fleet/command interface |
| `DockControl` | Docking UI |
| `DebugControl` | Debug panel bindings |
| `CommandBindings` | Command-mode key bindings |

## GUI (3)

| File | Role |
|------|------|
| `GameView` | 3D render viewport — deferred lighting, camera, world render |
| `DebugWindow` | ImGui debug panel with settings/metrics |
| `DebugInspector` | Entity inspection overlay |

## Jobs (2)

Economy job types (partial implementation):

- `Mine` — mining job action
- `Transport` — cargo transport job

## Architecture Example

```lua
-- Entities/Ship.lua (simplified)
local Ship = subclass(Entity, function (self, proto)
  self:addActions()
  self:addHealth(Config.game.shipHealth, Config.game.shipHealthRegen)
  self:addRigidBody(true, proto.mesh)
  self:addThrustController()
  self:addVisibleLodMesh(proto.lodMesh, proto.material)
  self:addSockets(proto.sockets)
  -- register Event handlers
  self:register(Event.Update, self.onUpdate)
  self:register(Event.Render, self.onRender)
end)
```

## Dependencies

- **phx**: Physics, Draw, Cache, Profiler, engine math types
- **Gen**: Procedural meshes for ships/stations/asteroids/nebulae
- **UI**: Control containers inherit from `UI.Container`
- **Config**: `Config.game`, `Config.gen`, `Config.ui`, `Config.debug`

## Incomplete Systems

- `Content.lua` — stub for mod-style item/production registration
- Economy (`Market`, `Trader`, `Jobs/`, `TestEcon.lua`) — partially implemented
- AI squad behavior — escort/attack actions exist but squad logic is minimal
