RosettaBoy Rust
===============
A GameBoy emulator, a simple project to teach myself Rust

Usage
-----
```
cargo run -- game.gb
```

(`cargo run --release` if you want it to be faster and less debuggable)

Requirements
------------
- SDL2


Thoughts on Rust
----------------
I really like enums with values, I wish every language had them - it's so
nice to be able to elegrantly represent every valid state, while making
invalid states impossible <3

Optional instead of Nullable is a delight after years of working with
languages which are based on Nullables