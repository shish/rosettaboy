{ pkgs ? import <nixpkgs> {} } :
let
	langShell = lang: (import (./. + ("/" + lang + "/shell.nix")) { inherit pkgs; });
	# We need this mess of no-op concatenations because Debian 11/Bullseye Stable is stuck on Nix 2.3.7 from 2020, which apparently doesn't always handle literals and antiquotation well:
	# https://gist.github.com/CMCDragonkai/de84aece83f8521d087416fa21e34df4/fde9346664741a18d2748a578d9a1b648ee42dbd
	combineShells = shells: pkgs.mkShell { inputsFrom = shells; };
in
combineShells (
	map (langShell) [
		"cpp"
		"go"
		"nim"
		"php"
		"py"
		"rs"
		"zig"
		
		"utils"
	]
)

# Some of the subshells explicitly specify very basic dependencies like `hostname`.
# This is a benefit of testing with `nix-shell --pure`.
# A lot of programs are *usually* installed, either due to widespread adoption or because they're bundled with something else, but technically aren't part of any OS base.
# That means they end up as secret, implicit dependencies, which can break without you even knowing they were there. Specifying them explicitly guarantees that they will be available.
# (Usually you probably want to just use `nix-shell`, without `--pure`, to keep access to global tools though.)

# Most of the language subshells aren't actually perfectly reproducible per se as they import the latest version of <nixpkgs> on the host system instead of pinning to a specific point in the repository history. For mature and stable languages with versioned packages, I think this is worth it to use the existing local Nix store and remote repository binary cache.
