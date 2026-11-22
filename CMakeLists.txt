cmake_minimum_required(VERSION 3.16)

# Nix provides the pinned Meshtastic source tree, including nested sources.
if(NOT DEFINED ENV{MESHTASTIC_FW_ROOT} OR "$ENV{MESHTASTIC_FW_ROOT}" STREQUAL "")
  message(FATAL_ERROR "Enter the Nix shell first; MESHTASTIC_FW_ROOT is set by flake.nix")
endif()
get_filename_component(FW_ROOT "$ENV{MESHTASTIC_FW_ROOT}" REALPATH)
if(NOT EXISTS "${FW_ROOT}/version.properties")
  message(FATAL_ERROR "MESHTASTIC_FW_ROOT does not point to a Meshtastic firmware checkout: ${FW_ROOT}")
endif()
if(NOT DEFINED ENV{MESHTASTIC_VENDOR_ROOT} OR "$ENV{MESHTASTIC_VENDOR_ROOT}" STREQUAL "")
  message(FATAL_ERROR "Enter the Nix shell first; MESHTASTIC_VENDOR_ROOT is set by flake.nix")
endif()
get_filename_component(VENDOR_ROOT "$ENV{MESHTASTIC_VENDOR_ROOT}" REALPATH)
if(NOT EXISTS "${VENDOR_ROOT}/lvgl/idf_component.yml")
  message(FATAL_ERROR "MESHTASTIC_VENDOR_ROOT does not contain the pinned source set: ${VENDOR_ROOT}")
endif()
find_package(Python3 REQUIRED COMPONENTS Interpreter)

execute_process(
  COMMAND "${Python3_EXECUTABLE}" "${FW_ROOT}/bin/buildinfo.py" long
  WORKING_DIRECTORY "${FW_ROOT}"
  OUTPUT_VARIABLE FW_VERSION_LONG
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE FW_VERSION_RESULT
)
execute_process(
  COMMAND "${Python3_EXECUTABLE}" "${FW_ROOT}/bin/buildinfo.py" short
  WORKING_DIRECTORY "${FW_ROOT}"
  OUTPUT_VARIABLE FW_VERSION_SHORT
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE FW_VERSION_SHORT_RESULT
)
if(NOT FW_VERSION_RESULT EQUAL 0 OR NOT FW_VERSION_SHORT_RESULT EQUAL 0)
  message(FATAL_ERROR "Could not read firmware version from version.properties")
endif()

set(GENERATED_CONFIG_DIR "${CMAKE_BINARY_DIR}/generated")
set(USERPREFS_HEADER "${GENERATED_CONFIG_DIR}/userprefs_build.h")
set(USERPREFS_FILE "${CMAKE_CURRENT_LIST_DIR}/userPrefs.local.jsonc")
if(NOT EXISTS "${USERPREFS_FILE}")
  set(USERPREFS_FILE "${FW_ROOT}/userPrefs.jsonc")
endif()
execute_process(
  COMMAND "${Python3_EXECUTABLE}"
    "${CMAKE_CURRENT_LIST_DIR}/scripts/build_userprefs.py"
    "${USERPREFS_FILE}" "${USERPREFS_HEADER}"
  RESULT_VARIABLE USERPREFS_RESULT
)
if(NOT USERPREFS_RESULT EQUAL 0)
  message(FATAL_ERROR "Could not generate userprefs_build.h from userPrefs.jsonc")
endif()

# Reconfigure when the Nix dependency graph, locked inputs, overlays, or
# device-local preferences change. ESP-IDF otherwise keeps using paths from
# CMake configure when entering a shell with changed Nix inputs.
file(GLOB _nix_patch_inputs CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_LIST_DIR}/patches/*.patch"
)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_LIST_DIR}/flake.nix"
  "${CMAKE_CURRENT_LIST_DIR}/flake.lock"
  "${CMAKE_CURRENT_LIST_DIR}/registry-components.json"
  "${USERPREFS_FILE}"
  ${_nix_patch_inputs}
)

set(EXTRA_COMPONENT_DIRS
  "${CMAKE_CURRENT_LIST_DIR}/components"
  "${VENDOR_ROOT}/lvgl"
)
set(PROJECT_VER "${FW_VERSION_SHORT}")
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(meshtastic_thinknode_m9_tft)

# CMake's ESP-IDF component requirement pass runs component CMakeLists in
# script mode, where GLOB CONFIGURE_DEPENDS is unsupported. Watch the inputs
# here, in normal project mode, so adding/removing a source triggers reconfigure.
file(GLOB_RECURSE _firmware_source_watch CONFIGURE_DEPENDS
  "${FW_ROOT}/src/*.c" "${FW_ROOT}/src/*.cpp" "${FW_ROOT}/src/*.S"
  "${FW_ROOT}/variants/esp32s3/ELECROW-ThinkNode-M9/*.c"
  "${FW_ROOT}/variants/esp32s3/ELECROW-ThinkNode-M9/*.cpp"
  "${FW_ROOT}/src/platform/esp32/*.c" "${FW_ROOT}/src/platform/esp32/*.cpp"
  "${FW_ROOT}/src/platform/extra_variants/*.c"
  "${FW_ROOT}/src/platform/extra_variants/*.cpp"
  "${VENDOR_ROOT}/*.c"
  "${VENDOR_ROOT}/*.cpp"
  "${VENDOR_ROOT}/*.S"
)
