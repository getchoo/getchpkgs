{
  description = "";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:

    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = lib.genAttrs systems;
      defaultNixFor = forAllSystems (
        system: import ./default.nix { pkgs = nixpkgs.legacyPackages.${system}; }
      );
    in

    {
      checks = forAllSystems (
        system:

        let
          pkgs = nixpkgs.legacyPackages.${system};
        in

        {
          nixfmt = pkgs.runCommand "check-nixfmt" {
            nativeBuildInputs = [ pkgs.nixfmt ];
          } "find ${self} -type f -name '*.nix' -exec nixfmt --check {} +";
        }
      );

      devShells = forAllSystems (system: {
        default = defaultNixFor.${system}.shell;
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      nixosModules.default = lib.modules.importApply ./nix/module.nix { inherit self; };

      overlays.default = final: prev: import ./overlay.nix final prev;

      packages = forAllSystems (
        system:

        let
          pkgs = nixpkgs.legacyPackages.${system};
          availableOnSystem = lib.meta.availableOn pkgs.stdenv.hostPlatform;

          packages = lib.filterAttrs (lib.const (
            deriv: !(deriv.meta.broken or false) && availableOnSystem deriv
          )) defaultNixFor.${system}.packages;
        in

        packages // { default = packages.cool-package or pkgs.emptyFile; }
      );
    };
}
