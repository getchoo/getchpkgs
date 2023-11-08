final: prev:
with prev; let
  # directories are mapped to packages here for convenience sake
  imported = lib.pipe ./. [
    builtins.readDir

    (
      lib.filterAttrs (
        name: type: !(lib.hasPrefix "_" name) && type == "directory"
      )
    )

    (
      lib.mapAttrs (
        file: _: callPackage ./${file} {}
      )
    )
  ];
in
  imported
  // {
    klassy = libsForQt5.callPackage ./klassy {};

    modrinth-app-unwrapped = callPackage ./modrinth-app {
      inherit (final.nodePackages or prev.nodePackages) pnpm;
      inherit ((final.darwin or prev.darwin).apple_sdk.frameworks) CoreServices Security WebKit;
    };

    modrinth-app = callPackage ./modrinth-app/wrapper.nix {
      inherit (final) modrinth-app-unwrapped;
    };
  }
