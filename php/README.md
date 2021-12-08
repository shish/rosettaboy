
PHP arg parsing is a nightmare, so this version only supports short flags
(patches welcome!)

PHP also doesn't seem to have any non-deprecated SDL bindings, so there's
no input or output (patches also welcome!). You can run in CPU-debug mode
to see the instructions as they are executed though, and data-cable output
works so things like gblargh's test roms can print "ok" or "fail".

```
./run.sh -c -S -H -t -p 60 game.gb
```
