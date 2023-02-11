#!/usr/bin/env node

/// <reference path='./index.d.ts'/>
//import sdl from '@kmamal/sdl'

import { parse_args } from "./args";
import { GameBoy } from "./gameboy";
import {
    GameException,
    UserException,
    ControlledExit,
    UnitTestFailed,
} from "./errors";

async function main(): Promise<number> {
    let args = parse_args(process.argv);

    try {
        let gameboy = new GameBoy(args);
        await gameboy.run();
    } catch (e) {
        if (e instanceof ControlledExit) {
            console.log(e.message);
            if (e instanceof UnitTestFailed) {
                return 2;
            }
            return 0;
        } else if (e instanceof GameException) {
            console.log(e);
            return 3;
        } else if (e instanceof UserException) {
            console.log(e);
            return 4;
        } else {
            console.log("Surprise error");
            console.log(e);
            return 1;
        }
    } finally {
        // FIXME: sdl.SDL_Quit()
    }
    return 0;
}

main().then((code) => process.exit(code));
