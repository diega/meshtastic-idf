{
  description = "Nix and ESP-IDF build for Meshtastic devices";

  inputs = {
    esp-idf-nix.url = "github:Cbeck527/esp-idf-nix";
    nixpkgs.follows = "esp-idf-nix/nixpkgs";
    meshtastic-firmware = {
      url = "git+https://github.com/meshtastic/firmware?ref=v2.8.0.47db0e3&rev=47db0e3020a608e06fb65cce70cd2f093021bd82&submodules=1";
      flake = false;
    };
    vendor-arduino-thread = { url = "github:meshtastic/ArduinoThread/b841b0415721f1341ea41cccfb4adccfaf951567"; flake = false; };
    vendor-crypto = { url = "github:meshtastic/Crypto/591ff9a690e8168ccb7a36abde8d7783e448d395"; flake = false; };
    vendor-oled = { url = "github:meshtastic/esp8266-oled-ssd1306/bb93fd40685f22e850330ea162f1dd154a4e0685"; flake = false; };
    vendor-erriez-crc32 = { url = "github:Erriez/ErriezCRC32/1.0.1"; flake = false; };
    vendor-fusion = { url = "github:meshtastic/Fusion/936e1eb1e5ea19e8f4ed467526f91adeebb4f53c"; flake = false; };
    vendor-lovyan-gfx = { url = "github:lovyan03/LovyanGFX/1.2.26"; flake = false; };
    vendor-ntpclient = { url = "github:arduino-libraries/NTPClient/3.2.1"; flake = false; };
    vendor-nonblocking-rtttl = { url = "github:end2endzone/NonBlockingRTTTL/1.4.0"; flake = false; };
    vendor-onebutton = { url = "github:meshtastic/OneButton/fa352d668c53f290cfa480a5f79ad422cd828c70"; flake = false; };
    vendor-pngdec = { url = "github:mverch67/PNGdec/d88b6fe2ec8d49c2b097a529b34d1d615ca5cf1b"; flake = false; };
    vendor-radiolib = { url = "github:jgromes/RadioLib/510e00cfb05bbc3c2b7b524262785454944adb6e"; flake = false; };
    vendor-sensorlib = { url = "github:lewisxhe/SensorLib/v0.4.1"; flake = false; };
    vendor-tb-pubsubclient = { url = "github:thingsboard/pubsubclient/v2.12.1"; flake = false; };
    vendor-tinygpsplus = { url = "github:meshtastic/TinyGPSPlus/71a82db35f3b973440044c476d4bcdc673b104f4"; flake = false; };
    vendor-arduino-fsm = { url = "github:meshtastic/arduino-fsm/7db3702bf0cfe97b783d6c72595e3f38e0b19159"; flake = false; };
    vendor-esp32-https-server = { url = "github:meshtastic/esp32_https_server/0c71f380390ad483ff134ad938e07f6cf1226c5b"; flake = false; };
    vendor-libpax = { url = "github:mverch67/libpax/6f52ee989301cdabaeef00bcbf93bff55708ce2f"; flake = false; };
    vendor-lvgl = { url = "github:lvgl/lvgl/v9.3.0"; flake = false; };
    vendor-meshtastic-device-ui = { url = "github:meshtastic/device-ui/e8a5ff337d1ead20b290307fb2159ad27fe47f86"; flake = false; };
  };

  outputs = inputs@{ self, esp-idf-nix, nixpkgs, meshtastic-firmware, ... }:
    let
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          idf = esp-idf-nix.devShells.${system}.v5;
          patchedDeviceUi = pkgs.applyPatches {
            name = "meshtastic-device-ui-nix-idf";
            src = inputs.vendor-meshtastic-device-ui;
            patches = [ ./patches/device-ui-nix-idf-splash.patch ];
          };
          registryComponents = builtins.fromJSON (builtins.readFile ./registry-components.json);
          componentNames = builtins.attrNames registryComponents;
          vendorSources = {
            ArduinoThread = inputs.vendor-arduino-thread;
            Crypto = inputs.vendor-crypto;
            "ESP8266 and ESP32 OLED driver for SSD1306 displays" = inputs.vendor-oled;
            ErriezCRC32 = inputs.vendor-erriez-crc32;
            Fusion = inputs.vendor-fusion;
            LovyanGFX = inputs.vendor-lovyan-gfx;
            NTPClient = inputs.vendor-ntpclient;
            NonBlockingRTTTL = inputs.vendor-nonblocking-rtttl;
            OneButton = inputs.vendor-onebutton;
            PNGdec = inputs.vendor-pngdec;
            RadioLib = inputs.vendor-radiolib;
            SensorLib = inputs.vendor-sensorlib;
            TBPubSubClient = inputs.vendor-tb-pubsubclient;
            TinyGPSPlus = inputs.vendor-tinygpsplus;
            "arduino-fsm" = inputs.vendor-arduino-fsm;
            esp32_https_server = inputs.vendor-esp32-https-server;
            libpax = inputs.vendor-libpax;
            lvgl = inputs.vendor-lvgl;
            "meshtastic-device-ui" = patchedDeviceUi;
          };
          lockedVendor = pkgs.runCommand "meshtastic-idf-locked-vendor" { } ''
            mkdir -p "$out"
            ${nixpkgs.lib.concatStringsSep "\n" (nixpkgs.lib.mapAttrsToList (name: source: ''
              mkdir -p "$out/${name}"
              ${if name == "meshtastic-device-ui" then ''
                cp -R ${source}/source/. "$out/${name}/"
                for path in drivers generated include locale; do
                  cp -R ${source}/"$path" "$out/${name}/$path"
                done
              '' else ''
                cp -R ${source}/. "$out/${name}/"
              ''}
            '') vendorSources)}
          '';
          lockedComponents = pkgs.runCommand "thinknode-m9-locked-components" {
            nativeBuildInputs = [ pkgs.unzip ];
          } (''
            mkdir -p "$out"
          '' + nixpkgs.lib.concatMapStrings (name:
            let
              source = builtins.elemAt registryComponents.${name} 0;
              hash = builtins.elemAt registryComponents.${name} 1;
              componentHash = builtins.elemAt registryComponents.${name} 2;
              archive = pkgs.fetchurl { url = source; sha256 = hash; };
            in ''
              mkdir -p "$out/${name}"
              unzip -q ${archive} -d "$out/${name}"
              printf '%s\n' '${componentHash}' > "$out/${name}/.component_hash"
            '') componentNames);
        in {
          default = idf.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
              pkgs.cmake
              pkgs.ninja
              pkgs.git
            ];
            shellHook = (old.shellHook or "") + ''
              export IDF_TARGET=esp32s3
              export MESHTASTIC_FW_ROOT="${meshtastic-firmware}"
              export MESHTASTIC_VENDOR_ROOT="${lockedVendor}"
              export IDF_LOCKED_COMPONENTS_DIR="${lockedComponents}"
              if [ ! -e "$PWD/managed_components" ]; then
                mkdir -p "$PWD/managed_components"
                for component in "$IDF_LOCKED_COMPONENTS_DIR"/*; do
                  ln -s "$component" "$PWD/managed_components/$(basename "$component")"
                done
              fi
              echo "ESP-IDF direct build: ThinkNode M9 TFT (ESP-IDF 5.5.x)"
              echo "Registry components: Nix SHA-256 locked; ESP Component Manager reads local sources"
            '';
          });
        });
    };
}
