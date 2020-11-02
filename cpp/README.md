RosettaBoy C++
==============
A GameBoy emulator, a simple project to see what C++ is like these days

Usage
-----
```
cmake .
make -j 8
./rosettaboy-cpp game.gb
```

Requirements
------------
- SDL2

Completeness
------------
- Passes all of gblargh's CPU test cases :)
- Audio works, but sounds off-key :|
- Backgrounds and sprites are rendered all at once, instead of a line at
  a time :(