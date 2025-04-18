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

  callPackage = lib.callPackageWith (pkgs // pkgs');

  pkgs' = {
    hello = callPackage ./nix/package.nix { };
  };
in

pkgs'
