{
  description = "My cool Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    getchpkgs = {
      url = "github:getchoo/getchpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:

    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.getchpkgs.flakeModules.configurations
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      configurations = {
        nixos = {
          my-machine = {
            # You should already have this file in /etc/nixos
            modules = [ ./configuration.nix ];
          };
        };
      };

      perSystem =
        { pkgs, self', ... }:

        {
          # Use `nix develop` to enter a shell with tools for this repository
          devShells = {
            default = pkgs.mkShellNoCC {
              packages = [
                pkgs.just

                # Lets you run `nixfmt` to format all of your files
                self'.formatter
              ];
            };
          };

          # You can also use `nix fmt`
          formatter = pkgs.nixfmt;
        };
    };
}
