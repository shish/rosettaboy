RosettaBoy
==========
Trying to implement a gameboy emulator in a bunch of languages for my own
amusement and education; also giving people an opportunity to compare the
same code written in different languages, similar to
[Rosetta Code](https://www.rosettacode.org) but with a non-trivial codebase :)

The main goals are:

- Readability of the code
- Consistency across langauges
- Idiomatic use of language features
- Basic playability

Notably, 100% accuracy is not a goal - if Tetris works perfectly then I'm
happy, if other games require more obscure hardware features, then I'll
weigh up whether or not the feature is worth the complexity.

Also yes, "consistent across languages" and "idiomatic" can be at odds -
there are subjective compromises to be made, but for the most part that
doesn't seem to be a huge problem. Rust uses `Result`, Python uses
`Exception`, Go uses `error` - but so far it's always been pretty obvious
that eg `NewCart()` in go and `Cart::new()` in rust are doing fundamentally
the same thing in the same way.

So far all the implementations follow a fairly standard layout, with each
module teaching me how to do a new thing. In fact they're all so similar,
I wrote one copy of the documentation for all the implementations:

- [main](docs/main.md): exception handling
- [args](docs/args.md): argument parsing
- [cpu](docs/cpu.md): CPU emulation
- [gpu](docs/gpu.md): graphical processing
- [apu](docs/apu.md): audio processing
- [buttons](docs/buttons.md): user input
- [cart](docs/cart.md): binary file I/O and parsing
- [clock](docs/clock.md): timing / sleeping
- [consts](docs/consts.md): lists of constant values
- [errors](docs/errors.md): standard errors / exceptions / etc
- [ram](docs/ram.md): array access where some array values are special

Pull requests to translate into new languages, or fleshing out existing
languages, are very welcome :)


Dev Guide
---------
I want to keep the build processes as simple as possible - it should be
possible to `cd` into the directory for any implementation and then `./run.sh`
should build (if necessary) and run the code. Ideally the run script should
also fetch-if-needed any dependencies, the only assumption I want to make is
that the user has the standard language dev kits installed (eg we assume
anyone who wants to work on the Rust version will have Cargo installed;
anyone who wants to work on Python will have virtualenv + pip; etc)

If you have a shell with docker installed, you can run `./utils/shell.sh`
to create and run a docker container with all the necessary dev tools
pre-installed -- `./run.sh --headless --silent` should be able to pass
tests for all languages.


Benchmarks
----------
**Warning**: These implementations aren't 100% in-sync, so take numbers with
a large grain of salt. For example, as of this writing, the PHP version is
using a stub SDL mock instead of calling the real C library, because I couldn't
find an SDL library that worked.

If somebody knows how to measure CPU instructions instead of clock time, that
seems fairer; especially if we can get the measurement included automatically
via github actions. Pull requests welcome :)

Running on an M1 Macbook Pro, using (to my knowledge) the latest version of
each compiler, with standard "release mode" flags (see each language's run.sh
for exactly which flags are used):

```
$ ./utils/bench.py
  zig / release: Emulated 28799 frames in 10.00s (2880fps)
   rs / lto    : Emulated 20371 frames in 10.00s (2037fps)
   rs / release: Emulated 16950 frames in 10.00s (1695fps)
  cpp / release: Emulated 15397 frames in 10.00s (1540fps)
  nim / speed  : Emulated 14241 frames in 10.00s (1424fps)
  nim / release: Emulated 14193 frames in 10.00s (1419fps)
   go / release: Emulated  5973 frames in 10.00s (597fps)
  php / release: Emulated   497 frames in 10.01s (50fps)
  zig / safe   : Emulated   228 frames in 10.00s (23fps)
   py / release: Emulated   181 frames in 10.00s (18fps)
   py / mypyc  : Emulated   179 frames in 10.01s (18fps)
```

Also if you spot some bit of code that is weirdly slow and making your favourite
language look bad, pull requests to fix that _might_ be welcome too, but "simplicity
and consistency" are going to take priority (eg an "add an `inline` flag to this
function" would be great but "replace python's CPU interpreter with a JIT compiler
written as a C extension module" would probably be rejected[0])

[0] That said if somebody wanted to come up with a separate "python but all the slow
parts are replaced with C modules like they would be in a real app" implementation,
that could be interesting...
