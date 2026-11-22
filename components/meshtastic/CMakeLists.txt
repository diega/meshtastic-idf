# Firmware component entry point. Source registration and dependency wrappers
# are kept local to this standalone target; see README.md for migration status.
get_filename_component(FW_ROOT "$ENV{MESHTASTIC_FW_ROOT}" REALPATH)
get_filename_component(VENDOR_ROOT "$ENV{MESHTASTIC_VENDOR_ROOT}" REALPATH)

file(GLOB_RECURSE APP_SOURCES
  "${FW_ROOT}/src/*.c"
  "${FW_ROOT}/src/*.cpp"
)

# Select platform-specific runtime code for ESP32 only; exclude native,
# RP2040, nRF, and STM32 implementations.
list(FILTER APP_SOURCES EXCLUDE REGEX "/src/platform/.*")
file(GLOB_RECURSE ESP32_SOURCES
  "${FW_ROOT}/src/platform/esp32/*.c"
  "${FW_ROOT}/src/platform/esp32/*.cpp"
  "${FW_ROOT}/src/platform/extra_variants/*.c"
  "${FW_ROOT}/src/platform/extra_variants/*.cpp"
)
list(APPEND APP_SOURCES ${ESP32_SOURCES})
file(GLOB_RECURSE BOARD_SOURCES
  "${FW_ROOT}/variants/esp32s3/ELECROW-ThinkNode-M9/*.c"
  "${FW_ROOT}/variants/esp32s3/ELECROW-ThinkNode-M9/*.cpp"
)
list(APPEND APP_SOURCES ${BOARD_SOURCES})

set(DEVICE_UI "${VENDOR_ROOT}/meshtastic-device-ui")
file(GLOB_RECURSE DEVICE_UI_SOURCES
  "${DEVICE_UI}/graphics/*.c"
  "${DEVICE_UI}/graphics/*.cpp"
  "${DEVICE_UI}/input/*.c"
  "${DEVICE_UI}/input/*.cpp"
  "${DEVICE_UI}/util/*.c"
  "${DEVICE_UI}/util/*.cpp"
  "${DEVICE_UI}/comms/*.c"
  "${DEVICE_UI}/comms/*.cpp"
  "${DEVICE_UI}/drivers/*.c"
  "${DEVICE_UI}/drivers/*.cpp"
  "${DEVICE_UI}/generated/ui_320x240/*.c"
  "${DEVICE_UI}/generated/ui_320x240/*.cpp"
  "${DEVICE_UI}/locale/*.c"
  "${DEVICE_UI}/locale/*.cpp"
)
list(APPEND APP_SOURCES ${DEVICE_UI_SOURCES})
list(FILTER APP_SOURCES EXCLUDE REGEX "/src/graphics/niche/|/src/graphics/eink/|/src/mesh/eth/|/src/mesh/raspihttp")
list(FILTER APP_SOURCES EXCLUDE REGEX "/meshtastic-device-ui/graphics/(OLED/|TFT/TFTView_(160x80|240x240|480x222|Debug)\\.cpp|driver/(FBDriver|X11Driver)\\.cpp)|/meshtastic-device-ui/graphics/map/(CURLService|LinuxFileSystemService)\\.cpp|/meshtastic-device-ui/comms/ethernet/|/meshtastic-device-ui/comms/serial/LinuxSerialClient\\.cpp|/meshtastic-device-ui/util/Linux")

set(VENDOR_LIBS "${VENDOR_ROOT}")
file(GLOB_RECURSE EXTERNAL_SOURCES
  "${VENDOR_LIBS}/ArduinoThread/*.cpp"
  "${VENDOR_LIBS}/Crypto/*.cpp"
  "${VENDOR_LIBS}/ESP8266 and ESP32 OLED driver for SSD1306 displays/src/*.cpp"
  "${VENDOR_LIBS}/TinyGPSPlus/src/*.cpp"
  "${VENDOR_LIBS}/RadioLib/src/*.cpp"
  "${VENDOR_LIBS}/NonBlockingRTTTL/src/*.cpp"
  "${VENDOR_LIBS}/OneButton/src/*.cpp"
  "${VENDOR_LIBS}/TBPubSubClient/src/*.cpp"
  "${VENDOR_LIBS}/ErriezCRC32/src/*.c"
  "${VENDOR_LIBS}/esp32_https_server/src/*.cpp"
  "${VENDOR_LIBS}/NTPClient/*.cpp"
  "${VENDOR_LIBS}/libpax/lib/libpax/*.c"
  "${VENDOR_LIBS}/libpax/lib/libpax/*.cpp"
  "${VENDOR_LIBS}/Fusion/Fusion/*.c"
  "${VENDOR_LIBS}/PNGdec/src/*.cpp"
  "${VENDOR_LIBS}/PNGdec/src/*.c"
  "${VENDOR_LIBS}/PNGdec/src/*.S"
  "${VENDOR_LIBS}/LovyanGFX/src/**/*.c"
  "${VENDOR_LIBS}/LovyanGFX/src/**/*.cpp"
)
file(GLOB FSM_SOURCES "${VENDOR_LIBS}/arduino-fsm/*.cpp")
list(APPEND EXTERNAL_SOURCES ${FSM_SOURCES})
list(APPEND EXTERNAL_SOURCES
  "${CMAKE_CURRENT_LIST_DIR}/../../managed_components/espressif__arduino-esp32/libraries/HTTPClient/src/HTTPClient.cpp"
)
list(APPEND APP_SOURCES ${EXTERNAL_SOURCES})

