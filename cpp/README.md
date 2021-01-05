RosettaBoy C++
==============
A GameBoy emulator, a simple project to see what C++ is like these days

Usage
-----
```
cmake -DCMAKE_BUILD_TYPE=Debug .
make -j
./rosettaboy-cpp game.gb
```

(`BUILD_TYPE=Release` if you want it to be faster and less debuggable)

Requirements
------------
- SDL2
