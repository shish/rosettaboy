RosettaBoy Rust
===============
A GameBoy emulator, a simple project to teach myself Rust

Usage
-----
```
cargo build --release
./target/release/spindle game.gb
```

Requirements
------------
- SDL2

Completeness
------------
- Most CPU tests pass, except #3 (`OP SP,HL`) :|
- No attempt at audio :(
- Graphics rendered a line at a time, so we get to see parallax effects :)