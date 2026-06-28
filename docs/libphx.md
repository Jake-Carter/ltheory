# LibPHX Engine Reference

LibPHX is the C/Lua game engine that powers Limit Theory. It ships as a shared library (`libphx64.dll` on Windows) with a thin executable (`lt64.exe`) that embeds LuaJIT and loads gameplay scripts. Game logic lives almost entirely in Lua; the C layer provides performance-critical subsystems and a stable `extern "C"` API surface for FFI.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Directory Structure](#directory-structure)
3. [Key Subsystems](#key-subsystems)
4. [FFI Bindings](#ffi-bindings)
5. [C Module Reference](#c-module-reference)
6. [External Dependencies](#external-dependencies)
7. [Configuration](#configuration)

---

## Architecture

LibPHX uses a three-layer model: **C engine → LuaJIT FFI bindings → game scripts**.

```
┌─────────────────────────────────────────────────────────────┐
│  Game scripts (script/)                                     │
│  App/, Game/, UI/, env/ — gameplay, entities, config        │
└───────────────────────────┬─────────────────────────────────┘
                            │ require('phx.phx') injects globals
┌───────────────────────────▼─────────────────────────────────┐
│  FFI layer (libphx/script/)                                 │
│  ffi/libphx.lua  — load DLL, shared typedefs                │
│  ffi/*.lua       — per-module cdef + metatypes              │
│  ffiext/*.lua    — Lua sugar via onDef_* hooks              │
└───────────────────────────┬─────────────────────────────────┘
                            │ LuaJIT FFI → PHX_API symbols
┌───────────────────────────▼─────────────────────────────────┐
│  C engine (libphx/src/, libphx/include/)                      │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│  Third-party: SDL3, OpenGL/GLAD, Bullet, LuaJIT, …        │
└─────────────────────────────────────────────────────────────┘
```

### Startup flow

1. **`lt64.exe`** calls `Engine_Init(2, 1)` (OpenGL 2.1 compatibility), creates Lua, sets globals, runs `./script/Main.lua`.
2. **`script/Main.lua`** extends `package.path`, loads env, then `require('phx.phx')`.
3. The selected app (`require('App.' .. app):run()`) drives the frame loop.

### Design conventions (C)

- **API export**: `PHX_API` (`extern "C" __declspec(dllexport)` on Windows) in `include/Common.h`.
- **Type taxonomy**:
  - **Opaque types** (`OPAQUE_T`): handles like `Mesh*`, `Window*` — hidden implementation.
  - **Transparent structs** (`STRUCT_T`): layout exposed to FFI (`Vec3f`, `Matrix`, `Ray`).
  - **Enums**: typedef'd integers (`BlendMode`, `ResourceType`, `Button`).
- **Error model**: `Fatal()` aborts; `Warn()` continues. `CHECK_LEVEL` (0–3) controls assertions.
- **Memory**: Internal `MemNew`/`MemFree`; exported `Memory_*` for host sharing.
- **Resources**: Typed path search lists resolve assets by logical name.

Engine APIs are **not** registered from C — the FFI layer binds everything.

---

## Directory Structure

```
libphx/
├── CMakeLists.txt          # Builds shared library `phx`
├── include/                # Public C headers (~129 files)
│   ├── Common.h            # Platform macros, types, CHECK_LEVEL
│   ├── PhxConfig.h         # Feature flags (GLCHECK, profiler, BSP)
│   └── Engine.h, Lua.h, Physics.h, ...
├── src/                    # C++ implementations (~113 .cpp files)
├── script/
│   ├── ffi/
│   │   ├── libphx.lua      # Core FFI bootstrap
│   │   └── *.lua           # ~100 per-module bindings
│   ├── ffiext/             # 21 Lua extension modules
│   └── build/
│       └── Shared.cmake    # Shared CMake helpers
└── ext/
    ├── glad/               # Vendored OpenGL loader
    └── include/            # stb, LuaJIT API headers, windirent
```

---

## Key Subsystems

### Engine & Platform

**Files:** `Engine.cpp`, `OS.cpp`, `PhxTime.cpp`, `TimeStamp.cpp`, `Timer.cpp`, `PhxSignal.cpp`, `Error.cpp`

- `Engine_Init`: SDL subsystems, OpenGL 2.1 context attributes, log directory, keyboard/mouse/input/resource init.
- `Engine_Update`: Per-frame poll — keyboard, mouse, joystick, gamepad, unified input.
- `Engine_GetTime`: Monotonic seconds since init.

### Window & OpenGL

**Files:** `Window.cpp`, `OpenGL.cpp`, `Viewport.cpp`, `ClipRect.cpp`

- SDL3 owns windows and GL contexts.
- `OpenGL_Init`: GLAD loader, default GL state, pushes default `RenderState`.
- Draw cycle: `Window_BeginDraw` → render → `Window_EndDraw` → swap.
- Uses **legacy OpenGL** (matrix stacks, immediate-mode in `Draw.cpp`, GLSL `#version 130`).

### Rendering

**Files:** `Draw.cpp`, `RenderState.cpp`, `RenderTarget.cpp`, `Shader.cpp`, `ShaderState.cpp`, `ShaderVar.cpp`, `GLMatrix.cpp`, `Metric.cpp`

| Component | Responsibility |
|-----------|----------------|
| `Draw` | Immediate-mode debug/UI drawing; alpha stack |
| `RenderState` | Stack-based blend, cull, depth, wireframe |
| `Shader` | Load/compile GLSL from resources; ref-counted cache |
| `ShaderState` | Bound shader + uniform values |
| `RenderTarget` | FBO render-to-texture |
| `Metric` | Draw-call / triangle counters |

### Meshes, Textures & Spatial

**Mesh:** `Mesh.cpp`, `Mesh_FromObj.cpp`, `Mesh_ComputeAO.cpp`, `LodMesh.cpp`, `BoxMesh.cpp`

- Ref-counted VBO/IBO, lazy GPU upload, OBJ/binary load, SDF conversion, AO.

**Textures:** `Tex1D/2D/3D/Cube.cpp`, `Tex2D_Load.cpp` (stb_image), `TexCube_GenIRMap.cpp`

**Spatial structures:**

| Module | Purpose |
|--------|---------|
| `BSP.cpp` | Binary space partition for ray/sphere queries |
| `Octree.cpp` | Octree spatial index |
| `KDTree.cpp` | KD-tree |
| `BoxTree.cpp` | AABB tree |
| `SDF.cpp` | Signed distance field utilities |
| `Intersect.cpp` | Ray/triangle, sphere tests |

### Physics

**Files:** `Physics.cpp`, `RigidBody.cpp`, `CollisionShape.cpp`, `Trigger.cpp`

- Wraps **Bullet Physics**: discrete dynamics world, DBVT broadphase.
- RigidBody: simple, compound, collision groups/masks, ghost triggers.
- Queries: ray cast, sphere/box cast, overlaps.
- Default gravity `(0,0,0)` — space sim.

### Audio

**Files:** `Audio.cpp`, `Sound.cpp`, `SoundDesc.cpp`, `Midi.cpp`

- **FMOD** backend: 1024 channels, 3D right-handed.
- Listener position/velocity/orientation; streaming from resources.
- `Midi.cpp`: MIDI device enumeration.

### Input

**Files:** `Input.cpp`, `InputEvent.cpp`, `InputBindings.cpp`, `Keyboard.cpp`, `Mouse.cpp`, `Gamepad.cpp`, `Joystick.cpp`

- Unified **device model**: `(DeviceType, deviceId)` with edge detection.
- SDL events → `InputEvent` queue each frame.
- Legacy per-device APIs still updated but deprecated in favor of `Input`.

### Resource Loading

**Files:** `Resource.cpp`, `File.cpp`, `Directory.cpp`, `Bytes.cpp`

| ResourceType | Example paths |
|--------------|---------------|
| Script | `./res/script/%s.lua` |
| Shader | `./res/shader/%s.glsl` |
| Tex2D | `./res/tex2d/%s.png`, `.jpg` |
| Mesh | `./res/mesh/%s.obj`, `.bin` |
| Sound | `./res/sound/%s.ogg`, `.wav`, `.mp3` |
| Font | `./res/font/%s.ttf`, `.otf` |

- `Resource_GetPath` — resolve or Fatal.
- `Resource_AddPath` — extend search paths at runtime.

### UI (Engine)

**Files:** `Font.cpp`, `ImGui.cpp`, `HmGui.cpp`, `UIRenderer.cpp`

- **Font**: FreeType rasterization.
- **ImGui**: Custom immediate-mode GUI (not Dear ImGui).
- **HmGui**: Higher-level hierarchical layout GUI.

### Lua Integration

**Files:** `Lua.cpp`, `LuaScheduler.cpp`

| API | Purpose |
|-----|---------|
| `Lua_Create` / `Lua_Free` | State lifecycle |
| `Lua_DoFile` / `Lua_LoadFile` | Load via resource paths |
| `Lua_Call` | Protected call |
| Scheduler | Global timed callback queue |

---

## FFI Bindings

### `script/ffi/libphx.lua`

1. `ffi.cdef` for shared typedefs, opaque placeholders, transparent struct layouts.
2. Loads DLL: `ffi.load('libphx' .. arch .. debug)`.
3. Exposes `libphx.lib` and metadata lists `Opaques`, `Structs`.

### Per-module FFI files (`script/ffi/*.lua`)

Each module follows a consistent pattern:

```lua
-- 1. ffi.cdef for this module's functions
-- 2. Global table: Physics = { Create = libphx.Physics_Create, ... }
-- 3. Optional onDef_Physics hook from ffiext
-- 4. Metatype Physics_t with instance methods
```

- Module table: `Physics`, `Mesh` (PascalCase).
- Metatype: `Physics_t`, `Vec3f_t`.
- Instance methods: camelCase (`addRigidBody`, `beginDraw`).
- Opaque lifetime: `.managed()` wraps with `ffi.gc(self, libphx.X_Free)`.

### Extensions (`script/ffiext/*.lua`)

Loaded before FFI modules. Register hooks:

| Hook | When called |
|------|-------------|
| `onDef_Physics` | After module table built |
| `onDef_Physics_t` | Before `ffi.metatype` applied |
| `onDef_Vec3f_t` | Adds operators, `normalize`, `lerp` |

21 modules: `BSP`, `Box3`, `Directory`, `File`, `Font`, `Input`, `Math`, `Matrix`, `Mesh`, `Physics`, `Profiler`, `Quat`, `Ray`, `RNG`, `Tex2D`, `Tex3D`, `Vec2`, `Vec3`, `Vec4`, `Viewport`, `Window`.

### Binding into the game (`script/phx/phx.lua`)

```lua
PHX.Ext  = requireAll('ffiext')
PHX.Lib  = require('ffi.libphx')
PHX.FFI  = requireAll('ffi')
Namespace.Inject(PHX, 'PHX', PHX.FFI, 'PHX.FFI')
-- Also injects Mesh, Physics, Window, etc. into _G
```

---

## C Module Reference

113 source files grouped by responsibility:

### Core & Diagnostics (11)
`Engine`, `OS`, `Error`, `Common`, `PhxTime`, `TimeStamp`, `Timer`, `PhxSignal`, `Metric`, `Profiler`, `State`

### Memory & Containers (11)
`PhxMemory`, `MemPool`, `MemStack`, `Bytes`, `Hash`, `HashMap`, `HashGrid`, `StrBuffer`, `StrMap`, `Bit`, `GUID`, `RNG`

### Math & Geometry (10)
`PhxMath`, `Matrix`, `Quat`, `Plane`, `Ray`, `Triangle`, `Polygon`, `LineSegment`, `Intersect`, `GLMatrix`

### Files & Resources (5)
`File`, `Directory`, `Resource`, `ResourceType`, `DataFormat`

### Lua (2)
`Lua`, `LuaScheduler`

### Window & GL (8)
`Window`, `WindowMode`, `WindowPos`, `OpenGL`, `Viewport`, `ClipRect`, `GLMatrix`, `VR`

### Rendering (11)
`Draw`, `RenderState`, `RenderTarget`, `Shader`, `ShaderState`, `ShaderVar`, `ShaderVarType`, `BlendMode`, `CullFace`, `DepthTest`, `PixelFormat`

### Meshes (6)
`Mesh`, `Mesh_FromObj`, `Mesh_ComputeAO`, `LodMesh`, `BoxMesh`, `Meshes`

### Spatial & SDF (5)
`BSP`, `Octree`, `KDTree`, `BoxTree`, `SDF`

### Textures (9)
`Tex1D`, `Tex2D`, `Tex2D_Load`, `Tex2D_Save`, `Tex3D`, `TexCube`, `TexCube_GenIRMap`, `TexFilter`, `TexFormat`, `TexWrapMode`, `CubeFace`

### Physics (4)
`Physics`, `RigidBody`, `CollisionShape`, `Trigger`

### Input (15)
`Input`, `InputEvent`, `InputBindings`, `Keyboard`, `Mouse`, `Gamepad`, `Joystick`, `Key`, `Button`, `Device`, ...

### Audio (4)
`Audio`, `Sound`, `SoundDesc`, `Midi`

### UI (4)
`Font`, `ImGui`, `HmGui`, `UIRenderer`

### Networking & Concurrency (3)
`Socket`, `Thread`, `ThreadPool`

---

## External Dependencies

| Dependency | Purpose |
|------------|---------|
| **LuaJIT 5.1** | Script VM |
| **SDL2** | Window, GL context, input |
| **GLEW + OpenGL** | Extension loading; rendering |
| **Bullet** | Physics |
| **FMOD + FMOD Studio** | 3D audio |
| **FreeType** | Font rasterization |
| **LZ4** | Compression |
| **stb** | PNG/JPG loading (header-only) |

See [build-and-maintenance.md](build-and-maintenance.md) for versions and linking details.

Default build and run:

```bash
cmake -S . -B build -A x64
cmake --build build --config RelWithDebInfo
cmake --build build --target run --config RelWithDebInfo
```

---

## Configuration

### `include/PhxConfig.h`

| Flag | Default | Effect |
|------|---------|--------|
| `ENABLE_GLCHECK` | 0 | Wrap GL calls with error check |
| `ENABLE_PROFILER` | 1 | Frame profiler scopes |
| `ENABLE_PROFILER_TRACE` | 0 | Chrome tracing output |
| `ENABLE_BSP_PROFILING` | 0 | BSP profiling |

### Lua globals set by host

| Global | Meaning |
|--------|---------|
| `__debug__` | Selects `libphx64d` vs `libphx64` |
| `__embedded__` | Embedded mode flag |
| `__checklevel__` | Mirrors C `CHECK_LEVEL` |
| `__app__` | App name under `script/App/` |
