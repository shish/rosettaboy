{ pkgs ? import <nixpkgs> { } }:

let
  sdl = pkgs.php82.buildPecl {
    pname = "sdl";
    version = "655e40";
    src = pkgs.fetchFromGitHub {
      owner = "Ponup";
      repo = "php-sdl";
      rev = "655e403b8a9681c418702a74833c68c1a4ae1bd5";
      sha256 = "1kfw1s4ip8y0zfyl61ipw3ql9c4d9f0bwwg398kfl9p8k3vc857h";
    };
    buildInputs = with pkgs; [ SDL2 ];
  };

  php = pkgs.php82.withExtensions ({ enabled, all }: enabled ++ [ sdl ]);
in

pkgs.mkShell {
  buildInputs = [
    php
    php.packages.php-cs-fixer
  ];
}
