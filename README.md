# Meshtastic ESP-IDF build experiment

An experimental Nix and CMake build recipe for Meshtastic firmware, currently targeting one board: the Elecrow ThinkNode M9 (ESP32-S3). It builds the pinned upstream firmware with ESP-IDF without using PlatformIO.

This is a proof of concept, not an official Meshtastic build workflow or a general-purpose multi-board build system. The current recipe has been flashed and exercised on one M9, but has not had comprehensive hardware testing.

## Goal

The immediate goal is to describe the toolchain, firmware sources, and component archives as versioned, hash-pinned Nix inputs, then build them through CMake and ESP-IDF. A fresh build fetches those inputs into the Nix store; the repository keeps the recipe and small overlays, not the downloaded source trees. This is an attempt at repeatable builds; bit-for-bit reproducibility and offline builds are not yet claimed.

Over the longer term, this could provide a place to migrate Meshtastic away from Arduino APIs and libraries in measured stages, toward native ESP-IDF APIs and Espressif components. That is a direction to explore, not a capability of the current firmware. Today the build still includes `espressif/arduino-esp32` and Arduino-oriented libraries; removing PlatformIO does not remove Arduino from the firmware.

## Build

```sh
git clone <repository-url> meshtastic-idf
cd meshtastic-idf
nix develop . --command idf.py build
```

The first build downloads pinned inputs that are not already cached. The application image is written to `build/meshtastic_thinknode_m9_tft.bin`. Building does not flash a device.

`userPrefs.local.jsonc` is an optional, Git-ignored file for local device settings. Without it, the build uses the defaults from the pinned Meshtastic source.

## Current scope and known gaps

- Only the ThinkNode M9 TFT profile is configured. Other boards need their own profiles and hardware validation.
- The firmware source is pinned to Meshtastic `v2.8.0.47db0e3`; ESP-IDF and registry component archives are pinned separately.
- The M9 build sets `CONFIG_MBEDTLS_CERTIFICATE_BUNDLE_MAX_CERTS=64` for the configured common certificate bundle. This setting has been exercised on the target device.
- Hardware checks so far cover boot, configuration loading, and live LoRa receive/transmit on one device. They are not a full feature or regression test suite.

## Repository map

- `flake.nix`, `flake.lock`: Nix toolchain and pinned upstream source inputs.
- `CMakeLists.txt`, `components/`, `scripts/`, `sdkconfig.defaults`, `partitions.csv`: local ESP-IDF build recipe and M9 settings.
- `registry-components.json`, `dependencies.lock`: hash-pinned Espressif registry archives and the ESP Component Manager lock.
- `patches/device-ui-nix-idf-splash.patch`: identifies this build on the M9 boot screen.
- `DEPENDENCIES.md`: source revisions used to assemble the build inputs.
- `ARDUINO_MIGRATION_INVENTORY.md`: initial inventory and possible migration phases.
- `legacy/`: archived build material; it is not used by the root build.

Build output, fetched dependencies, local device settings, and retained firmware images are excluded from Git. No Git submodule initialization is needed: Nix fetches the pinned firmware source, including its declared nested sources.
