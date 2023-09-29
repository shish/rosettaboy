{ pkgs ? import <nixpkgs> {} } : pkgs.mkShell {
	buildInputs = with pkgs; [
		rustc
		cargo
		SDL2
		
		rustfmt
	] ++ (pkgs.lib.optional pkgs.targetPlatform.isMacOS pkgs.libiconv);
}
