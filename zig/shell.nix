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
		sha256 = "sha256:cb9c420ce745632cecd65f99b3e9b3b9decdcbbce874e7e3e1c47c4472e8d73a";
	}))).master.${version} or (abort "Unknown version: ${version}")
	).${pkgs.stdenv.system} or (abort "Unknown platform ${pkgs.stdenv.system}");
	
	zig-pinned-bin = let zigUrl=getZigUrl "2023-02-13"; in pkgs.stdenv.mkDerivation {
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
	
	SDL2-lowercase = with pkgs; symlinkJoin {
		name =  "${SDL2.pname}-lowercase";
		paths = [ SDL2 ];
		postBuild = ''
			cd $out/lib/
			for _file in libSDL2*; do
				if [[ ! -f "''${_file,,}" ]]; then
					ln -s "$_file" "''${_file,,}"
				fi
			done;
		'';
		# Apparently, Nix capitalizing "SDL2" creates an incompatibility:
		# https://github.com/MasterQ32/SDL.zig/issues/14
		# I'm not sure what the "right" way to do it is. `zig build` seems to just be running `lld -lsdl2`, the SDL2 `.so` files are also capitalized as "libSDL2" on my non-Nix system, and GH:andrewrk/sdl-zig-demo does `exe.linkSystemLibrary("SDL2")` capitalized, so I'm inclined to call this a bug in GH:MasterQ32/SDL.zig for trying to link to non-existent lower-case "sdl2". But then presumably it works in the Docker, so IDK.
		
		# Not directly causative of or related to this issue, but interesting, how Zig handles libraries from Nix:
		# https://github.com/ziglang/zig/blob/8a344fab3908e1b793fe8f9590696142aee2a1be/lib/std/zig/system/NativePaths.zig#L29
		# https://nixos.wiki/wiki/C
	};
in
pkgs.mkShell {
	buildInputs = with pkgs; [
		zig-pinned-bin
		SDL2-lowercase
	];
}
