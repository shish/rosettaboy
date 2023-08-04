RosettaBoy - Zig Edition
========================

Ideally, clone recursively:

```
$ git clone https://github.com/shish/rosettaboy --recursive
```

Or retroactively:

```
$ git submodule update --recursive
```

And to update submodules because the build.zig API changed again:

```
cd lib/sdl
git pull
git checkout master
cd ../clap
git pull
git checkout master
cd ../../
git commit -a -m "bump dependencies"
```

Usage
-----
```
./build.sh
./rosettaboy-release game.gb
```

Thoughts on Zig
===============
- It's pre-1.0 which means people break things regularly, certain
  libraries target certain compiler versions with no backward or forward
  compatibility so you need to do a git bisect to find a library version
  that works with your compiler... Also stackoverflow answers from a
  couple of years ago are syntactically invalid now :( On the plus side,
  the new syntax does seem to be better, and I can't blame them too much
  for making breaking changes for good reasons pre-1.0.

- Also the compiler itself has issues - I managed to crash the stable
  compiler with some seemingly-simple code, so I switched to nightly, and
  then nightly was generating binaries that would crash at runtime.
  - There was a patch written to fix my issue a couple of hours after I
    reported it though, so I'm very happy with the speed of improvements :D
  - I had another bug which I hadn't yet managed to narrow down into a small
    test-case, so I hadn't even reported it upstream - but the day after
    complaining on Hacker News, the lead developer of Zig reached out and
    sent a PR with workarounds, which takes the crown for "most positive
    community interaction" I've had with any language ever :)

- No string library? I'm making a character uppercase by fiddling with
  the binary ASCII value... T_T

- No package manager? T_T (It seems there are multiple different
  third-party package managers, and the packages that I wanted to use
  aren't available in either of them?)
  - Looks like a first-party package manager is on the roadmap for
    "after the core language is more stable"

- If you want to get details from an error situation, the idiomatic thing
  is to pass in a "Diagnostics" object into the function, then if there's
  an error, the function will populate the object. U wot m8? This feels
  like the worst parts of returning error codes combined with the worst
  parts of throwing exceptions, and then somehow even more bad on top...
  For now I'm doing some hacky workarounds, eg where most languages would
  do `raise Timeout(time_elapsed, frames_emulated)` and then the
  error-handler in `main()` can print out the FPS if it so chooses, this
  implementation does the printing-to-stdout in the clock library. If I'm
  missing something and there are more elegant ways to do this, pull
  requests would be welcome :)

- Packed structs seem pretty great, especially useful for emulators where
  there are a lot of bitwise operations.

- Ints of any size are also nice -- compared to eg Rust where we have u8,
  and so `match op & 0x07` needs to support all 256 possible values even
  if it only has 8, zig lets us say "this is a u3" and then write a switch
  statement which exhaustively covers all 8 options - no need to have a
  useless `default` branch pointing to an "unreachable" marker.

- The combination of packed structs + any-size-ints make a lot of
  bit-twiddling code _really_ beautiful and simple, which is a huge mess
  of AND / NOT / XOR with masks in other languages. If there is anything
  other languages could copy from Zig, I think this would be my choice.

- No way to iterate over a range? Simple `for` loops are so painful T_T
  - Looks like this is coming in the next language update \o/

- No nested functions? :(

- I really like `zig format`'s way of formatting long lists of short strings
  (eg the names of CPU instructions at the top of `cpu.zig`) - it renders
  them as a table, the same way I would do by hand <3

- No string formatting without single compile-time-known format strings?
  This is pretty painful because most other implementations print CPU
  instructions with their parameters by having an array of CPU instruction
  names like `op_names = [..., "LD A,%02X", ...]` and then we do
  `printf(op_names[op], op_param);`, but that doesn't work for zig... I do
  appreciate that this means there will be no runtime "format string vs
  number of parameter mismatch" errors - and Rust actually has the same
  thing. The same workaround applies though, `op_names = [..., "LD A,u16", ...]` +
  `print(op_names[op].replace("u16", op_param));` (after I eventually found
  the `replace` function in the `mem` library)

- Log-levels per module are set by... defining a global variable in the
  main module? Fixed at compile-time?? This does avoid the release binary
  even containing the code for debug logs. I guess that's great if you never
  want to implement a `--verbose` flag?

- Functions which work fine in 0.10.0.X cause a fatal deprecation error
  in 0.10.0.Y x__x

- When it's not randomly segfaulting due to compiler bugs, Zig is _really_
  fast, almost twice as fast as C++ and Rust for this use-case; I have no
  idea how it manages that. The zig implementation is still missing a
  couple of bits, like the audio processor implementation - but I can't
  think of anything that would have any significant effect on performance.
