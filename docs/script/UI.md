# UI Module

## Purpose

**Custom immediate-mode UI toolkit** — hierarchical widget tree with layout, focus, drag, scroll, and draw. Used by game controls, HUD, and debug panels.

Distinct from the engine's built-in ImGui/HmGui (tested separately in `App/TestImGui.lua`, `App/TestHmGui.lua`).

Registered via `Namespace.Load('UI')` — accessed as `UI.Widget`, `UI.Canvas`, etc.

## Files (25, flat directory)

### Core

| File | Role |
|------|------|
| `Widget.lua` | **Base widget** — geometry, padding, stretch/align, input/draw virtuals, hierarchy search |
| `Container.lua` | Parent widget; child management, enable/disable fade, propagates input/layout/draw |
| `Canvas.lua` | **Root UI surface** — focus management, modal/scroll/drag state, top-level loop |
| `State.lua` | Per-frame UI state (mouse, focus, active, drag) |
| `Rect.lua` | Rectangle math |
| `DrawEx.lua` | UI drawing helpers |
| `Bindings.lua` | UI input bindings (Select, Cancel, Navigate) |

### Controls

| File | Role |
|------|------|
| `Button.lua` | Clickable button |
| `IconButton.lua` | Button with icon |
| `Checkbox.lua` | Toggle checkbox |
| `Slider.lua` | Value slider |
| `OptionSlider.lua` | Discrete option slider |
| `Label.lua` | Text label |
| `Panel.lua` | Background panel |
| `Window.lua` | Titled window container |
| `Image.lua` | Image display |
| `Icon.lua` | Icon display |
| `Graph.lua` | Data graph display |

### Layout

| File | Role |
|------|------|
| `Grid.lua` | Grid layout container |
| `Stack.lua` | Vertical/horizontal stack |
| `ScrollView.lua` | Scrollable container |
| `Stretch.lua` | Flexible space filler |
| `Collapsible.lua` | Expandable section |
| `NavGroup.lua` | Navigation group (gamepad-friendly) |
| `Hidden.lua` | Zero-size placeholder |

## Widget Pattern

Widgets use metatable inheritance from `Widget`:

```lua
local Button = {}
Button.__index = Button
setmetatable(Button, Widget)

Button.focusable = true

function Button:onDraw(focus, active)
  -- draw button appearance based on state
end

function Button:onInput()
  -- handle click
end

function Button.Create(text)
  local self = setmetatable({}, Button)
  self.text = text
  return self
end
```

### Fluent API

Setters return `self` for chaining:

```lua
widget:setPadUniform(6):setAlign(0.5, 0.5):setMinSize(100, 32)
```

## UI Loop

`Canvas` drives the per-frame cycle (called from app's `onInput`/`onUpdate`/`onDraw`):

```
input()  →  propagate to focused widget tree
update(dt)  →  animations, fade states
layoutSize()  →  compute desired sizes bottom-up
layoutPos()  →  position widgets top-down
draw()  →  render widget tree
```

## Canvas

Root container created by apps:

```lua
self.canvas = UI.Canvas()
self.canvas
  :add(self.gameView
    :add(Controls.MasterControl(self.gameView, self.player)))
```

Canvas manages:

- **Focus** — which widget receives keyboard/gamepad input
- **Active** — which widget is being interacted with (drag, press)
- **Modal state** — blocking input to widgets below
- **Scroll/drag** — scroll view and drag state tracking

## Styling

Colors and fonts come from `Config.ui` (`Config.App.lua`):

```lua
Config.ui.color = {
  accent   = Color(1.00, 0.00, 0.30, 1.0),
  focused  = Color(1.00, 0.00, 0.30, 1.0),
  background = Color(0.15, 0.15, 0.15, 1.0),
  ...
}

Config.ui.font = {
  normal = Cache.Font('Share', 14),
  title  = Cache.Font('Exo2Bold', 10),
}
```

## Game Integration

Game controls inherit from `UI.Container`:

- `Controls/MasterControl.lua` — root control bar
- `Controls/HUDControl.lua` — heads-up display
- `Controls/ShipBindings.lua` — flight control overlay

`Game/GUI/GameView.lua` is a `UI.Container` subclass that renders the 3D viewport within the widget tree.

## Dependencies

- **phx**: `Draw`, `Input`, `Font`, `Cache`, `BlendMode`, `Profiler`
- **Config**: `Config.ui.color`, `Config.ui.font`
- Used by **App** and **Game/Controls**, **Game/GUI**

## Future Work

`WIP/Control.lua` contains an input control abstraction intended for integration with UI widgets (referenced in TODOs in `Canvas`).
