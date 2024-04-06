import { Buttons } from "./buttons";
import { Timeout } from "./errors";

let sleep = require("util").promisify(setTimeout);

export class Clock {
    buttons: Buttons;
    frames: number;
    profile: number;
    turbo: boolean;

    cycle: number;
    frame: number;
    last_frame_start: number;
    start: number;

    constructor(
        buttons: Buttons,
        frames: number,
        profile: number,
        turbo: boolean,
    ) {
        this.buttons = buttons;
        this.frames = frames;
        this.profile = profile;
        this.turbo = turbo;

        this.cycle = 0;
        this.frame = 0;
        this.last_frame_start = Date.now();
        this.start = Date.now();
    }

    async tick() {
        this.cycle += 1;

        // Do a whole frame's worth of sleeping at the start of each frame
        if (this.cycle % 17556 == 20) {
            // Sleep if we have time left over
            let time_spent = Date.now() - this.last_frame_start;
            let time_per_frame = 1000.0 / 60.0;
            if (
                !this.turbo &&
                !this.buttons.turbo &&
                time_spent < time_per_frame
            ) {
                let sleep_time = time_per_frame - time_spent;
                await sleep(sleep_time);
            }
            this.last_frame_start = Date.now();

            // Exit if we've hit the frame or time limit
            let duration = this.last_frame_start - this.start;
            if (
                (this.frames && this.frame >= this.frames) ||
                (this.profile && duration >= this.profile * 1000)
            ) {
                throw new Timeout(this.frame, duration / 1000);
            }

            this.frame += 1;
        }
    }
}
