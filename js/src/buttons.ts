import sdl from "@kmamal/sdl";

import { CPU } from "./cpu";
import { Quit } from "./errors";
import { Interrupt, Mem } from "./consts";

enum Joypad {
    MODE_BUTTONS = 1 << 5,
    MODE_DPAD = 1 << 4,
    DOWN = 1 << 3,
    START = 1 << 3,
    UP = 1 << 2,
    SELECT = 1 << 2,
    LEFT = 1 << 1,
    B = 1 << 1,
    RIGHT = 1 << 0,
    A = 1 << 0,
}

export class Buttons {
    cpu: CPU;
    turbo: boolean;
    cycle: number;
    up: boolean;
    down: boolean;
    left: boolean;
    right: boolean;
    a: boolean;
    b: boolean;
    start: boolean;
    select: boolean;

    constructor(cpu: CPU, window: sdl.Sdl.Video.Window | null) {
        this.cpu = cpu;
        this.turbo = false;
        this.cycle = 0;
        this.up = false;
        this.down = false;
        this.left = false;
        this.right = false;
        this.a = false;
        this.b = false;
        this.start = false;
        this.select = false;

        if (window) {
            window.on("keyDown", this.onKeyDown);
            window.on("keyUp", this.onKeyUp);
            window.on("close", this.onClose);
        }
    }

    tick() {
        // FIXME: handle inputs
        this.cycle += 1;
        this.update_buttons();
    }

    update_buttons() {
        let JOYP = ~this.cpu.ram.get(Mem.JOYP);
        JOYP &= 0x30;
        if (JOYP & Joypad.MODE_DPAD) {
            if (this.up) JOYP |= Joypad.UP;
            if (this.down) JOYP |= Joypad.DOWN;
            if (this.left) JOYP |= Joypad.LEFT;
            if (this.right) JOYP |= Joypad.RIGHT;
        }
        if (JOYP & Joypad.MODE_BUTTONS) {
            if (this.b) JOYP |= Joypad.B;
            if (this.a) JOYP |= Joypad.A;
            if (this.start) JOYP |= Joypad.START;
            if (this.select) JOYP |= Joypad.SELECT;
        }
        this.cpu.ram.set(Mem.JOYP, ~JOYP & 0x3f);
    }

    onClose() {
        throw new Quit();
    }

    onKeyDown(event: sdl.Events.Window.KeyDown) {
        let need_interrupt = true;
        switch (event.key) {
            case "escape":
                throw new Quit();
            case "shift":
                this.turbo = true;
                need_interrupt = false;
                break;
            case "up":
                this.up = true;
                break;
            case "down":
                this.down = true;
                break;
            case "left":
                this.left = true;
                break;
            case "right":
                this.right = true;
                break;
            case "z":
                this.b = true;
                break;
            case "x":
                this.a = true;
                break;
            case "\n":
                this.start = true;
                break;
            case " ":
                this.select = true;
                break;
            default:
                need_interrupt = false;
                break;
        }
        if (need_interrupt) {
            this.cpu.stop = false;
            this.cpu.interrupt(Interrupt.JOYPAD);
        }
    }

    onKeyUp(event: sdl.Events.Window.KeyUp) {
        switch (event.key) {
            case "shift":
                this.turbo = false;
                break;
            case "up":
                this.up = false;
                break;
            case "down":
                this.down = false;
                break;
            case "left":
                this.left = false;
                break;
            case "right":
                this.right = false;
                break;
            case "z":
                this.b = false;
                break;
            case "x":
                this.a = false;
                break;
            case "\n":
                this.start = false;
                break;
            case " ":
                this.select = false;
                break;
        }
    }
}
