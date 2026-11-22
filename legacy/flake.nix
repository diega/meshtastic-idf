{
  description = "Dev environment to build and flash Meshtastic firmware (ThinkNode M9) and manage the node";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.platformio   # builds the firmware (downloads toolchains on first build)
            pkgs.esptool      # USB flashing (ESP32-S3)
            pkgs.git
            pkgs.gh
            # `meshtastic` CLI to configure the node. Tests are disabled: they pull in
            # `pytap2` (TAP tunnel, Linux only), which breaks evaluation on macOS.
            (pkgs.python3Packages.meshtastic.overridePythonAttrs (_: {
              doCheck = false;
              nativeCheckInputs = [ ];
            }))
          ];

          # PlatformIO toolchains live inside the project, not in ~/.platformio.
          shellHook = ''
            export PLATFORMIO_CORE_DIR="$(cd .. && pwd)/.platformio"
            echo "Meshtastic dev shell. Typical steps:"
            echo "  git clone https://github.com/meshtastic/firmware ../firmware"
            echo "  cd ../firmware && pio run -e thinknode_m9-tft   # archived workflow, no flashing"
            echo "  meshtastic --ble-scan                        # list nodes over Bluetooth"
          '';
        };
      });
    };
}
