{ pkgs ? import <nixpkgs> {} } : pkgs.mkShell {
	buildInputs = with pkgs; [
		wget cacert
	];
}
