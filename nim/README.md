RosettaBoy - Nim Edition
========================



Thoughts on Nim
===============
For the most part, it seems ok.

Argument parsing
----------------
Unless I'm missing something, command line parsing is really bad. Like
I'd be tempted to do it myself, but the documentation for the command
line parser doesn't even include an example of parsing the command line,
it only includes examples of how to parse hard-coded strings...

I think I'm supposed to take all of the parameters from the command line
one at a time, concatenate them into one string, and then pass that to
the command line parsing library? Is that what you want??

After a couple of hours of trying to make this work, I'm giving up and
using a third party library... update: the third party library also
doesn't seem to work, and doesn't include any examples of how to use it
with actual command line input either. (https://github.com/iffy/nim-argparse)

At this point I gave up and tried to ask on the nim forums, but I can't
post until I confirm my email address, and the email they sent to confirm
my address never reached me :|

Looks like somebody else created yet another arg parsing library:
https://forum.nim-lang.org/t/6376 - Let's see what they say about using
their library, maybe I can get some hints there:

```
# `args` and `command` would normally be picked up from the commandline
```

No shit! Yes, of course, I would want to use this command line parsing
library to parse a command line. HOW DO I DO THAT???

Const
-----
Apparently many of the random ungooglable errors I hit while trying to
make arg parsing work were because I did `const args = parse_args()`,
thinking that args is something which will never change once defined.
Apparently in this case `const` means "compile-time constant", which
is a pretty neat feature, but it makes everything break in weird ways
when you aren't expecting it.

Bit-mangling
------------
Having bitops as a library of functions rather than using punctuation like
`&` for `binary AND` actually makes a lot of sense, even if it's kind of
painful for a binary-operation-heavy use-case like an emulator...

Formatting
----------
Mostly, I love having One True Formatting Tool. But then I ran nimpretty
on my code...

```
$ cat test.nim
if true:
  if true:
# what
    echo "hello world"

$ nim r test.nim
hello world

$ nimpretty test.nim

$ nim r test.nim
test.nim(5, 3) Error: invalid indentation
```