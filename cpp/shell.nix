{ pkgs ? import <nixpkgs> { }
}:

let
  packages = pkgs.callPackage ./default.nix { inherit pkgs; };
in

pkgs.mkShell {
  inputsFrom = [ packages.debug ];
  nativeBuildInputs = with pkgs; [
    clang-tools # Massive, and only used for format.sh. But I think it may share some dependencies with Nim, Zig (11/generic, I think), Rust. Painful because the other requirements are so small.
    nixpkgs-fmt
  ];
}
