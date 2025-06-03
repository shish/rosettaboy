const std = @import("std");
const fs = std.fs;

const errors = @import("errors.zig");

const KB: u32 = 1024;

fn parse_rom_size(val: u8) u32 {
    return (32 * KB) << @as(u5, @intCast(val));
}

fn parse_ram_size(val: u8) u32 {
    return switch (val) {
        0 => 0,
        2 => 8 * KB,
        3 => 32 * KB,
        4 => 128 * KB,
        5 => 64 * KB,
        else => 0,
    };
}

pub const Cart = struct {
    data: []const u8,
    ram: []u8,

    logo: []u8,
    name: []const u8,
    is_gbc: bool,
    licensee: u16,
    is_sgb: bool,
    cart_type: u8, // ?
    rom_size: u32,
    ram_size: u32,
    destination: u8,
    old_licensee: u8,
    rom_version: u8,
    complement_check: u8,
    checksum: u16,

    pub fn new(fname: []const u8) !Cart {
        var f = try fs.cwd().openFile(fname, fs.File.OpenFlags{ .mode = .read_only });
        defer f.close();

        const allocator = std.heap.page_allocator;
        var data = try allocator.alloc(u8, (try f.stat()).size);
        _ = try f.read(data[0..]);

        const logo: *[48]u8 = data[0x104 .. 0x104 + 48];
        const name: *[15]u8 = data[0x134 .. 0x134 + 15];

        const is_gbc = data[0x143] == 0x80; // 0x80 = works on both, 0xC0 = colour only
        const licensee: u16 = @as(u16, @intCast(data[0x144])) << 8 | @as(u16, @intCast(data[0x145]));
        const is_sgb = data[0x146] == 0x03;
        const cart_type = data[0x147];
        const rom_size = parse_rom_size(data[0x148]);
        const ram_size = parse_ram_size(data[0x149]);
        const destination = data[0x14A];
        const old_licensee = data[0x14B];
        const rom_version = data[0x14C];
        const complement_check = data[0x14D];
        const checksum: u16 = @as(u16, @intCast(data[0x14E])) << 8 | @as(u16, @intCast(data[0x14F]));

        var logo_checksum: u16 = 0;
        for (logo) |i| {
            logo_checksum += i;
        }
        if (logo_checksum != 5446) {
            return errors.UserException.LogoChecksumFailed;
        }

        var header_checksum: u16 = 25;
        for (data[0x0134..0x014E]) |i| {
            header_checksum += i;
        }
        if ((header_checksum & 0xFF) != 0) {
            return errors.UserException.HeaderChecksumFailed;
        }

        // FIXME
        //if(cart_type != CartType::RomOnly && cart_type != CartType::RomMbc1) {
        //    return Err(anyhow!(UserException::UnsupportedCart(cart_type)));
        //}

        // FIXME: ram should be synced with .sav file
        const ram = try allocator.alloc(u8, ram_size);

        return Cart{
            .data = data,
            .ram = ram,
            .logo = logo,
            .name = name,
            .is_gbc = is_gbc,
            .licensee = licensee,
            .is_sgb = is_sgb,
            .cart_type = cart_type,
            .rom_size = rom_size,
            .ram_size = ram_size,
            .destination = destination,
            .old_licensee = old_licensee,
            .rom_version = rom_version,
            .complement_check = complement_check,
            .checksum = checksum,
        };
    }
};
