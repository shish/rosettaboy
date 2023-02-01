{ pkgs ? import <nixpkgs> { }
}:

{
  default = pkgs.callPackage ./derivation.nix { opcacheSupport = false; };
  opcache = pkgs.callPackage ./derivation.nix { opcacheSupport = true; };
}
