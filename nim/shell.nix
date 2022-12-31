{ pkgs ? import <nixpkgs> {} } : pkgs.mkShell {
	buildInputs = with pkgs; [
		nim
		SDL2
		lld
		
		git cacert
	];
}
