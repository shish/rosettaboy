import { RAM } from "./ram";

export class APU {
    ram: RAM;
    silent: boolean;
    debug: boolean;

    constructor(ram: RAM, silent: boolean, debug: boolean) {
        this.ram = ram;
        this.silent = silent;
        this.debug = debug;
    }

    tick() {}
}
