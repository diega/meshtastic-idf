# Arduino dependency inventory: ThinkNode M9

Scope: the source set registered by the direct M9 CMake target. The component compiles several external libraries unconditionally; a compiled library is not necessarily exercised at runtime, since features such as MQTT depend on configuration.

## Arduino-oriented libraries

| Library | M9 role | Criticality | Likely replacement effort |
| --- | --- | --- | --- |
| **RadioLib** | LoRa driver in `src/mesh/RadioLibInterface.*`; the M9 HAL uses Arduino SPI, GPIO, IRQ, and locking APIs. | Critical: radio and mesh traffic. | High. Keep `RadioInterface`; port its HAL to IDF SPI, GPIO, ISR, and FreeRTOS APIs. Validate the shared radio/display bus. |
| **ArduinoThread** | `src/concurrency/OSThread.h`; system and radio workers. | Critical: task lifecycle and synchronization. | High. Move to FreeRTOS tasks, notifications, timers, and locks while preserving semantics. |
| **arduino-fsm** | `src/PowerFSM.*` uses the FSM for power and sleep transitions. | High: affects power state and wake behavior. | Medium. Replace the wrapper with an explicit state machine and compare each transition. |
| **Crypto** | Portable crypto algorithms; `Crypto/RNG.cpp` still uses Arduino `millis()`. ESP32 AES uses mbedTLS in `src/platform/esp32/ESP32CryptoEngine.cpp`. | Critical: encrypted packets and identity. | Low for the clock/RNG coupling; higher if replacing algorithms. Preserve compatibility and validate test vectors. |
| **LovyanGFX** | M9 TFT backend in `src/graphics/TFTDisplay.cpp`; generic ST7789 over SPI3. | High for the display and user experience. | Medium-high. Move panel I/O to `esp_lcd` and keep a drawing adapter. |
| **SSD1306 OLED driver** | Supplies the shared `OLEDDisplay`/`OLEDDisplayUi` graphics interfaces used by firmware UI code, even though the M9 panel is TFT. | Medium-high: shared UI compatibility. | Medium-high. Separate the generic drawing interface from the Arduino display implementation. |
| **OneButton** | Button event handling in `src/input/ButtonThread.h`. | Low-medium: physical input. | Low. Use GPIO and an IDF timer-backed state machine. |
| **TinyGPSPlus** | NMEA parsing in `src/gps/GPS.*`; fix aging uses the Arduino clock. | Medium when the M9 GPS is enabled. | Low-medium. Keep the parser and replace UART/clock access with IDF APIs. |
| **NTPClient** | Time synchronization from `src/mesh/wifi/WiFiAPClient.cpp`; the Ethernet source is excluded from this target. | Low-medium: optional network time sync. | Low. Use ESP-IDF SNTP/time services. |
| **TBPubSubClient** | MQTT client in `src/mqtt/MQTT.*`; compiled even when MQTT is not configured for a node. | Low-medium: optional MQTT feature. | Medium. Use Espressif's MQTT component behind the existing module interface. |
| **esp32_https_server** | HTTP/HTTPS handlers in `src/mesh/http/WebServer.cpp` and `ContentHandler.cpp`. | Medium: optional local web services. | Medium-high. Port to ESP-IDF HTTP/HTTPS server APIs and preserve route behavior. |
| **NonBlockingRTTTL** | RTTTL support in `ExternalNotificationModule`; the source is compiled for this target. | Low: optional tone notifications. | Low. Use a small IDF timer-driven player or keep the parser and replace its hardware hooks. |

The CMake source list also compiles `ErriezCRC32`, `Fusion`, `PNGdec`, and `libpax`, which are portable C/C++ libraries, plus `SensorLib`, which provides an ESP-IDF backend. Do not rewrite a library just because it originated in the Arduino ecosystem; verify the APIs used by the M9 path.

## Arduino APIs in project code

The coupling extends beyond third-party libraries. Shared firmware and the M9 variant call `pinMode`, `digitalWrite`, `delay`, `millis`, `Wire`, `SPIClass`, `Serial`, and `String`. Add or adapt IDF interfaces for GPIO, I²C/SPI, time, serial, storage, and tasks before rewriting modules. The radio/display SPI bus, power transitions, and protobuf persistence are high-risk boundaries.

## Possible migration phases

1. Keep the hash-pinned Nix build as an experimental baseline. 2. Add IDF-backed adapters for time, GPIO, serial, I²C/SPI, storage, and tasks while preserving the current firmware interfaces. 3. Port M9 startup and the radio/display HAL; check stored preferences, radio TX/RX, and shared-bus behavior on hardware. 4. Replace ArduinoThread and move the TFT path to `esp_lcd` behind the existing display interface. 5. Migrate optional libraries and remove unused compatibility sources; consider removing the Arduino core only after the remaining APIs have IDF implementations.

Useful gates include preference decoding, encrypted packets, LoRa traffic, display/radio bus coexistence, and stable boot without memory regressions. This inventory is an initial map, not a completed migration plan.
