{
  lib,
  rustPlatform,
}:
let
  pname = "nix-clean";
  version = "1.0.0";
  fileset = lib.fileset.unions [
    ./Cargo.lock
    ./Cargo.toml
    ./src
  ];
  src = lib.fileset.toSource {
    root = ./.;
    inherit fileset;
  };
in
rustPlatform.buildRustPackage {
  inherit src pname version;
  cargoLock.lockFile = ./Cargo.lock;
}
