# Build and Maintenance

Limit Theory is a Lua-driven game built on **LibPHX**, a C shared library exposed to **LuaJIT** via FFI. The repo root CMake project builds the `lt` executable; engine code lives in the `libphx` directory (git submodule).

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Git](https://git-scm.com/downloads) | Clone + submodule |
| [Git LFS](https://git-lfs.github.com/) | Large binary assets |
| [CMake](https://cmake.org/download/) ≥ 3.21 | Generate build files |
| Visual Studio Community | MSVC compiler / IDE (Windows) |

Clone with submodules (LibPHX ships prebuilt libs in `libphx/ext/`):

```bash
git lfs install
git clone --recursive https://github.com/JoshParnell/ltheory.git ltheory
cd ltheory
```

---

## Build Pipeline

### Overview

```
cmake -S . -B build -A x64          →  configure into build/
cmake --build build --config RelWithDebInfo
cmake --build build --target run --config RelWithDebInfo
```

All artifacts land in `bin/` at the **repository root** (not `build/`).

Visual Studio is a multi-config generator: always pass `--config RelWithDebInfo` (or `Debug`) when building from the command line. Single-config generators (Ninja, Makefiles) use `CMAKE_BUILD_TYPE` instead and omit `--config`.

### Standard commands

```bash
# Configure and build (Windows, x64)
cmake -S . -B build -A x64
cmake --build build --config RelWithDebInfo

# Debug build
cmake --build build --config Debug

# Run
cmake --build build --target run --config RelWithDebInfo

# Clean rebuild
rm -rf build bin
cmake -S . -B build -A x64
cmake --build build --config RelWithDebInfo
```

On Linux:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build
```

Optional Ninja build (from a Visual Studio developer shell):

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build
```

You can also open `build/LTheory.sln` in Visual Studio. Use the **RelWithDebInfo** configuration for normal development.

### CMake Structure

**Root `CMakeLists.txt`:**

- Includes shared LibPHX build logic from `libphx/script/build/Shared.cmake`.
- Builds `lt` from `src/Main.cpp`, links against `phx`.
- Sets `DEBUG=1` for Debug builds, `DEBUG=0` otherwise via `phx_configure_debug()` (drives Lua `__debug__`).
- Defines a `run` custom target.
- Defaults single-config generators to RelWithDebInfo.

**`libphx/CMakeLists.txt`:**

- Builds shared library `phx` from all `libphx/src/*.cpp`.
- Include paths: `include/`, `ext/include/`, `ext/include/bullet/`.
- Links against prebuilt binaries in `ext/lib/${PLATARCH}/`.
- On Windows: imports DLLs and **copies them to `bin/`** post-build.

**`libphx/script/build/Shared.cmake`:**

| Condition | `PLATFORM` | `PLATARCH` |
|-----------|------------|------------|
| `WIN32` | `win` | `win64`, `win32` |
| `UNIX AND NOT APPLE` | `linux` | `linux64`, `linux32` |
| Other | — | Fatal error |

Architecture from `CMAKE_SIZEOF_VOID_P`: `32` or `64`.

Compiler flags:

| Platform | Notable flags |
|----------|---------------|
| Windows | `/MD`, `/MP`, `/EHs-c-`, `/GR-`, `/GL`, `/fp:fast`, `/arch:SSE2` |
| Linux | `-Wall`, `-fno-exceptions`, `-ffast-math`, `-fpic`, `-O3`, SSE2–SSE4, `-std=c++11` |

---

## Output Naming Convention

Pattern: `{prefix}{ARCH}{suffix}` where `ARCH` is `32` or `64`.

### Executables (`lt`)

| CMake configuration | Output name (64-bit) |
|---------------------|----------------------|
| Debug | `lt64d.exe` |
| Release | `lt64.exe` |
| **RelWithDebInfo** | **`lt64.exe`** ← default |
| MinSizeRel | `lt64.exe` |

### Engine library (`phx`)

Windows adds `lib` prefix to the DLL:

| Configuration | Output (64-bit) |
|---------------|-----------------|
| Debug | `libphx64d.dll` |
| Release | `libphx64.dll` |
| **RelWithDebInfo** | **`libphx64.dll`** ← default |
| MinSizeRel | `libphx64.dll` |

Only Debug uses a suffix. Release, RelWithDebInfo, and MinSizeRel share the same name so `libphx.lua` can load `libphx64` whenever `__debug__` is false.

### Relation to `__debug__` and FFI Loading

**C side** (`src/Main.cpp`):

```cpp
Lua_SetBool(lua, "__debug__", DEBUG > 0);
```

`DEBUG` is set per configuration by `phx_configure_debug()` in `Shared.cmake`:

- Debug → `DEBUG=1` → `__debug__=true` → loads `libphx64d`
- All other configs → `DEBUG=0` → `__debug__=false` → loads `libphx64`

**Lua FFI loader** (`libphx/script/ffi/libphx.lua`):

```lua
local debug = __debug__ and 'd' or ''
local path = string.format('libphx%s%s', arch, debug)
libphx.lib = ffi.load(path, false)
```

| `__debug__` | Library loaded (64-bit) |
|-------------|-------------------------|
| `true` | `libphx64d` |
| `false` | `libphx64` |

**Separate from game debug UI:** `Config.debug` in `script/Config.App.lua` controls metrics, debug window, physics wireframes. It does **not** control FFI library selection.

---

## External Dependencies

Headers and prebuilt libs live under `libphx/ext/`:

```
libphx/ext/
  include/     # Headers (SDL, GL/GLEW, bullet, fmod, freetype, luajit, lz4, stb)
  lib/
    win64/     # .lib + .dll (Windows x64)
    win32/     # 32-bit Windows
    linux64/   # Shared objects for Linux (when present)
```

### Versions (from headers in `ext/include/`)

| Dependency | Version | Notes |
|------------|---------|-------|
| **SDL2** | 2.0.14 | Strict runtime version check in `Engine_Init` |
| **GLEW** | 2.0.0 | OpenGL extension loading |
| **OpenGL** | 2.1 | Requested via `Engine_Init(2, 1)` |
| **Bullet** | 2.87 | Static link on Windows |
| **FMOD Studio** | 1.10.01 | `fmodL64.dll`, `fmodstudioL64.dll` |
| **LuaJIT** | 2.1.0-beta3 | Shipped as `lua51.dll` (Lua 5.1 API) |
| **FreeType** | 2.8.0 | Static `.lib` on Windows |
| **LZ4** | 1.7.5 | DLL on Windows |

### Windows linking

| Library | Link | Runtime copy to `bin/` |
|---------|------|------------------------|
| GLEW | `glew32.lib` → `glew32.dll` | Yes |
| SDL2 | `SDL2.lib` → `SDL2.dll` | Yes |
| LuaJIT | `lua51.lib` → `lua51.dll` | Yes |
| LZ4 | `liblz4.lib` → `liblz4.dll` | Yes |
| FMOD | `fmodL64_vc.lib`, `fmodstudioL64_vc.lib` | Yes |
| FreeType | `freetype.lib` | Static |
| Bullet | `BulletCollision`, `BulletDynamics`, `LinearMath` | Static |
| OpenGL | `opengl32.lib` | System |

### Linux linking

Links against system-style names: `GL`, `GLEW`, `SDL2`, `luajit-5.1`, `lz4`, `fmod`, `fmodstudio`, `freetype`, `BulletCollision`, `BulletDynamics`. Sets `-Wl,-rpath,../ext/lib/${PLATARCH}`. The Windows-style `add_extlib` / DLL-copy block is marked `# TODO`.

---

## Platform Support

| Platform | Status |
|----------|--------|
| **Windows** (32/64) | Primary, fully wired in CMake |
| **Linux** (32/64) | CMake paths exist; ext-lib import incomplete |
| **macOS** | Explicitly unsupported |

Primary development platform is **Windows** with Visual Studio or Ninja.

---

## Git LFS Requirements

Root `.gitattributes` tracks via LFS:

```
*.jpg  *.png  *.obj  *.bin  *.ogx
*.mp3  *.wav
```

**Before clone/pull:** run `git lfs install`.

**Not LFS-tracked** (may be missing from a bare checkout):

- Font files (`.ttf`, `.otf`) — `res/font/` may only contain license text; game code references `Share`, `Exo2Bold`, `NovaMono` via `Cache.Font`.
- Prebuilt native libs in `libphx/ext/lib/` come from the **libphx submodule**.

Use `git clone --recursive` so `libphx` and its `ext/` tree are populated.

---

## Known Build Issues

### Stale binaries in `bin/`

Switching between Debug and RelWithDebInfo can leave old DLLs in `bin/`. If the app fails to start or loads the wrong library, do a clean rebuild:

```bash
rm -rf build bin
cmake -S . -B build -A x64
cmake --build build --config RelWithDebInfo
```

### Visual Studio configuration

If you build from the IDE, select **RelWithDebInfo** for normal use. Debug builds produce `lt64d.exe` / `libphx64d.dll` and require running that executable (or `cmake --build build --config Debug` followed by `cmake --build build --target run --config Debug`).

Debug and RelWithDebInfo builds are now aligned: Debug sets `DEBUG=1` so Lua loads `libphx64d` matching the Debug DLL name.

### Other gaps

- `CHECK_LEVEL` is never set from CMake; engine assertions stay at level 0.
- Linux ext-lib packaging is incomplete.
- Font assets may be absent from a bare checkout.

---

## `res/` Folder Structure

Runtime assets resolve through `Resource_Init()` using `./res/…` paths.

| Directory | Contents |
|-----------|----------|
| `res/shader/` | GLSL vertex/fragment shaders and `include/` shared code |
| `res/tex2d/` | 2D textures (`.jpg`, `.png`) |
| `res/texcube/` | Cube maps |
| `res/sound/` | Audio (`.mp3`, `.wav`, `.ogx`) |
| `res/mesh/` | Geometry (`.obj`, `.bin`) |
| `res/font/` | Font files (may be missing) |
| `res/grammar/` | Procedural text grammars (`.txt`) |
| `res/gen/` | Generation helper scripts |
| `res/` (root) | `gamecontrollerdb_205.txt` (SDL gamepad mappings) |

### Shader organization

```
res/shader/
  vertex/       # VS entry points
  fragment/     # FS by category: brush/, compute/, effect/, filter/,
                #   gen/, light/, material/, sdf/, ui/, uvbake/
  include/      # Shared GLSL (#include from shaders)
```

Shaders are referenced by logical name, e.g. `Cache.Shader('wvp', 'material/metal')`.

---

## Running the Application

### Working directory

`Main.cpp` loads `./script/Main.lua`. If not found, it `chdir`s to `../` (supports launching from `bin/`). After this, CWD is the **repository root** and assets load from `./res/…`.

### Launch methods

```bash
# CMake run target
cmake --build build --target run --config RelWithDebInfo

# Direct
bin/lt64.exe
bin/lt64.exe LTheory
bin/lt64.exe PhysicsTest
```

### Script bootstrap

1. `script/Main.lua` — sets Lua `package.path`, loads env + phx, launches app.
2. `script/Config.App.lua` — default app name, debug, generation, render, UI settings.
3. `__app__` — from CLI arg or `Config.app` (default `'LTheory'`).

Apps in `script/App/`: `LTheory`, `PhysicsTest`, `BSPTest`, `FMODTest`, `InputTest`, `GenTex2D`, `TestEcon`, `TestHmGui`, `TestImGui`, `TestIcon`, `TestStrMap`, `CoordTest`, `Todo`.

### DLL search path (Windows)

External DLLs and `libphx64.dll` are copied into `bin/` at build time. Running `bin/lt64.exe` does not require PATH changes.

### Logs

`Engine_Init` creates a `log/` directory at the repository root.

---

## Quick Reference

```bash
git lfs install
git clone --recursive https://github.com/JoshParnell/ltheory.git ltheory
cd ltheory
cmake -S . -B build -A x64
cmake --build build
cmake --build build --target run
```

| Artifact | RelWithDebInfo (supported path) |
|----------|--------------------------------|
| Game exe | `bin/lt64.exe` |
| Engine DLL | `bin/libphx64.dll` |
| FFI name when `__debug__==false` | `libphx64` |
| Entry script | `script/Main.lua` |
| Default app | `script/App/LTheory.lua` |
| Assets | `res/` |

## Maintaining Dependencies

LibPHX vendors prebuilt binaries in `libphx/ext/lib/`. To upgrade a dependency:

1. Replace headers in `libphx/ext/include/`
2. Replace `.lib`/`.dll` (Windows) or `.so` (Linux) in `libphx/ext/lib/${PLATARCH}/`
3. Update any API changes in corresponding `libphx/src/` and `libphx/script/ffi/` files
4. Rebuild and run test apps (`PhysicsTest`, `FMODTest`, etc.) to validate

The engine submodule is at https://github.com/JoshParnell/libphx.git — engine changes typically go there first, then the submodule pointer in ltheory is updated.
