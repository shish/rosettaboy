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

Ints of any size are also nice -- compared to eg Rust where we have u8,
and so `match op & 0x07` needs to support all 256 possible values even
if it only has 8, zig lets us say "this is a u3"

No way to iterate over a range? Again: u wot m8?

No nested functions? :(

I really like zig's way of formatting long lists of short strings
(eg the names of CPU instructions at the top of `cpu.zig`) - it renders
them as a table, the same way I would do by hand <3

No string formatting without single compile-time-known format strings?
This is pretty painful because most other implementations print CPU
instructions with their parameters by having an array of CPU instruction
names like `op_names = [..., "LD A,%02X", ...]` and then we do
`printf(op_names[op], op_param);`, but that doesn't work for zig... I do
appreciate that this means there will be no runtime "format string vs
number of parameter mismatch" errors - and Rust actually has the same
thing... but in Rust I can at least have a workaround of doing things like 
`op_names = [..., "LD A,xx", ...]` + `print(op_names[op].replace("xx", op_param));`,
and zig has no string library so no "replace" :(