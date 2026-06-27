# jit Module

## Purpose

**Vendored LuaJIT toolkit** — bytecode dumps, disassemblers, profiler, and zone profiling. This is the standard LuaJIT `jit/` directory shipped with the runtime, not project-specific code.

## Files (20)

| File | Responsibility |
|------|----------------|
| `vmdef.lua` | VM definition tables |
| `bc.lua` | Bytecode utilities |
| `dump.lua`, `dump2.lua` | Bytecode dump output |
| `bcsave.lua` | Save bytecode to file |
| `dis_x86.lua`, `dis_x64.lua` | x86/x64 disassemblers |
| `dis_arm.lua`, `dis_arm64.lua`, `dis_arm64be.lua` | ARM disassemblers |
| `dis_mips.lua`, `dis_mips64.lua`, `dis_mips64el.lua` | MIPS disassemblers |
| `dis_ppc.lua` | PowerPC disassembler |
| `p.lua` | Profiler |
| `v.lua` | Verbose mode |
| `zone.lua` | Zone profiling |
| `loom.lua`, `loom.html` | Loom visualization |

## Usage in Project

Configured via `env/util/Config.lua` and invoked from `env/util/Jit.lua`:

| Config flag | Effect |
|-------------|--------|
| `Config.jit.profile` | Enable LuaJIT profiler |
| `Config.jit.profileInit` | Start profiling at init vs. after warmup |
| `Config.jit.dumpasm` | Dump assembly for compiled traces |
| `Config.jit.verbose` | Verbose JIT compiler output |

Toggled at Application startup in `phx/util/Application.lua`:

```lua
if Config.jit.profile and Config.jit.profileInit then Jit.StartProfile() end
if Config.jit.dumpasm then Jit.StartDump() end
if Config.jit.verbose then Jit.StartVerbose() end
```

JIT compiler tuning parameters are set in `Main.lua` from `Config.jit.tune.*` (maxtrace, hotloop, unroll settings, etc.).

## Dependencies

- Used by **env** only (`Jit.lua` wrapper)
- Not directly imported by game code

## Notes

These files are upstream LuaJIT tooling. Modifying them is generally not recommended — they may be overwritten when updating the LuaJIT dependency in `libphx/ext/`.
