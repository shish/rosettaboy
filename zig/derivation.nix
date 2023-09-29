{ 
  stdenv,
  lib,
  darwin,
  libiconv,
  zig,
  pkg-config,
  SDL2,
  zig-sdl,
  zig-clap,
  autoPatchelfHook,
  cleanSource,
	safeSupport ? false,
	fastSupport ? false
}:

let
  # `apple_sdk` defaults to `10_12` instead of `11_0` on `x86_64-darwin` but we
  # need `CoreHaptics` to successfully link against `SDL2` and `CoreHaptics` is
  # not available in `10_12`.
  #
  # So, we use `11_0`, even on x86_64.
  inherit (darwin.apple_sdk_11_0) frameworks;
in

stdenv.mkDerivation rec {
  name = "rosettaboy-zig";
  src = cleanSource {
    inherit name;
    src = ./.;
    extraRules = ''
      lib
    '';
  };

  passthru = {
    devTools = [ zig ];
  };

  buildInputs = [ SDL2 ]
    ++ lib.optionals stdenv.isDarwin (with frameworks; [
      IOKit GameController CoreAudio AudioToolbox QuartzCore Carbon Metal
      Cocoa ForceFeedback CoreHaptics
    ])
    ++ lib.optional stdenv.isDarwin libiconv
    ;
  
  nativeBuildInputs = [ zig pkg-config ]
    ++ lib.optional (!stdenv.isDarwin) autoPatchelfHook
    ;

  dontConfigure = true;
  dontBuild = true;

  # Unforunately `zig`'s parsing of `NIX_LDFLAGS` bails when it encounters any
  # flags it does not expect.
  # https://github.com/ziglang/zig/blob/fe6dcdba1407f00584725318404814571cdbd828/lib/std/zig/system/NativePaths.zig#L79
  #
  # When `zig` sees the `-liconv` flag that's in `NIX_LDFLAGS` on macOS, it
  # bails, causing it to miss the `-L` path for SDL.
  #
  # Really, this should be fixed in upstream (zig) but for now we just strip out
  # the `-l` flags:
  preInstall = lib.optionalString stdenv.isDarwin ''
    readonly ORIGINAL_NIX_LDFLAGS=($NIX_LDFLAGS)

    NIX_LDFLAGS=""
    for c in "''${ORIGINAL_NIX_LDFLAGS[@]}"; do
      # brittle, bad, etc; this presumes `-l...` style args (no space)
      if [[ $c =~ ^-l.* ]]; then
        echo "dropping link flag: $c"
        continue
      else
        echo "keeping link flag: $c"
        NIX_LDFLAGS="$NIX_LDFLAGS $c"
      fi
    done

    export NIX_LDFLAGS
  '';

  ZIG_FLAGS = []
    ++ lib.optional fastSupport "-Doptimize=ReleaseFast"
    ++ lib.optional safeSupport "-Doptimize=ReleaseSafe"
    ;

  installPhase = ''
    runHook preInstall

    export HOME=$TMPDIR
    mkdir -p lib
    cp -aR ${zig-sdl}/ lib/sdl
    cp -aR ${zig-clap}/ lib/clap
    zig build $ZIG_FLAGS --prefix $out install
    mv $out/bin/rosettaboy $out/bin/rosettaboy-zig

    runHook postInstall
  '';

  meta = {
    description = name;
    mainProgram = name;
  };
}
