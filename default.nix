let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
in

{
  pkgs ? import nixpkgs {
    config = { };
    overlays = [ ];
    inherit system;
  },
  nixpkgs ? (
    fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${lock.nodes.nixpkgs.locked.rev}.tar.gz";
      sha256 = lock.nodes.nixpkgs.locked.narHash;
    }
  ),
  system ? builtins.currentSystem,
}:

let
  inherit (pkgs) lib;

  packageScope = lib.makeScope pkgs.newScope (lib.flip (import ./overlay.nix) pkgs);
in

lib.filterAttrs (lib.const lib.isDerivation) packageScope
