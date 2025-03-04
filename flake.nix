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

          mkCheck =
            name: deps: script:
            pkgs.runCommand name { nativeBuildInputs = deps; } ''
              ${script}
              touch $out
            '';
        in
        {
          deadnix = mkCheck "check-deadnix" [ pkgs.deadnix ] "deadnix --fail ${self}";
          nixfmt = mkCheck "check-nixfmt" [ pkgs.nixfmt-rfc-style ] "nixfmt --check ${self}/**.nix";
          statix = mkCheck "check-statix" [ pkgs.statix ] "statix check ${self}";
        }
      );

      packages = forAllSystems (
        system:

        let
          pkgs = nixpkgsFor.${system};

          getchpkgs = import ./default.nix { inherit pkgs; };

          getchpkgs' = lib.filterAttrs (lib.const (
            deriv:
            let
              isCross = deriv.stdenv.buildPlatform != deriv.stdenv.hostPlatform;
              availableOnHost = lib.meta.availableOn pkgs.stdenv.hostPlatform deriv;
              # `nix flake check` doesn't like broken packages
              isBroken = deriv.meta.broken or false;
            in
            isCross || availableOnHost && (!isBroken)
          )) getchpkgs;
        in

        getchpkgs' // { default = getchpkgs'.treefetch or pkgs.emptyFile; }
      );

      flakeModules = import ./modules/flake;

      homeModules = import ./modules/home;

      nixosModules = import ./modules/nixos;

      formatter = forTier1Systems (system: nixpkgsFor.${system}.nixfmt-rfc-style);

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

      hydraJobs = forTier1Systems (system: {
        all-packages = nixpkgsFor.${system}.linkFarm "all-packages" (
          lib.mapAttrs (lib.const (deriv: deriv.outPath or deriv)) self.packages.${system}
        );
      });
    };
}
