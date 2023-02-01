{ stdenv
, lib
, fetchFromGitHub
, makeWrapper
, php
, SDL2
, opcacheSupport ? false
}@args:

let
  sdl = php.buildPecl {
    pname = "sdl";
    version = "655e40";
    src = fetchFromGitHub {
      owner = "Ponup";
      repo = "php-sdl";
      rev = "655e403b8a9681c418702a74833c68c1a4ae1bd5";
      sha256 = "1kfw1s4ip8y0zfyl61ipw3ql9c4d9f0bwwg398kfl9p8k3vc857h";
    };
    buildInputs = [ SDL2 ];
  };

  php = args.php.buildEnv {
    extensions = ({ enabled, all }: enabled ++ [ sdl ]);
    extraConfig = lib.optionalString opcacheSupport ''
      opcache.enable_cli=1
      opcache.jit_buffer_size=100M
    '';
  };
in

stdenv.mkDerivation {
  name = "rosettaboy-php";

  src = ./.;

  passthru = {
    inherit php;
  };

  buildInputs = [ php ];
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/$name
    cp src/* $out/libexec/$name

    makeWrapper $out/libexec/$name/main.php $out/bin/$name

    runHook postInstall
  '';
}
