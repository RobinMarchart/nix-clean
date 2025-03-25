{
  description = "tool that removes nix direnv, result and other junk gc roots. Also updates all flake locks.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default-linux";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs =
    {
      nixpkgs,
      rust-overlay,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        toolchain_dev = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        platform_dev = pkgs.makeRustPlatform {
          rustc = toolchain_dev;
          cargo = toolchain_dev;
        };
        stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv;
        nix-clean = pkgs.callPackage ./nix-clean.nix { inherit stdenv; };
      in
      {
        packages = {
          default = nix-clean;
          inherit nix-clean;
        };
        devShells.default =
          pkgs.mkShell.override
            {
              inherit stdenv;
            }
            {
              inputsFrom = [
                (nix-clean.override { rustPlatform = platform_dev; })
              ];
              buildInputs = [
                pkgs.cargo-audit
                pkgs.rust-bin.nightly.latest.rust-analyzer
              ];
            };
      }
    )
    // (
      let
        nix-clean =
          final: prev:
          let
            stdenv = final.stdenvAdapters.useMoldLinker final.clangStdenv;
          in
          {
            nix-clean = final.callPackage ./nix-clean.nix { inherit stdenv; };
          };
      in
      {
        overlays = {
          inherit nix-clean;
          default = nix-clean;
        };
      }

    );
}
