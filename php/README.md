
PHP arg parsing is a nightmare, so this version only supports short flags
(patches welcome!)

PHP also doesn't seem to have any non-deprecated SDL bindings, so there's
no input or output (patches also welcome!). You can run in CPU-debug mode
to see the instructions as they are executed though, and data-cable output
works so things like gblargh's test roms can print "ok" or "fail".

```
./run.sh -c -S -H -t -p 60 game.gb
```

xdebug is useful, but makes things slow. opcache makes things fast, but is
incompatible with xdebug. To try and get the least-bad thing in each situation:

For running in practice:
```
php8.1 -dopcache.enable_cli=1 -dopcache.jit_buffer_size=100M src/main.php --args
```

VS Code debug configuration:
```json
        {
            "name": "PHP Script",
            "type": "php",
            "request": "launch",
            "program": "${fileDirname}/main.php",
            // "cwd": "${fileDirname}",
            "port": 0,
            "args": ["-t", "-p", "60", "-S", "-H", "../gb-test-roms/cpu_instrs/individual/01-special.gb"],
            "cwd": "${workspaceFolder}/php",
            "console": "integratedTerminal",
            "runtimeArgs": [
                "-z/usr/local/lib/php/pecl/20210902/xdebug.so",
                "-dxdebug.start_with_request=yes"
            ],
            "env": {
                "XDEBUG_MODE": "debug,develop",
                "XDEBUG_CONFIG": "client_port=${port}"
            }
        },
```