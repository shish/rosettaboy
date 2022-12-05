{ pkgs ? import <nixpkgs> {} } :
let
# # 	zig-commit = "34fa6a1e0437ab7f08a2ccff2aff88aa77aeb037";
# # 	zig-commit = "3c3def6ac2b01cd2c78e296f328d67d064d73f15";
# 	zig-commit = "e863292fe2f280945d914e7e98fbc704b68f1004"; # Last commit supporting LLVM 14. Nix are currently working on packaging LLVM 15.
# 	zig-pinned = pkgs.llvmPackages_14.stdenv.mkDerivation {
# 		# Based on https://github.com/chivay/zig-nightly/blob/2e9419a6d2402b44b33d2d9127de6143e3186fd4/flake.nix, but de-flaked. Actually the Nix version for Debian stable doesn't even support flakes yet.
# 		pname = "zig-pinned";
# 		version = zig-commit;
# 		src = pkgs.fetchFromGitHub {
# 			owner = "ziglang";
# 			repo = "zig";
# 			rev = zig-commit;
# 			hash = "sha256:1sywgcs72kkl1pr96534r2n3y5l5gbhf7vcm7fpmhknn8qp82hrv";
# 		};
# # 		cmakeFlags = "";
# 		nativeBuildInputs = with pkgs; [
# 			cmake
# 			llvmPackages_14.llvm.dev
# 		];
# 		buildInputs = with pkgs; [
# 			libxml2
# 			zlib
# 			llvmPackages_14.libclang
# 			llvmPackages_14.lld
# 			llvmPackages_14.llvm
# 		];
# 		preBuild = ''
# 			export HOME=$TMPDIR;
# 		'';
# 	};
# 	getZigUrl = {}: with pkgs.stdenv; (
# 		# Screw it. (The source builds above, but is still seemingly an API-incompatible version from the latest LLVM 14-compatible commit.) Let's just download the official binaries. It'll be way faster too.
# 		# From: https://ziglang.org/download/
# 		# Automate with https://ziglang.org/download/index.json I guess if updating this becomes a problem.
# 		if isLinux then
# 			if isx86_64 then {
# 				url = "https://ziglang.org/download/0.10.0/zig-linux-x86_64-0.10.0.tar.xz";
# 				sha256 = "sha256:631ec7bcb649cd6795abe40df044d2473b59b44e10be689c15632a0458ddea55";
# 			} else if isAarch64 then {
# 				url = "https://ziglang.org/download/0.10.0/zig-linux-aarch64-0.10.0.tar.xz";
# 				sha256 = "sha256:09ef50c8be73380799804169197820ee78760723b0430fa823f56ed42b06ea0f";
# 			} else if isi686 || isx86_32 then {
# 				url = "https://ziglang.org/download/0.10.0/zig-linux-i386-0.10.0.tar.xz";
# 				sha256 = "sha256:dac8134f1328c50269f3e50b334298ec7916cb3b0ef76927703ddd1c96fd0115";
# 			} else if isAarch32 then {
# 				url = "https://ziglang.org/download/0.10.0/zig-linux-armv7a-0.10.0.tar.xz";
# 				sha256 = "sha256:7201b2e89cd7cc2dde95d39485fd7d5641ba67dc6a9a58c036cb4c308d2e82de";
# 			} else
# 				abort "Unknown Linux platform."
# 		else if isDarwin then
# 			if isx86_64 then {
# 				url = "https://ziglang.org/download/0.10.0/zig-macos-x86_64-0.10.0.tar.xz";
# 				sha256 = "sha256:3a22cb6c4749884156a94ea9b60f3a28cf4e098a69f08c18fbca81c733ebfeda";
# 			} else if isAarch64 then {
# 				url = "https://ziglang.org/download/0.10.0/zig-macos-aarch64-0.10.0.tar.xz";
# 				sha256 = "sha256:02f7a7839b6a1e127eeae22ea72c87603fb7298c58bc35822a951479d53c7557";
# 			} else
# 				abort "Unknown Darwin platform."
# 		else if isFreeBSD then
# 			if isx86_64 then {
# 				url = "https://ziglang.org/download/0.10.0/zig-freebsd-x86_64-0.10.0.tar.xz";
# 				sha256 = "sha256:dd77afa2a8676afbf39f7d6068eda81b0723afd728642adaac43cb2106253d65";
# 			} else
# 				abort "Unknown FreeBSD platform."
# 		else
# 			abort "Unknown platform."
# 	);

	# Right. Getting this to work took more effort than all the other shells put together.
	# Things that didn't work:
	# - Directly using the Zig package, pinned to any version. Nix is "known as the most up to date distribution", but this project uses a *nightly* build of Zig, so that's not there.
	# - Building Zig from source. The latest version of Zig itself uses LLVM+Clang 15, which is brand new and also not yet in Nix repos. There was a brief window in late August 2022 where Zig could be built with LLVM 14, but the most recent commit that works with that doesn't work with this project.
	# - Building LLVM 15 from source. I didn't even try this given the massive disk space and build time requirements.

