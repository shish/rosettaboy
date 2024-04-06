import { HeaderChecksumFailed, LogoChecksumFailed } from "./errors";

var fs = require("fs");

enum CartType {
    RomOnly = 0x00,
    RomMbc1 = 0x01,
    RomMbc1Ram = 0x02,
    RomMbc1RamBatt = 0x03,
    RomMbc2 = 0x05,
    RomMbc2Batt = 0x06,
    RomRam = 0x08,
    RomRamBatt = 0x09,
    RomMmm01 = 0x0b,
    RomMmm01Sram = 0x0c,
    RomMmm01SramBatt = 0x0d,
    RomMbc3TimerBatt = 0x0f,
    RomMbc3TimerRamBatt = 0x10,
    RomMbc3 = 0x11,
    RomMbc3Ram = 0x12,
    RomMbc3RamBatt = 0x13,
    RomMbc5 = 0x19,
    RomMbc5Ram = 0x1a,
    RomMbc5RamBatt = 0x1b,
    RomMbc5Rumble = 0x1c,
    RomMbc5RumbleRam = 0x1d,
    RomMbc5RumbleRamBatt = 0x1e,
    PocketCamera = 0x1f,
    BandaiTama5 = 0xfd,
    HudsonHuc3 = 0xfe,
    HudsonHuc1 = 0xff,
}

const KB: number = 1024;

function parse_rom_size(val: u8): number {
    return (32 * KB) << val;
}

function parse_ram_size(val: u8): number {
    return (
        {
            0: 0,
            2: 8 * KB,
            3: 32 * KB,
            4: 128 * KB,
            5: 64 * KB,
        }[val] || 0
    );
}

export class Cart {
    data: Uint8Array;
    ram: Uint8Array;

    logo: Uint8Array;
    name: string;
    is_gbc: boolean;
    licensee: number;
    is_sgb: boolean;
    cart_type: CartType;
    rom_size: number;
    ram_size: number;
    destination: number;
    old_licensee: number;
    rom_version: number;
    complement_check: number;
    checksum: number;

    constructor(rom: string) {
        this.data = new Uint8Array(fs.readFileSync(rom, null));
        this.ram = new Uint8Array(0);

        this.logo = this.data.slice(0x0104, 0x0104 + 48);
        this.name = Buffer.from(this.data.slice(0x0134, 0x0134 + 16))
            .toString()
            .trim();
        this.is_gbc = this.data[0x143] == 0x80; // 0x80 = works on both, 0xC0 = colour only
        this.licensee = (this.data[0x144] << 8) | this.data[0x145];
        this.is_sgb = this.data[0x146] == 0x03;
        this.cart_type = CartType.RomOnly; // FIXME val to enum
        this.rom_size = parse_rom_size(this.data[0x148]);
        this.ram_size = parse_ram_size(this.data[0x149]);
        this.destination = this.data[0x14a];
        this.old_licensee = this.data[0x14b];
        this.rom_version = this.data[0x14c];
        this.complement_check = this.data[0x14d];
        this.checksum = (this.data[0x14e] << 8) | this.data[0x14f];

        var logo_checksum = this.logo.reduce((a, b) => a + b, 0) & 0xffff;
        if (logo_checksum != 5446) {
            throw new LogoChecksumFailed(logo_checksum);
        }

        var header_checksum =
            this.data.slice(0x0134, 0x014e).reduce((a, b) => a + b, 25) & 0xff;
        if (header_checksum != 0) {
            throw new HeaderChecksumFailed(header_checksum);
        }

        if (this.ram_size) {
            // FIXME
        }
    }
}