file(GLOB_RECURSE APP_HEADERS
  "${FW_ROOT}/src/*.h"
  "${FW_ROOT}/src/*.hpp"
)
set(APP_INCLUDE_DIRS "${FW_ROOT}/src" "${FW_ROOT}/variants/esp32s3/ELECROW-ThinkNode-M9")
foreach(APP_HEADER IN LISTS APP_HEADERS)
  get_filename_component(APP_HEADER_DIR "${APP_HEADER}" DIRECTORY)
  if(APP_HEADER_DIR MATCHES "/src/platform/")
    continue()
  endif()
  list(APPEND APP_INCLUDE_DIRS "${APP_HEADER_DIR}")
endforeach()
list(APPEND APP_INCLUDE_DIRS
  "${FW_ROOT}/src/mesh/generated"
  "${FW_ROOT}/src/platform/esp32"
  "${FW_ROOT}/src/platform/extra_variants"
  "${VENDOR_ROOT}/ArduinoThread"
  "${VENDOR_ROOT}/ESP8266 and ESP32 OLED driver for SSD1306 displays/src"
  "${VENDOR_ROOT}/LovyanGFX/src"
  "${VENDOR_ROOT}/lvgl/src"
  "${VENDOR_ROOT}/meshtastic-device-ui"
  "${VENDOR_ROOT}/meshtastic-device-ui/include"
  "${CMAKE_CURRENT_LIST_DIR}/../../managed_components/espressif__arduino-esp32/libraries/HTTPClient/src"
  "${CMAKE_CURRENT_LIST_DIR}/../../managed_components/espressif__arduino-esp32/cores/esp32"
  "${VENDOR_ROOT}/meshtastic-device-ui/generated"
  "${VENDOR_ROOT}/meshtastic-device-ui/generated/ui_320x240"
  "${VENDOR_ROOT}/meshtastic-device-ui/generated/ui_320x240"
  "${VENDOR_ROOT}/meshtastic-device-ui/locale"
  "${VENDOR_ROOT}/meshtastic-device-ui/drivers"
  "${VENDOR_ROOT}/OneButton/src"
  "${VENDOR_ROOT}/TBPubSubClient/src"
  "${VENDOR_ROOT}/ErriezCRC32/src"
  "${VENDOR_ROOT}/esp32_https_server/src"
  "${VENDOR_ROOT}/NTPClient"
  "${VENDOR_ROOT}/libpax/lib/libpax"
  "${VENDOR_ROOT}/Fusion"
  "${VENDOR_ROOT}/Crypto"
  "${VENDOR_ROOT}/arduino-fsm"
  "${VENDOR_ROOT}/TinyGPSPlus/src"
  "${VENDOR_ROOT}/PNGdec/src"
  "${VENDOR_ROOT}/SensorLib/src"
  "${VENDOR_ROOT}/RadioLib/src"
  "${VENDOR_ROOT}/NonBlockingRTTTL/src"
  "${GENERATED_CONFIG_DIR}"
)
list(REMOVE_DUPLICATES APP_INCLUDE_DIRS)

idf_component_register(
  SRCS ${APP_SOURCES}
  INCLUDE_DIRS ${APP_INCLUDE_DIRS}
  REQUIRES arduino-esp32 nanopb lvgl esp_wifi app_update nvs_flash efuse esp_lcd espressif__network_provisioning espressif__esp-dsp
)

# livekit/nanopb defaults to PB_BUFFER_ONLY, which bypasses pb_istream_t and
# pb_ostream_t callbacks. The firmware's filesystem persistence uses custom
# File read/write callbacks, so compiling nanopb in buffer-only mode makes it
# interpret the File object pointer as protobuf bytes and corrupts SafeFile.
idf_component_get_property(NANOPB_COMPONENT_LIB livekit__nanopb COMPONENT_LIB)
if(NOT NANOPB_COMPONENT_LIB)
  message(FATAL_ERROR "Could not find the livekit__nanopb component target")
endif()
target_compile_options(${NANOPB_COMPONENT_LIB} PRIVATE -UPB_BUFFER_ONLY)

target_include_directories(${COMPONENT_LIB} BEFORE PRIVATE
  "${DEVICE_UI}/generated/ui_320x240"
)

idf_component_get_property(LVGL_LIBRARY lvgl COMPONENT_LIB)
target_compile_definitions(${LVGL_LIBRARY} PUBLIC
  "LV_CONF_PATH=\"${VENDOR_ROOT}/meshtastic-device-ui/include/lv_conf.h\""
  # LVGL is a separate IDF component, so it needs the board's PSRAM and pool
  # size settings too; otherwise lv_conf.h falls back to a 96 KiB static pool.
  BOARD_HAS_PSRAM
  RAM_SIZE=5120
)
target_include_directories(${LVGL_LIBRARY} PUBLIC
  "${VENDOR_ROOT}/meshtastic-device-ui/include"
)

