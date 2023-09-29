{ pkgs ? import <nixpkgs> {} } : pkgs.mkShell {
	buildInputs = with pkgs; [
		(python310.withPackages (pypkgs: with pypkgs; [
			pysdl2
			cython_3
			setuptools
			
			black
		])).out
		
		SDL2
	];
}
