{
  description = "my cool flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    self,
    ...
  } @ inputs: {
    nixosConfigurations."myHostname" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [./configuration.nix self.nixosModules.default];
      specialArgs = {inherit inputs;} // inputs;
    };

    nixosModules.default = import ./modules;
  };
}
