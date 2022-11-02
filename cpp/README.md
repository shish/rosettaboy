RosettaBoy C++
==============
A GameBoy emulator, a simple project to see what C++ is like these days

Usage
-----
```
cmake -DCMAKE_BUILD_TYPE=Release .  # or Debug
make -j
./rosettaboy-cpp game.gb
```

(`BUILD_TYPE=Release` if you want it to be faster and less debuggable)

Requirements
------------
- SDL2

Formatting
----------
Automated with clang-format:
```
clang-format $(find src -type f | grep -v args.h) -i
```

Thoughts on C++
---------------
String formating is SUCH PAIN.

I want to do:
```
blah = format("%04X", 1234)
```
but apparently I need to do:
```
template< typename T >
std::string int_to_hex( T i )
{
  std::stringstream stream;
  stream << std::setfill('0') << std::setw(sizeof(T)*2) << std::hex << i;
  return stream.str();
}
```
and that doesn't even work right -_-

For now I'm just using the plain C formatting functions...