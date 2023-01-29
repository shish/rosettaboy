
PHP arg parsing is a nightmare, so this version only supports short flags
(patches welcome!)

```
./build.sh
./rosettaboy-release -c -S -H -t -p 60 game.gb
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
