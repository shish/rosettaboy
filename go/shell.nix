{ pkgs ? import <nixpkgs> {} } : pkgs.mkShell {
	buildInputs = with pkgs; [
		go
		SDL2
		
		pkg-config
	];
}
