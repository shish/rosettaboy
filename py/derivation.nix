{
  lib,
  python311,
  cleanSource,
  fetchFromGitHub,
  mypycSupport ? false
}:

let
  python = python311;
  pythonPackages = python.pkgs;

  # We use `match` which is only supported in `mypy` v1 and newer:
  # https://github.com/python/mypy/commit/d5e96e381f72ad3fafaae8707b688b3da320587d
  #
  # This hasn't made it's way into `nixpkgs` yet so we override for now:
  # (!!! remove once nixpkgs has 1.0.0+)
  mypy' = pythonPackages.mypy.overridePythonAttrs (old: rec {
    version = "1.0.0";
    buildInputs = (old.buildInputs or []) ++ (with pythonPackages; [ psutil types-psutil ]);
    src = fetchFromGitHub {
      owner = "python";
      repo = "mypy";
      rev = "refs/tags/v${version}";
      hash = "sha256-/E2O6J+o0OiY2v/ogatygaB07D/Z5ZQ6mB0daEQqo+4=";
    };
  });

  runtimeDeps = with pythonPackages; [ setuptools pysdl2 ];
  devDeps = with pythonPackages; [ mypy' black ];
in

pythonPackages.buildPythonApplication rec {
  name = "rosettaboy-py";
  src = cleanSource {
    inherit name;
    src = ./.;
    extraRules = ''
      py_env.sh
    '';
  };

  nativeBuildInputs = lib.optional mypycSupport mypy';

  passthru.python = python.withPackages (p: runtimeDeps ++ devDeps);
  passthru.devTools = [ python ];
 
  propagatedBuildInputs = runtimeDeps;

  ROSETTABOY_USE_MYPYC = mypycSupport;
  dontUseSetuptoolsCheck = true;

  meta = {
    description = name;
    mainProgram = name;
  };
}
