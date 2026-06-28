# Build and Maintenance

Limit Theory is a Lua-driven game built on **LibPHX**, a C shared library exposed to **LuaJIT** via FFI. The repo root CMake project builds the `lt` executable; engine code lives in the `libphx` directory (git submodule).

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Git](https://git-scm.com/downloads) | Clone + submodule |
| [Git LFS](https://git-lfs.github.com/) | Large binary assets |
| [CMake](https://cmake.org/download/) ≥ 3.21 | Generate build files |
| Visual Studio Community | MSVC compiler / IDE (Windows) |

Clone with submodules (LibPHX engine code lives in `libphx/`):

```bash
git lfs install
git clone --recursive https://github.com/JoshParnell/ltheory.git ltheory
cd ltheory
```

Third-party native libraries (SDL3, Bullet, FreeType, etc.) are **built from source** on first configure via CMake FetchContent. You do not need prebuilt binaries in `libphx/ext/lib/` for Windows x64.

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
- Includes `libphx/cmake/Dependencies.cmake` — FetchContent / ExternalProject for third-party deps.
- Include paths: fetched Bullet, FreeType, and LZ4 headers; `include/`; vendored `ext/include/` (stb, LuaJIT API, windirent); minimp3.
- Links SDL3, FreeType, LZ4, Bullet, GLAD, LuaJIT (`lua51.dll`), and builds `lfs.dll`.
- On Windows: copies `SDL3.dll`, `lua51.dll` next to `phx` / `lt` in `bin/` post-build.

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

Windows x64 builds pull and compile dependencies automatically (`libphx/cmake/Dependencies.cmake`). Pinned versions:

| Dependency | Pin | Role |
|------------|-----|------|
| **SDL3** | `release-3.2.8` | Window, input, events, WAV decode, audio output |
| **GLAD** | vendored in `libphx/ext/glad/` | OpenGL 2.1 compatibility loader |
| **FreeType** | `VER-2-13-3` | Font rasterization (static link) |
| **LZ4** | `v1.10.0` | Compression (static link) |
| **Bullet** | `3.25` | Physics (static link; headers from fetched `src/`) |
| **LuaJIT** | `v2.1.0-beta3` | Lua runtime (`lua51.dll`; MSVC build script) |
| **minimp3** | commit `7b590fd` | MP3 decode (header-only) |
| **LuaFileSystem** | `v1_8_0` | Native `lfs.dll` for script I/O |
| **OpenGL** | 2.1 compat | Requested via `Engine_Init(2, 1)` |

Audio uses the **SDL3 backend** (`PHX_AUDIO_SDL3=1`): WAV via `SDL_LoadWAV`, MP3 via minimp3.

`AudioTest` verifies playback without listening: it asserts `Audio.GetLastMixPeak()` exceeds a threshold while sounds play, and checks `Sound:getPlayPos()` advances. `Audio.Set3DSettings(doppler, minDistance, rolloff)` uses **minDistance** as full-volume range for 3D attenuation.

Vendored under `libphx/ext/`: **GLAD** (`ext/glad/`), **stb** image I/O, **LuaJIT** public headers (`ext/include/luajit/`), and **windirent** for Windows directory iteration. All other native deps are fetched at configure time into `build/_deps/`.

### Windows runtime DLLs in `bin/`

| File | Source |
|------|--------|
| `libphx64.dll` | Engine |
| `SDL3.dll` | SDL3 FetchContent |
| `lua51.dll` | LuaJIT ExternalProject |
| `lfs.dll` | LuaFileSystem target |
| `lt64.exe` | Game executable |

### Linux linking

Linux CMake paths exist but are less tested than Windows. SDL3 + static deps are linked similarly; verify `rpath` / shared library layout before relying on a Linux build.

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

**Not LFS-tracked** (verify after clone):

- Font files (`.ttf`, `.otf`) — `res/font/` should contain `Share.ttf` and others; some filenames may be placeholders if LFS was not used. The metrics overlay uses `Share`; UI fonts use `Share` / `Exo2Bold` via `Config.ui.font`.
- `.ogx` sounds are legacy FMOD bank paths; the SDL3 audio backend loads `.wav` and `.mp3` only.

Use `git clone --recursive` so the `libphx` submodule is present. First CMake configure downloads third-party sources into `build/_deps/`.

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

### Smoke-test apps

After building, from the repo root (pass `--frames N` for scripted auto-exit):

```bash
bin/lt64.exe InputTest              # window + input loop (default in Config.App.lua)
bin/lt64.exe AudioTest --frames 90   # SDL3 decode + 2D/3D playback; verifies mix peak programmatically
bin/lt64.exe PhysicsAttachTest --frames 60
bin/lt64.exe ProcGenTest --frames 120
bin/lt64.exe PhysicsTest --frames 120
bin/lt64.exe FontTest --frames 120
bin/lt64.exe LTheory --frames 300   # composition gate; validates generate + N update frames
bin/lt64.exe BSPTest                # interactive BSP debugger (test 5: sphere/triangle)
```

Recommended validation order: **InputTest → AudioTest → PhysicsAttachTest → ProcGenTest → PhysicsTest → LTheory**.

Default app in `script/Config.App.lua` is `InputTest`. Set `Config.app = 'LTheory'` or pass `LTheory` on the CLI for the full game.

`Config.run` flags used by smoke apps: `maxFrames` (from `--frames`), `minimalAttach` / `skipAttach` (PhysicsAttachTest), `procGenSeed` / `procGenBuildBSP` (ProcGenTest), `ltheorySeed` (fixed LTheory generate seed).

LTheory gate (`--frames N`): prints `gate ok` after generate (ship, station, planet, belt, escort, AI) and `passed` on clean exit.

### Vendored `ext/` layout

The FetchContent build does not use prebuilt binaries. `libphx/ext/` now contains only:

| Path | Contents |
|------|----------|
| `ext/glad/` | OpenGL 2.1 compatibility loader (generated) |
| `ext/include/stb/` | stb_image / stb_image_write |
| `ext/include/luajit/` | LuaJIT public API headers (runtime built via ExternalProject) |
| `ext/include/windirent.h` | POSIX `dirent` shim for MSVC |

`libphx/ext/lib/` and `libphx/ext/bin/` are gitignored; delete any local copies left over from the legacy static-deps workflow.

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
| `res/font/` | Font files (Share, NovaMono, Exo2Bold, OFL licenses) |
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

Apps in `script/App/`: `LTheory`, `PhysicsTest`, `PhysicsAttachTest`, `ProcGenTest`, `FontTest`, `AudioTest`, `InputTest`, `BSPTest`, `GenTex2D`, and others.

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

Dependency pins live in `libphx/cmake/Dependencies.cmake`. To upgrade:

1. Change the `GIT_TAG` (or minimp3 commit) in `Dependencies.cmake`.
2. Reconfigure: `cmake -S . -B build -A x64` (FetchContent re-downloads as needed).
3. Fix API drift in `libphx/src/` and `libphx/script/ffi/` if headers changed.
4. Run smoke apps: `InputTest`, `AudioTest`, then `LTheory`.

GLAD can be regenerated for OpenGL 2.1 compatibility:

```bash
python -m glad --api="gl:compatibility=2.1" --out-path=libphx/ext/glad c
```

The engine submodule is at https://github.com/JoshParnell/libphx.git — engine changes typically go there first, then the submodule pointer in ltheory is updated.
