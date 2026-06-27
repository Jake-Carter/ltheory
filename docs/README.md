# Limit Theory — Documentation

This directory contains architecture and maintenance documentation for the Limit Theory (ltheory) codebase — the second-generation C/Lua implementation of the cancelled open-world space simulation game.

## Documents

| Document | Description |
|----------|-------------|
| [design.md](design.md) | Top-level system design, architecture, and data flow |
| [build-and-maintenance.md](build-and-maintenance.md) | Build pipeline, dependencies, platform support, known issues |
| [libphx.md](libphx.md) | LibPHX engine: C subsystems, FFI bindings, module reference |
| [script/README.md](script/README.md) | Game script layer overview and bootstrap flow |
| [script/App.md](script/App.md) | Runnable application entry points |
| [script/env.md](script/env.md) | Lua runtime foundation (class system, utilities) |
| [script/phx.md](script/phx.md) | Engine Lua binding layer and Application framework |
| [script/Game.md](script/Game.md) | Core gameplay: entities, components, AI, controls |
| [script/Gen.md](script/Gen.md) | Procedural content generation |
| [script/UI.md](script/UI.md) | Custom immediate-mode UI toolkit |
| [script/Util.md](script/Util.md) | Shared camera and tracking utilities |
| [script/jit.md](script/jit.md) | Vendored LuaJIT tooling |
| [script/WIP.md](script/WIP.md) | Experimental / in-progress code |

## Quick Start

```bash
cmake -S . -B build -A x64
cmake --build build --config RelWithDebInfo
cmake --build build --target run --config RelWithDebInfo
```

If the app fails to load the engine DLL, see [Build Issues](build-and-maintenance.md#known-build-issues) — usually a Debug/RelWithDebInfo mismatch or stale binaries in `bin/`.
