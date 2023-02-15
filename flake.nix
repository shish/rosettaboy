{
  description = "rosettaboy nix flake";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    flake-utils.url = github:numtide/flake-utils;
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
      inputs.gitignore.follows = "gitignore";
    };
    gomod2nix-src = {
      url = "github:nix-community/gomod2nix";
      flake = false;
    };
    nim-argparse = {
      url = "github:iffy/nim-argparse";
      flake = false;
    };
    php-sdl-src = {
      url = "github:Ponup/php-sdl";
      flake = false;
    };
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
    zig-sdl = {
      url = "github:MasterQ32/SDL.zig/6b33f1f4299ec8814e9fb3b206cda37791ced574";
      flake = false;
    };
    zig-clap = {
      url = "github:Hejsil/zig-clap/272d8e2088b2cae037349fb260dc05ec46bba422";
      flake = false;
    };
    gb-autotest-roms = {
      url = "github:shish/gb-autotest-roms";
      flake = false;
    };
    cl-gameboy = {
      url = "github:sjl/cl-gameboy";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    gitignore,
    pre-commit-hooks,
    gomod2nix-src,
    nim-argparse,
    php-sdl-src,
    naersk,
    zig-overlay,
    zig-sdl,
    zig-clap,
    gb-autotest-roms,
    cl-gameboy,
    ...
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;
    inherit (builtins) mapAttrs;
    inherit (lib) hiPrio filterAttrs;
    gomod2nix' = rec {
      gomod2nix = pkgs.callPackage "${gomod2nix-src}" { inherit buildGoApplication mkGoEnv; };
      inherit (pkgs.callPackage "${gomod2nix-src}/builder" { inherit gomod2nix; }) buildGoApplication mkGoEnv;
    };
    callPackage = pkgs.newScope {
      inherit gb-autotest-roms cl-gameboy;
      # inherit (gitignore.lib) gitignoreSource;
      cleanSource = import ./utils/clean-source.nix { inherit (gitignore.lib) gitignoreFilterWith; inherit (lib) cleanSourceWith; };
      inherit php-sdl-src;
      inherit nim-argparse;
      inherit (gomod2nix') gomod2nix buildGoApplication;
      naersk = pkgs.callPackage naersk {};
      zig = zig-overlay.packages.${system}.master-2023-02-06;
      inherit zig-clap zig-sdl;
    };

    utils = callPackage ./utils/derivation.nix {};

    mkC = {clangSupport ? false, ltoSupport ? false, debugSupport ? false}: 
      callPackage ./c/derivation.nix {
        stdenv = if clangSupport then pkgs.clangStdenv else pkgs.stdenv;
        inherit ltoSupport debugSupport;
      };

    mkCpp = {ltoSupport ? false, debugSupport ? false, clangSupport ? false}:
      callPackage ./cpp/derivation.nix {
        stdenv = if clangSupport then pkgs.clangStdenv else pkgs.stdenv;
        inherit ltoSupport debugSupport;
      };
      
    mkGo = {...}:
        callPackage ./go/derivation.nix {
      };

    mkNim = {debugSupport ? false, speedSupport ? false}:
      callPackage ./nim/derivation.nix {
        inherit debugSupport speedSupport;
        inherit (pkgs.llvmPackages_14) bintools;
      };

    mkPhp = {opcacheSupport ? false}:
      callPackage ./php/derivation.nix {
        inherit opcacheSupport;
      };

    mkPxd = {}:
      callPackage ./pxd/derivation.nix {};

    mkPy = {mypycSupport ? false}:
      callPackage ./py/derivation.nix {
        inherit mypycSupport;
      };

    mkRs = {ltoSupport ? false, debugSupport ? false}:
      callPackage ./rs/derivation.nix {
        inherit ltoSupport debugSupport;
      };

    mkZig = {safeSupport ? false, fastSupport ? false}:
      callPackage ./zig/derivation.nix {
        inherit safeSupport fastSupport;
      };

    pre-commit-check = pre-commit-hooks.lib.${system}.run {
      src = ./.;
      hooks = {
        actionlint.enable = true;
        #deadnix.enable = true;
        shellcheck.enable = true;
      };
    };

  in rec {
    packages = rec {
      inherit utils;
      
      c-debug = mkC { debugSupport = true; };
      c-lto = mkC { ltoSupport = true; };
      c-release = mkC { };
      c-clang-debug = mkC { debugSupport = true; clangSupport = true; };
      c-clang-lto = mkC { ltoSupport = true; clangSupport = true; };
      c-clang-release = mkC { clangSupport = true; };
      c = hiPrio c-release;

      cpp-release = mkCpp {};
      cpp-debug = mkCpp { debugSupport = true; };
      cpp-lto = mkCpp { ltoSupport = true; };
      cpp-clang-release = mkCpp { clangSupport = true; };
      cpp-clang-debug = mkCpp { debugSupport = true; clangSupport = true; };
      cpp-clang-lto = mkCpp { ltoSupport = true; clangSupport = true; };
      cpp = hiPrio cpp-release;
      
      go-release = mkGo {};
      go = hiPrio go-release;

      nim-release = mkNim {};
      nim-debug = mkNim { debugSupport = true; };
      nim-speed = mkNim { speedSupport = true; };
      nim = hiPrio nim-release;

      php-release = mkPhp {};
      php-opcache = mkPhp { opcacheSupport = true; };
      php = hiPrio php-release;

      py-release = mkPy {};
      py-mypyc = mkPy { mypycSupport = true; };
      py = hiPrio py-release;

      pxd-release = mkPxd {};
      pxd = hiPrio pxd-release;
      
      rs-debug = mkRs { debugSupport = true; };
      rs-release = mkRs { };
      rs-lto = mkRs { ltoSupport = true; };
      rs = hiPrio rs-release;
      
      zig-fast = mkZig { fastSupport = true; };
      zig-safe = mkZig { safeSupport = true; };
      zig = hiPrio zig-fast;

      # I don't think we can join all of them because they collide
      default = pkgs.symlinkJoin {
        name = "rosettaboy";
        paths = [ c cpp go nim php pxd py rs zig ];
        # if we use this without adding build tags to the executable,
        # it'll build all variants but not symlink them
        # paths = builtins.attrValues (filterAttrs (n: v: n != "default") packages);
      };
    };

    checks = let
      # zig-safe is too slow - skip
      packagesToCheck = filterAttrs (n: p: p.meta ? mainProgram && n != "zig-safe") packages;
    in {
      inherit pre-commit-check;
    } // mapAttrs (_: utils.mkBlargg) packagesToCheck;

    devShells = let
      shellHook = ''
          export GB_DEFAULT_AUTOTEST_ROM_DIR=${gb-autotest-roms}
          export GB_DEFAULT_BENCH_ROM=${cl-gameboy}/roms/opus5.gb
        '';
      langDevShells = mapAttrs (name: package: pkgs.mkShell {
        inputsFrom = [ package ];
        buildInputs = package.devTools or [];
        inherit shellHook;
      }) packages;
    in langDevShells // {
      default = pkgs.mkShell {
        inputsFrom = builtins.attrValues langDevShells;
        inherit (pre-commit-check) shellHook;
      };
      # something wrong with using it in `inputsFrom`
      py = pkgs.mkShell {
        buildInputs = packages.py.devTools;
        inherit shellHook;
      };
    };
  });
}
