# getchpkgs

[![Build status](https://img.shields.io/github/actions/workflow/status/getchoo/getchpkgs/ci.yaml?style=flat-square&logo=github&label=Build%20status&color=5277c3)](https://github.com/getchoo/getchpkgs/actions/workflows/ci.yaml)

My nix expressions not quite ready for nixpkgs yet - if ever

## How to Use

### Enabling the Binary Cache

All packages are cached by [cachix](https://cachix.org). To enable it, you can run
`nix run nixpkgs#cachix use getchoo`. It may may also be used in the `nixConfig` attribute
of Flakes or in a system configuration.

<details>
<summary>Example</summary>

```nix
{
  nix.settings = {
    substituters = [ "https://getchoo.cachix.org" ];
    trusted-public-keys = [ "getchoo.cachix.org-1:ftdbAUJVNaFonM0obRGgR5+nUmdLMM+AOvDOSx0z5tE=" ];
  };
}
```

</details>

### Flake-based

Flakes are the primary method to use this repository

#### Installing Packages

You can add this repository as an input, and optionally override the nixpkgs input to build against
your own revision of nixpkgs

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    getchpkgs = {
      url = "github:getchoo/getchpkgs";
      # this will break reproducibility, but lower the instances of nixpkgs
      # in flake.lock and possibly duplicated dependencies
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, getchpkgs, ... }:

    {
      nixosConfigurations.myMachine = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix

          (
            { pkgs, ... }:

            let
              inherit (pkgs.stdenv.hostPlatform) system;
            in

            {
              environment.systemPackages = [
                getchpkgs.packages.${system}.treefetch
              ];
            }
          )
        ];
      };
    };
}
```

#### Ad-hoc Installation

This Flake can also be used in the base Nix package manager!

The best way to make these packages available for you is to
add it to your flake registry like so:

```console
$ nix registry add getchpkgs 'github:getchoo/getchpkgs'
$ nix profile install 'getchpkgs#treefetch'
$ nix shell 'getchpkgs#treefetch'
```

### Stable Nix

There are two main ways to use this repository with stable Nix: channels and [`npins`](https://github.com/andir/npins) (or similar)

To add the channel, run:

```console
$ nix-channel --add https://github.com/getchoo/getchpkgs/archive/main.tar.gz getcpkgs
$ nix-channel --update getchpkgs
```

To use `npins`, please view their [Getting Started guide](https://github.com/andir/npins?tab=readme-ov-file#getting-started) to initialize your project.
After, run:

```console
$ npins add github getchoo getchpkgs
```

#### Installing Packages

```nix
{ pkgs, ... }:

let
  # If you use channels
  getcpkgs = import <getchpkgs> {
    # Add this if you want to use your own nixpkgs
    inherit pkgs;
  };

  # Or if you use `npins`
  # sources = import ./npins;
  # getchoo = import sources.getchpkgs { };
in

{
  environment.systemPackages = [ getchpkgs.treefetch ];
}
```

#### Ad-hoc Installation

Channels are the recommended method of adhoc-installation and usage. After adding it with the command above, you can use it like so:

```console
$ nix-env -f '<getchpkgs>' -iA treefetch
$ nix-shell '<getchpkgs>' -p treefetch
```
