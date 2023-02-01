{ pkgs ? import <nixpkgs> { } }:

let
  packages = pkgs.callPackage ./default.nix { inherit pkgs; };
  php = packages.default.php;
in

pkgs.mkShell {
  inputsFrom = [ packages.default ];
  nativeBuildInputs = [ php.packages.php-cs-fixer ];
}
