{ lib
, stdenv
, cmake
, SDL2
, autoPatchelfHook
, pkg-config
, ltoSupport ? false
, debugSupport ? false
}:

stdenv.mkDerivation {
  name = "rosettaboy-cpp";

  src = ./.;

  enableParallelBuilding = true;

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ autoPatchelfHook cmake pkg-config ];

  cmakeFlags = [ ]
    ++ lib.optional debugSupport "-DCMAKE_BUILD_TYPE=Debug"
    ++ lib.optional (!debugSupport) "-DCMAKE_BUILD_TYPE=Release"
    ++ lib.optional ltoSupport "-DENABLE_LTO=On"
  ;
  
  meta = with lib; {
    description = "rosettaboy-cpp";
    mainProgram = "rosettaboy-cpp";
  };
}
