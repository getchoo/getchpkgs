{
  description = "getchoo's nix expressions";

  nixConfig = {
    extra-substituters = [ "https://getchoo.cachix.org" ];
    extra-trusted-public-keys = [ "getchoo.cachix.org-1:ftdbAUJVNaFonM0obRGgR5+nUmdLMM+AOvDOSx0z5tE=" ];
  };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:

    let
      inherit (nixpkgs) lib;

      # Support all systems exported by Nixpkgs
      systems = lib.intersectLists lib.systems.flakeExposed (with lib.platforms; darwin ++ linux);
      # But separate our primarily supported systems
      tier1Systems = lib.intersectLists systems (with lib.platforms; aarch64 ++ x86_64);

      forAllSystems = lib.genAttrs systems;
      forTier1Systems = lib.genAttrs tier1Systems;
      nixpkgsFor = nixpkgs.legacyPackages;
    in

    {
      checks = forTier1Systems (
        system:

        let
          pkgs = nixpkgsFor.${system};
        in

        {
          treefmt = pkgs.stdenvNoCC.mkDerivation {
            name = "check-treefmt";

            src = self;

            nativeBuildInputs = [ self.formatter.${system} ];

            buildCommand = ''
              runPhase unpackPhase
              treefmt --ci |& tee $out
            '';
          };
        }
        // lib.mapAttrs' (name: lib.nameValuePair "check-${name}") self.packages.${system}
      );

      packages = forAllSystems (
        system:

        let
          pkgs = nixpkgsFor.${system};

          availableOnSystem = lib.meta.availableOn pkgs.stdenv.hostPlatform;

          getchpkgs = import ./default.nix { inherit pkgs; };
          getchpkgs' = lib.filterAttrs (lib.const (
            deriv: !(deriv.meta.broken or false) && availableOnSystem deriv
          )) getchpkgs;
        in

        getchpkgs' // { default = getchpkgs'.treefetch or pkgs.emptyFile; }
      );

      overlays.default = final: prev: import ./overlay.nix final prev;

      flakeModules = import ./modules/flake;

      homeModules = import ./modules/home;

      nixosModules = import ./modules/nixos;

      formatter = forTier1Systems (
        system:

        let
          pkgs = nixpkgsFor.${system};

          nixFiles = "*.nix";
        in

        pkgs.treefmt.withConfig {
          settings = {
            tree-root-file = "flake.nix";

            formatter = {
              deadnix = {
                command = lib.getExe pkgs.deadnix;
                options = [ "--edit" ];
                includes = [ nixFiles ];
              };

              nixfmt = {
                command = lib.getExe pkgs.nixfmt;
                includes = [ nixFiles ];
              };

              nixf-diagnose = {
                command = lib.getExe pkgs.nixf-diagnose;
                includes = [ nixFiles ];
              };
            };
          };
        }
      );

      templates =
        let
          toTemplate = name: description: {
            path = ./templates + "/${name}";
            inherit description;
          };
        in
        lib.mapAttrs toTemplate {
          standard = "Minimal boilerplate for my Flakes";
          nixos = "Minimal boilerplate for a Flake-based NixOS configuration";
        };
    };
}
