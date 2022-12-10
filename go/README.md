RosettaBoy - Go Edition
=======================

Usage
-----
```
./build.sh
./rosettaboy-release game.gb
```

Thoughts on Go
==============
- The verbosity of error handling is constantly a minor annoyance,
  `err := foo(); if err != nil { return err }` compared to eg
  Rust's `foo()?`. It's not a _big_ issue, but it is like trying
  to run a marathon with a grain of sand in your shoe...
- Error handling still fails to catch errors - I spent hours trying
  to figure out why nothing was displaying on screen, and it turns
  out that I'd created a buffer but forgotten to assign it to the
  `hw_buffer` variable... and everything was just silently totally
  fine with that variable being `nil`, I could even call methods on
  it with no NullPointerException equivalent. Argh.
- I want to check three things, returning as soon as I find one.
  `check(A) || check(B) || check(C)` works in most languages. Go
  however complains that I need to use the result of this expression.
  Like I get it, the compiler is trying to be helpful... but it's
  being anal about things that don't matter and turning a blind
  eye to real problems -_-