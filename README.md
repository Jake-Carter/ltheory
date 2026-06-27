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

This produces `bin/lt64.exe` and `bin/libphx64.dll`.

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
bin/lt64.exe                  # default app (LTheory)
bin/lt64.exe PhysicsTest      # a specific script/App/*.lua
```

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
