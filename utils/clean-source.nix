{
  cleanSourceWith,
  gitignoreFilterWith
}:

# see https://github.com/hercules-ci/gitignore.nix/blob/master/docs/gitignoreFilter.md

let
  customerFilter = src: extraRules:
    let
      # IMPORTANT: use a let binding like this to memoize info about the git directories.
      srcIgnored = gitignoreFilterWith {
        basePath = src;
        extraRules = ''
          .envrc
          .gitignore
          *.nix
          build*.sh
          format*.sh
        '' + extraRules;
      };
    in path: type: srcIgnored path type;
in

{
  name,
  src,
  extraRules ? ""
}:

cleanSourceWith {
  filter = customerFilter src extraRules;
  src = src;
  name = name + "-source";
}
