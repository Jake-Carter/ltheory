# WIP Module

## Purpose

**Work-in-progress / experimental code** — loaded via `Namespace.Load('WIP')` (available as `WIP` global table, not inlined into `_G`). Contains incomplete features not yet integrated into Game or UI.

## Files (2)

| File | Responsibility |
|------|----------------|
| `Control.lua` | Input control abstraction (`ControlT` class) — axis/button mapping, icons, delta/get with deadzone/curve |
| `Gamepads.lua` | Gamepad-related experiments |

## Control.lua

Defines a reusable input control abstraction:

```lua
local control = ControlT({
  axis = Button.Gamepad.LStickX,
  deadzone = 0.1,
  curve = 'linear',
})
local value = control:get()
local delta = control:delta()
```

Intended to replace ad-hoc input handling in UI widgets and game controls. Referenced in TODOs in `UI/Canvas.lua` for future integration.

## Gamepads.lua

Experimental gamepad handling utilities — not yet wired into the main control system.

## Dependencies

- **phx**: `Button`, `Input`, `Cache`, `Math`
- Intended for future **UI** and **Game/Controls** integration

## Status

This module represents code that was being developed but not finished before the project was abandoned. The `Control` abstraction in particular would unify keyboard, mouse, and gamepad input into a single mapping layer.
