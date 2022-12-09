{ pkgs ? import <nixpkgs> {} } : pkgs.mkShell {
	buildInputs = with pkgs; [
		cmake
		gnumake
		SDL2
				
		clang-tools # Massive, and only used for format.sh. But I think it may share some dependencies with Nim, Zig (11/generic, I think), Rust. Painful because the other requirements are so small.
	];
}
