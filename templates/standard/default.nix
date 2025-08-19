{
  pkgs ? import nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  },
  nixpkgs ? <nixpkgs>,
  system ? builtins.currentSystem,
}:

let
  inherit (pkgs) lib;

  packageScope = lib.makeScope pkgs.newScope (lib.flip (import ./overlay.nix) pkgs);
  packages = lib.filterAttrs (lib.const lib.isDerivation) packageScope;
in

{
  inherit packages;
  shell = pkgs.mkShellNoCC {
    packages = [ pkgs.bash ];
    inputsFrom = [ packages.cool-package ];
  };
}
