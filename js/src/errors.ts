export class EmuError extends Error {}

export class UnsupportedCart extends EmuError {}
//    def __init__(self, cart_type):
//        self.cart_type = cart_type

// Controlled exit, ie we are deliberately stopping emulation
export class ControlledExit extends EmuError {}

export class Quit extends ControlledExit {
    constructor() {
        super("User has exited the emulator");
    }
}

export class Timeout extends ControlledExit {
    constructor(frames: number, duration: number) {
        let f = frames.toString().padStart(5, " ");
        let d = duration.toFixed(2).toString().padStart(5, " ");
        let p = (frames / duration).toFixed(2);
        super(`Emulated ${f} frames in ${d}s (${p}fps)`);
    }
}

export class UnitTestPassed extends ControlledExit {
    constructor() {
        super("Unit test passed");
    }
}

export class UnitTestFailed extends ControlledExit {
    constructor() {
        super("Unit test failed");
    }
}

// Game error, ie the game developer has a bug
export class GameException extends EmuError {}

export class InvalidOpcode extends GameException {
    constructor(opcode: u8) {
        super(`Invalid opcode ${opcode}`);
    }
}

export class InvalidRamRead extends GameException {}
//    def __init__(self, ram_bank, offset, ram_size):
//        self.ram_bank = ram_bank
//        self.offset = offset
//        self.ram_size = ram_size
//        return f"Read from RAM bank {self.ram_bank} offset {self.offset} >= ram size {self.ram_size}"

export class InvalidRamWrite extends GameException {}
//    def __init__(self, ram_bank, offset, ram_size):
//        return f"Write to RAM bank {self.ram_bank} offset {self.offset} >= ram size {self.ram_size}"

// User error, ie the user gave us an ivalid or corrupt input file
export class UserException extends EmuError {}

export class RomMissing extends UserException {
    constructor(rom: string, error: Error) {
        super(`Error opening ${rom}: ${error}`);
    }
}

export class LogoChecksumFailed extends UserException {
    constructor(logo_checksum: u16) {
        super(`Logo checksum failed: ${logo_checksum} != 5446`);
    }
}

export class HeaderChecksumFailed extends UserException {
    constructor(header_checksum: u8) {
        super(`Header checksum failed: ${header_checksum} != 0`);
    }
}
