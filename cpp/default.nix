{ pkgs ? import <nixpkgs> { }
}:

let
  makeDerivation = { ltoSupport, debugSupport }: pkgs.callPackage ./derivation.nix {
    inherit ltoSupport debugSupport;
  };
in

{
  default = makeDerivation {
    ltoSupport = false;
    debugSupport = false;
  };

  debug = makeDerivation {
    ltoSupport = false;
    debugSupport = true;
  };

  lto = makeDerivation {
    ltoSupport = true;
    debugSupport = true;
  };
}
