{ pkgs ? import <nixpkgs> { }
}:

let
  makeDerivation = { stdenv, ltoSupport, debugSupport }: pkgs.callPackage ./derivation.nix {
    inherit ltoSupport debugSupport stdenv;
  };

  makeDerivation' = stdenv: (pkgs.recurseIntoAttrs {
    default = makeDerivation {
      inherit stdenv;
      ltoSupport = false;
      debugSupport = false;
    };

    debug = makeDerivation {
      inherit stdenv;
      ltoSupport = false;
      debugSupport = true;
    };

    lto = makeDerivation {
      inherit stdenv;
      ltoSupport = true;
      debugSupport = true;
    };
  });
in

pkgs.recurseIntoAttrs {
  gcc = makeDerivation' pkgs.stdenv;
  clang = makeDerivation' pkgs.clangStdenv;
}
