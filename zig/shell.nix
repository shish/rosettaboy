{ pkgs ? import <nixpkgs> {} } :
let
	# Right. Getting this to work took more effort than all the other shells put together.
	# Things that didn't work:
	# - Directly using the Zig package, pinned to any version. Nix is "known as the most up to date distribution", but this project uses a *nightly* build of Zig, so that's not there.
	# - Building Zig from source. The latest version of Zig itself uses LLVM+Clang 15, which is brand new and also not yet in Nix repos. There was a brief window in late August 2022 where Zig could be built with LLVM 14, but the most recent commit that works with that doesn't work with this project.
	# - Building LLVM 15 from source. I didn't even try this given the massive disk space and build time requirements.	
	getZigUrl = version: with builtins; ((fromJSON (readFile (fetchurl {
		# Officially this information is published without past history at: https://ziglang.org/download/index.json
		# TODO: To switch to a newer version of Zig:
		# 1. Update this URL with the latest commit.
		# 2. Try to use it with `nix-shell`. It will error because the hash is wrong, and the right hash will be reported. Put the new hash here too. (I swear this is what the tutorials say to do.)
		# 3. Change the "YYYY-MM-DD" key below to the new version, as long as it's in the `sources.json`.
		url = "https://raw.githubusercontent.com/mitchellh/zig-overlay/7f6b977414710c4e7f1f0f8a5e66876cda9cface/sources.json";
		sha256 = "sha256:0fnpx1r48z64w7iyfx78pk5wvpmrnglv76azsvn2qqs5ww64576b";
	}))).master.${version} or (abort "Unknown version: ${version}")
	).${pkgs.stdenv.system} or (abort "Unknown platform ${pkgs.stdenv.system}");
	
	zig-pinned-bin = let zigUrl=getZigUrl "2023-02-09"; in pkgs.stdenv.mkDerivation {
		pname = "zig-bin";
		inherit (zigUrl) version;
		
		src = pkgs.fetchurl {
			inherit (zigUrl) url sha256;
		};
		
		installPhase = ''
			mkdir -p $out/
			for _f in *; do
				echo "Installing file: $_f"
				cp -r $_f $out/$_f
			done
			mkdir -p $out/bin/
			ln -s $out/zig $out/bin/zig
		'';
	};
	
	# The build doesn't currently work on Debian Stable (11/Bullseye) because system GLIBC is limited to 2.31 there, but compiled output is linked against 2.32-2.34. But it runs great when system GLIBC is new enough.
	# FIXME: Find a reasonable way to work around that.
in
pkgs.mkShell {
	buildInputs = with pkgs; [
		zig-pinned-bin
		SDL2
	];
}
