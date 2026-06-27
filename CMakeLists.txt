cmake_minimum_required (VERSION 3.21)

# Allow FetchContent deps (Bullet 3.25) that declare older cmake_minimum_required.
if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.29")
  cmake_policy (SET CMP0156 NEW)
endif ()
if (CMAKE_VERSION VERSION_GREATER_EQUAL "4.0")
  set (CMAKE_POLICY_VERSION_MINIMUM 3.5)
endif ()

project (LTheory)
include (libphx/script/build/Shared.cmake)

# Default to RelWithDebInfo. Single-config generators use this directly; for
# multi-config generators (Visual Studio), cmake --build uses it when --config
# is omitted.
if (NOT CMAKE_BUILD_TYPE)
  set (CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type" FORCE)
endif ()
set_property (CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
  Debug Release RelWithDebInfo MinSizeRel)

if (CMAKE_CONFIGURATION_TYPES)
  message (STATUS "Multi-config generator: use --config RelWithDebInfo when building")
endif ()

add_subdirectory (libphx)

add_executable (lt "src/Main.cpp")
phx_configure_output_dir (lt)
phx_configure_target_properties (lt)
phx_configure_debug (lt)

target_link_libraries (lt phx)

# Debug builds use a 'd' suffix; all other configs share the same name so that
# libphx.lua (__debug__=false) loads libphx64, matching RelWithDebInfo/Release.
set_target_properties (lt PROPERTIES
  OUTPUT_NAME_DEBUG "lt${ARCH}d"
  OUTPUT_NAME_RELEASE "lt${ARCH}"
  OUTPUT_NAME_RELWITHDEBINFO "lt${ARCH}"
  OUTPUT_NAME_MINSIZEREL "lt${ARCH}")

add_custom_target (run
  COMMAND ${CMAKE_COMMAND} -E chdir "${CMAKE_SOURCE_DIR}" $<TARGET_FILE:lt>
  DEPENDS lt
  USES_TERMINAL
  COMMENT "Running Limit Theory (default app from Config.app)")
