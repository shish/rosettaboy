RosettaBoy - Zig Edition
========================

Thoughts on Zig
===============
No strings? T_T

No package manager? T_T

If you want to get details from an error situation, the idiomatic thing
is to pass in a "Diagnostics" object into the function, then if there's
an error, the function will populate the object. U wot m8? This feels
like the worst parts of returning error codes combined with the worst
parts of throwing exceptions, and then somehow even more bad on top...

Also it's pre-1.0 which means people break things regularly, certain
libraries target certain compiler versions with no backward or forward
compatibility so you need to do a git bisect to find a library version
that works with your compiler...

Packed structs seem pretty great though, especially useful for emulators
where there are a lot of bitwise operations.