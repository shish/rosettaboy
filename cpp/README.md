RosettaBoy C++
==============
A GameBoy emulator, a simple project to see what C++ is like these days

Usage
-----
```
./build.sh
./rosettaboy-release game.gb
```

Requirements
------------
- SDL2

Thoughts on C++
---------------
- String formating is SUCH PAIN.

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

- GCC and Clang can't agree on what a char is (#41)
