{ pkgs ? import <nixpkgs> { } }:

let
  sdl = pkgs.php81.buildPecl {
    pname = "sdl";
    version = "bd24b2";
    src = pkgs.fetchFromGitHub {
      owner = "shish";
      repo = "php-sdl";
      rev = "bd24b2600dc23717abd538ffba188b295dafe60d";
      sha256 = "0dr048bvcvb6f4gzdwb3ykim30ir6pckcsl2pwpsmv3c6ni9sq25";
    };
    buildInputs = with pkgs; [ SDL2 ];
  };

  php = pkgs.php81.withExtensions ({ enabled, all }: enabled ++ [ sdl ]);
in

pkgs.mkShell {
  buildInputs = [
    php
    php.packages.php-cs-fixer
  ];
}