# 	getZigUrl = {}: { # 2022-10-17
# 		# Grabbed the URLs conveniently from here: https://github.com/mitchellh/zig-overlay/blob/main/sources.json
# 		# Officially they're published without past history at: https://ziglang.org/download/index.json
# 		x86_64-darwin = {
# 			url = "https://ziglang.org/builds/zig-macos-x86_64-0.10.0-dev.4437+1e963053d.tar.xz";
# 			sha256 = "da1c958fdc8ac6b88c0b997497795f65c45cc7600642a68284812e6635400594";
# 			version = "0.10.0-dev.4437+1e963053d";
# 		};
# 		aarch64-darwin = {
# 			url = "https://ziglang.org/builds/zig-macos-aarch64-0.10.0-dev.4437+1e963053d.tar.xz";
# 			sha256 = "f31bf3562125df1d6385cbcffd10eded6c6c8c822f4ba464513412e1815f798b";
# 			version = "0.10.0-dev.4437+1e963053d";
# 		};
# 		x86_64-linux = {
# 			url = "https://ziglang.org/builds/zig-linux-x86_64-0.10.0-dev.4437+1e963053d.tar.xz";
# 			sha256 = "7858e053facf3550fdf52f9d7c63441705a4d8158520e10e51ae0a2d29ca5634";
# 			version = "0.10.0-dev.4437+1e963053d";
# 		};
# 		aarch64-linux = {
# 			url = "https://ziglang.org/builds/zig-linux-aarch64-0.10.0-dev.4437+1e963053d.tar.xz";
# 			sha256 = "cb43f1d32b5e0b7f20a1013cc4e2f849a124ba2e433a87eebedc4da8aa5b12c4";
# 			version = "0.10.0-dev.4437+1e963053d";
# 		};
# 	}.${pkgs.stdenv.system} or (abort "Unknown platform: ${pkgs.stdenv.system}");
	
	getZigUrl = version: with builtins; ((fromJSON (readFile (fetchurl {
		# Officially this information is published without past history at: https://ziglang.org/download/index.json
		# TODO: To switch to a newer version of Zig:
		# 1. Update this URL with the latest commit.
		# 2. Try to use it with `nix-shell`. It will error because the hash is wrong, and the right hash will be reported. Put the new hash here too.
		# 3. Change the "YYYY-MM-DD" key below to the new version, as long as it's in the `sources.json`.
		url = "https://raw.githubusercontent.com/mitchellh/zig-overlay/17352071583eda4be43fa2a312f6e061326374f7/sources.json";
		sha256 = "sha256:0356h1aaknnzzk0lrjjbg5lwy9b3i06rsww91cmjs45scy6h7fj2";
	}))).master.${version} or (abort "Unknown version: ${version}")
	).${pkgs.stdenv.system} or (abort "Unknown platform ${pkgs.stdenv.system}");
	
	zig-pinned-bin = let zigUrl=getZigUrl "2022-11-29"; in pkgs.stdenv.mkDerivation {
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
				_file_lower="libsdl2$(echo $_file | cut -c 8-)"
				if [ ! -a $_file_lower ]; then
					ln -s $_file $_file_lower
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
