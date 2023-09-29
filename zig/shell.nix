{
	pkgs ? import <nixpkgs> {},
	# Right. Getting this to work took more effort than all the other shells put 
	# together.
	# Things that didn't work:
	# - Directly using the Zig package, pinned to any version. Nix is "known 
	#   as the most up to date distribution", but this project uses a *nightly* 
	#   build of Zig, so that's not there.
	# - Building Zig from source. The latest version of Zig itself uses 
	#   LLVM+Clang 15, which is brand new and also not yet in Nix repos. There 
	#   was a brief window in late August 2022 where Zig could be built with 
	#   LLVM 14, but the most recent commit that works with that doesn't work 
	#   with this project.
	# - Building LLVM 15 from source. I didn't even try this given the massive 
	#   disk space and build time requirements.	
	zig-overlay ? pkgs.callPackage ((pkgs.fetchFromGitHub {
		# Officially this information is published without past history at: 
		# https://ziglang.org/download/index.json
		# 1. Update this URL with the latest commit.
		# 2. Try to use it with `nix-shell`. It will error because the hash is 
		#    wrong, and the right hash will be reported. Put the new hash here 
		#    too. (I swear this is what the tutorials say to do.)
		# 3. Change the "YYYY-MM-DD" key below to the new version, as long as 
		#    it's in the `sources.json`.
		owner = "mitchellh";
		repo = "zig-overlay";
		rev = "6a76f5697bcf291d1a7d88b0ef8189c2f5c9b38f";
		hash = "sha256-62E0b7i51LNHBsWbsi2ChG5gCqZfTb8/UaZren6DqXs=";
	}) + "/default.nix") {},
	zig ? zig-overlay.master-2023-02-06
}:

pkgs.mkShell {
	buildInputs = with pkgs; [
		pkg-config
		SDL2
		zig
	];
}
