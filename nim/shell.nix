{ pkgs ? import <nixpkgs> {} } : pkgs.mkShell {
	buildInputs = with pkgs; [
		nim
		SDL2
		pkgs.llvmPackages_15.bintools
		
		git cacert
	];
}
