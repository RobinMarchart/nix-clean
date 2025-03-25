{
  lib,
  rustPlatform,
  stdenv,
}:
let
  pname = "nix-clean";
  version = "1.0.0";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.lock
      ./Cargo.toml
      ./src
    ];
  };
in
(rustPlatform.buildRustPackage.override {
  inherit stdenv;
})
  {
    inherit src pname version;
    cargoLock.lockFile = ./Cargo.lock;
  }
