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
        nix-clean = pkgs.callPackage ./nix-clean.nix { };
      in
      {
        packages = {
          default = nix-clean;
          inherit nix-clean;
        };
        devShells.default = pkgs.mkShell {
          inputsFrom = [
            (nix-clean.override { rustPlatform = platform_dev; })
          ];
          buildInputs = [
            pkgs.cargo-nextest
            pkgs.cargo-audit
            pkgs.rust-bin.nightly.latest.rust-analyzer
          ];
        };
      }
    )
    // (
      let
        nix-clean = final: prev: {
          nix-clean = final.callPackage ./nix-clean.nix { };
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
