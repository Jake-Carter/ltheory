# Util Module

## Purpose

**Shared game utilities** — camera controllers and object tracking helpers. Loaded with `Namespace.LoadInline('Util')` so symbols are injected directly into globals.

## Files (4)

| File | Responsibility |
|------|----------------|
| `Camera.lua` | 3D camera with view/projection matrices, stack push/pop, shader var integration |
| `CameraChase.lua` | Chase/follow camera — tracks a target with offset and smoothing |
| `CameraOrbit.lua` | Orbit camera — rotates around a target point |
| `TrackingList.lua` | List utility for tracked objects (target selection, cycling) |

## Camera

Central 3D camera used by `Game/GUI/GameView.lua`:

```lua
local camera = Camera()
camera:setPos(pos)
camera:setTarget(target)
camera:setPerspective(fov, aspect, near, far)
camera:push()   -- save state
camera:pop()    -- restore state
```

Provides view and projection matrices bound to shader uniforms via `ShaderVar`.

## Camera Modes

| Mode | Usage |
|------|-------|
| Chase | Follow player ship with configurable offset and lag |
| Orbit | Rotate around a point (debug/spectator) |

Mode selection typically driven by `Settings` or control bindings.

## TrackingList

Manages a list of trackable objects (ships, stations) for UI target selection and camera focus.

## Dependencies

- **phx**: `Vec3f`, `Quat`, `Matrix`, `ShaderVar`, `Settings`
- Used by **Game/GUI/GameView** and game controls
