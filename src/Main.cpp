#include "Directory.h"
#include "Engine.h"
#include "File.h"
#include "Lua.h"
#include "PhxString.h"

#include <cstdlib>
#include <cstring>

#if WINDOWS
extern "C" {
  __declspec(dllexport) unsigned long NvOptimusEnablement = 0x00000001;
  __declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;
}
#endif

int main (int argc, char* argv[]) {
  Engine_Init(2, 1);
  Lua* lua = Lua_Create();
  char const* entryPoint = "./script/Main.lua";

  if (!File_Exists(entryPoint))
  {
    Directory_Change("../");
    if (!File_Exists(entryPoint))
      Fatal("can't find script entrypoint <%s>", entryPoint);
  }

  Lua_SetBool(lua, "__debug__", DEBUG > 0);
  Lua_SetBool(lua, "__embedded__", true);
  Lua_SetNumber(lua, "__checklevel__", CHECK_LEVEL);

  bool appSet = false;
  for (int i = 1; i < argc; ++i) {
    if (strcmp(argv[i], "--frames") == 0) {
      if (i + 1 >= argc)
        Fatal("missing value for --frames");
      Lua_SetNumber(lua, "__max_frames__", (double) atoi(argv[i + 1]));
      ++i;
    } else {
      if (appSet)
        Fatal("unexpected argument: %s", argv[i]);
      Lua_SetStr(lua, "__app__", argv[i]);
      appSet = true;
    }
  }

  Lua_DoFile(lua, "./script/Main.lua");
  Lua_Free(lua);
  Engine_Free();
  return 0;
}
