{
 lib,
 stdenv,
 cmake,
 SDL2,
 pkg-config,
 cleanSource,
 clang-tools ? null,
 ltoSupport ? false,
 debugSupport ? false
}:

let
  devTools = [ clang-tools ];
in

stdenv.mkDerivation rec {
  name = "rosettaboy-c";
  src = cleanSource {
    inherit name;
    src = ./.;
    extraRules = ''
      .clang-format
    '';
  };

  passthru = { inherit devTools; };

  enableParallelBuilding = true;

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ cmake pkg-config ];

  cmakeFlags = [ ]
    ++ lib.optional debugSupport "-DCMAKE_BUILD_TYPE=Debug"
    ++ lib.optional (!debugSupport) "-DCMAKE_BUILD_TYPE=Release"
    ++ lib.optional ltoSupport "-DENABLE_LTO=On"
  ;

  meta = {
    description = name;
    mainProgram = name;
  };
}
