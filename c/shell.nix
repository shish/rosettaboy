{ pkgs ? import <nixpkgs> { } }:

let
  packages = pkgs.callPackage ./default.nix { };
in

pkgs.mkShell {
  inputsFrom = [ packages.gcc.default ];
  buildInputs = [ packages.gcc.default.devTools ];
}
