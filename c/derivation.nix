{ lib
, stdenv
, cmake
, SDL2
, autoPatchelfHook
, pkg-config
, valgrind ? null
, clang-tools ? null
, nixpkgs-fmt ? null
, ltoSupport ? false
, debugSupport ? false
}:

let
  devTools = [ clang-tools nixpkgs-fmt valgrind ];
in

stdenv.mkDerivation {
  name = "rosettaboy-c";

  src = ./.;

  passthru = { inherit devTools; };

  enableParallelBuilding = true;

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ autoPatchelfHook cmake pkg-config ]
    ++ lib.optionals debugSupport devTools;

  cmakeFlags = [ ]
    ++ lib.optional debugSupport "-DCMAKE_BUILD_TYPE=Debug"
    ++ lib.optional (!debugSupport) "-DCMAKE_BUILD_TYPE=Release"
    ++ lib.optional ltoSupport "-DENABLE_LTO=On"
  ;

  meta = with lib; {
    description = "rosettaboy-c";
    mainProgram = "rosettaboy-c";
  };
}
