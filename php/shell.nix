{ pkgs ? import <nixpkgs> {} } : pkgs.mkShell {
	buildInputs = with pkgs; [
		php81
		php81Packages.php-cs-fixer
	];
}
