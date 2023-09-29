{
  lang,
  attr ? "checks",
  system ? builtins.currentSystem,
  prefix ? ".#${attr}.${system}.",
  lib ? import <nixpkgs/lib>
}:

attrs: lib.pipe attrs.${system} [
  builtins.attrNames
  (builtins.filter (x: x == lang || lib.hasPrefix "${lang}-" x))
  (builtins.map (x: "${prefix}${x}"))
  (builtins.concatStringsSep "\n")
]