target_compile_features(${COMPONENT_LIB} PUBLIC cxx_std_17)
target_compile_options(${COMPONENT_LIB} PRIVATE
  -Wno-format -Wno-missing-field-initializers -Wno-trigraphs
  -Wno-error=overloaded-virtual
  "-ffile-prefix-map=${FW_ROOT}=/firmware"
  "-fdebug-prefix-map=${FW_ROOT}=/firmware"
  "-fmacro-prefix-map=${FW_ROOT}=/firmware"
  "-ffile-prefix-map=${VENDOR_ROOT}=/vendor"
  "-fdebug-prefix-map=${VENDOR_ROOT}=/vendor"
  $<$<COMPILE_LANGUAGE:CXX>:-include>
  $<$<COMPILE_LANGUAGE:CXX>:${CMAKE_CURRENT_LIST_DIR}/compat.h>
)
target_compile_definitions(${COMPONENT_LIB} PRIVATE
  dsps_fft2r_sc16_aes3_enabled=1
  APP_VERSION=\"${FW_VERSION_LONG}\" APP_VERSION_SHORT=\"${FW_VERSION_SHORT}\"
  APP_ENV=\"thinknode_m9-tft-nix-idf\" APP_REPO=\"meshtastic/firmware\"
  ARCH_ESP32 VIEW_320x240 LV_LVGL_H_INCLUDE_SIMPLE LV_CONF_INCLUDE_SIMPLE
  SERIAL_BUFFER_SIZE=4096 SERIAL_HAS_ON_RECEIVE
  ELECROW_ThinkNode_M9 BOARD_HAS_PSRAM HAS_SDCARD=1 SDCARD_CS=48
  SDCARD_USE_SPI1 SDCARD_SHARE_SPI SDCARD_INIT_SPI SD_SPI_FREQUENCY=75000000U
  HAS_SCREEN=1 HAS_TFT=1 USE_PACKET_API USE_PIN_BUZZER=PIN_BUZZER
  SPI_FREQUENCY=75000000
  LGFX_DRIVER_TEMPLATE DISPLAY_SIZE=320x240 LGFX_DRIVER=LGFX_GENERIC
  LGFX_PANEL=ST7789 LGFX_ROTATION=3 LGFX_CFG_HOST=SPI3_HOST
  LGFX_PIN_SCK=40 LGFX_PIN_MOSI=47 LGFX_PIN_DC=15 LGFX_PIN_CS=16
  LGFX_PIN_BL=17 LGFX_PIN_RST=14 LGFX_SCREEN_WIDTH=240 LGFX_SCREEN_HEIGHT=320
  LGFX_INVERT_LIGHT=true MUI_WIFI_PS_MIN_MODEM
  DEFAULT_FTP_SERVER_NETWORK_TYPE_ESP32=NETWORK_ESP32
  DEFAULT_STORAGE_TYPE_ESP32=STORAGE_SD CHARGING_VOLTAGE=4.25
  TINYGPS_OPTION_NO_CUSTOM_FIELDS PB_ENABLE_MALLOC=1 PB_VALIDATE_UTF8=1
  USE_THREAD_NAMES MAX_THREADS=40
  MESHTASTIC_EXCLUDE_DROPZONE=1 MESHTASTIC_EXCLUDE_REPLYBOT=1
  MESHTASTIC_EXCLUDE_RANGETEST=1 MESHTASTIC_EXCLUDE_REMOTEHARDWARE=1
  MESHTASTIC_EXCLUDE_HEALTH_TELEMETRY=1 MESHTASTIC_EXCLUDE_POWERSTRESS=1
  MESHTASTIC_EXCLUDE_GENERIC_THREAD_MODULE=1 MESHTASTIC_EXCLUDE_POWERMON=1
  RADIOLIB_EXCLUDE_CC1101=1 RADIOLIB_EXCLUDE_NRF24=1
  RADIOLIB_EXCLUDE_RF69=1 RADIOLIB_EXCLUDE_SX1231=1
  RADIOLIB_EXCLUDE_SX1233=1 RADIOLIB_EXCLUDE_SI443X=1
  RADIOLIB_EXCLUDE_RFM2X=1 RADIOLIB_EXCLUDE_AFSK=1
  RADIOLIB_EXCLUDE_BELL=1 RADIOLIB_EXCLUDE_HELLSCHREIBER=1
  RADIOLIB_EXCLUDE_MORSE=1 RADIOLIB_EXCLUDE_RTTY=1
  RADIOLIB_EXCLUDE_SSTV=1 RADIOLIB_EXCLUDE_AX25=1
  RADIOLIB_EXCLUDE_DIRECT_RECEIVE=1 RADIOLIB_EXCLUDE_PAGER=1
  RADIOLIB_EXCLUDE_FSK4=1 RADIOLIB_EXCLUDE_APRS=1
  RADIOLIB_EXCLUDE_ADSB=1 RADIOLIB_EXCLUDE_LORAWAN=1
)
