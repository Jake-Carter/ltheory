# Limit Theory

Limit Theory is a now-cancelled open world space simulation game.

This repository is the game (not engine) code for the second generation of LT's development, when all work was migrated to C and Lua. For the older, C++/LTSL Limit Theory, see https://github.com/JoshParnell/ltheory-old.

![LT Screenshot](./res/tex2d/screenshot.png)

# Prerequisites

To build Limit Theory, you'll need a few standard developer tools. All of them are available to download for free.

- Git: https://git-scm.com/downloads
- Git LFS: https://git-lfs.github.com/
- Visual Studio Community: https://visualstudio.microsoft.com/vs/ (with "Desktop development with C++")
- CMake 3.21+: https://cmake.org/download/

# Building

## Checking out the Repository

Before doing any other `git` commands, make sure LFS is installed:

```bash
git lfs install
```

**Important**: if you forget to install and initialize Git LFS, most of the resources will probably be broken. Make sure you do the above step!

Clone with submodules (LibPHX engine):

```bash
git clone --recursive https://github.com/JoshParnell/ltheory.git ltheory
cd ltheory
```

## Compiling

From the repository root:

```bash
cmake -S . -B build -A x64
cmake --build build --config RelWithDebInfo
```

This produces `bin/lt64.exe`, `bin/libphx64.dll`, `bin/SDL3.dll`, `bin/lua51.dll`, and `bin/lfs.dll`. First configure downloads and builds third-party libraries (SDL3, Bullet, FreeType, etc.) via CMake FetchContent — allow a few minutes and network access.

Visual Studio is a multi-config generator, so pass `--config RelWithDebInfo` when building. If you open `build/LTheory.sln` in the IDE instead, select the **RelWithDebInfo** configuration there.

### Debug build

```bash
cmake --build build --config Debug
```

Debug output is `bin/lt64d.exe` and `bin/libphx64d.dll`.

### Ninja (optional)

From a Visual Studio developer shell:

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build
```

Ninja is single-config, so `--config` is not needed.

### Clean rebuild

```bash
rm -rf build bin
cmake -S . -B build -A x64
cmake --build build --config RelWithDebInfo
```

## Running

The main executable launches a Lua script. Gameplay lives entirely in `script/`; the C++ layer is just the engine host.

```bash
cmake --build build --target run --config RelWithDebInfo
```

Or run directly:

```bash
bin/lt64.exe                  # default app (InputTest; see Config.App.lua)
bin/lt64.exe InputTest        # input / window smoke test
bin/lt64.exe AudioTest --frames 90  # SDL3 audio; verifies mix peak programmatically
bin/lt64.exe PhysicsAttachTest --frames 60
bin/lt64.exe PhysicsTest --frames 120
bin/lt64.exe FontTest --frames 120
bin/lt64.exe ProcGenTest --frames 120
bin/lt64.exe LTheory --frames 300  # composition gate (escorts, AI, planet, belt)
```

Smoke apps auto-exit when given `--frames N`, or use built-in frame limits where noted in each app. Recommended order: InputTest → AudioTest → PhysicsAttachTest → ProcGenTest → PhysicsTest → LTheory.

All top-level apps are in `script/App/`.

# Example of the Entire Process

```bash
git lfs install
git clone --recursive https://github.com/JoshParnell/ltheory.git ltheory
cd ltheory
cmake -S . -B build -A x64
cmake --build build --config RelWithDebInfo
cmake --build build --target run --config RelWithDebInfo
```

For more detail on the build system, output naming, and dependencies, see [docs/build-and-maintenance.md](docs/build-and-maintenance.md).
