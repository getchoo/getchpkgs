{
  pkgs ? import nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  },
  nixpkgs ? <nixpkgs>,
  system ? builtins.currentSystem,
}:

(import ./default.nix { inherit pkgs; }).shell
