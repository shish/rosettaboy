RosettaBoy - JavaScript (TypeScript (Node)) Version
===================================================

Thoughts on JS / TS / Node
--------------------------

On TypeScript vs JavaScript:
* TypeScript seems better in every way, except that it requires a build step :(

On the state of NPM libraries:
* Try one SDL library, it doesn't compile
* Try another SDL library, realise it hasn't been updated in 8 years and doesn't work with current Node
* Try a third SDL library, realise that it makes a lot of assumptions and has its own API that's very different from SDL
* Find some modern, supported, well-behaved libraries... which _exclusively_ cover the audio interface and nothing else
* Give up on SDL libraries, try the FFI library instead to build my own
* Find that there's no official FFI library, so I try the FFI library on NPM
* Find that the FFI library on NPM was abandoned several years ago
* Seems like somebody forked the above to make a stable version and _has_ kept it up to date, so let's try that...
* The up-to-date FFI library links to the abandoned library's docs