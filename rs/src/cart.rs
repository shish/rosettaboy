use crate::consts;
use std::convert::TryFrom;
use std::fs::File;
use std::io;
use std::io::Read;

pub struct Cart {
    pub data: Vec<u8>,
    pub ram: Vec<u8>,

    // u8 rsts[0x100];
    // u8 init[0x4];
    pub logo: [u8; 48],
    pub name: String,
    pub is_gbc: bool,
    pub licensee: u16,
    pub is_sgb: bool,
    pub cart_type: consts::CartType,
    pub rom_size: u32,
    pub ram_size: u32,
    pub destination: consts::Destination,
    pub old_licensee: consts::OldLicensee,
    pub rom_version: u8,
    pub complement_check: u8,
    pub checksum: u16,
}

const KB: u32 = 1024;
const MB: u32 = 1024 * 1024;

fn parse_rom_size(val: u8) -> u32 {
    match val {
        0 => 32 * KB,
        1 => 64 * KB,
        2 => 128 * KB,
        3 => 256 * KB,
        4 => 512 * KB,
        5 => 1 * MB,
        6 => 2 * MB,
        7 => 4 * MB,
        8 => 8 * MB,
        0x52 => 1 * MB + 128 * KB,
        0x53 => 1 * MB + 256 * KB,
        0x54 => 1 * MB + 512 * KB,
        _ => 0,
    }
}

fn parse_ram_size(val: u8) -> u32 {
    match val {
        0 => 0,
        1 => 2 * KB,
        2 => 8 * KB,
        3 => 32 * KB,
        4 => 128 * KB,
        5 => 64 * KB,
        _ => 0,
    }
}

impl Cart {
    pub fn init(filename: &str) -> Result<Cart, io::Error> {
        let mut fp = File::open(filename)?;
        let mut data: Vec<u8> = Vec::new();
        fp.read_to_end(&mut data)?;

        let mut logo: [u8; 48] = [0; 48];
        logo.copy_from_slice(&data[0x104..0x104 + 48]);
        let mut name_bytes: [u8; 15] = [0; 15];
        name_bytes.copy_from_slice(&data[0x134..0x134 + 15]);
        let name = std::str::from_utf8(&name_bytes)
            .unwrap()
            .trim_matches(char::from(0))
            .to_string();

        let is_gbc = data[0x143] == 0x80; // 0x80 = works on both, 0xC0 = colour only
        let licensee: u16 = (data[0x144] as u16) << 8 | (data[0x145] as u16);
        let is_sgb = data[0x146] == 0x03;
        let cart_type = consts::CartType::try_from(data[0x147]).unwrap();
        let rom_size = parse_rom_size(data[0x148]);
        let ram_size = parse_ram_size(data[0x149]);
        let destination = consts::Destination::try_from(data[0x14A]).unwrap();
        let old_licensee = consts::OldLicensee::try_from(data[0x14B]).unwrap();
        let rom_version = data[0x14C];
        let complement_check = data[0x14D];
        let checksum: u16 = (data[0x14E] as u16) << 8 | (data[0x14F] as u16);

        let mut logo_checksum: u16 = 0;
        for i in logo.iter() {
            logo_checksum += *i as u16;
        }
        if logo_checksum != 5446 {
            panic!("Logo checksum failed\n")
        }

        let mut header_checksum: u16 = 25;
        for i in 0x0134..0x014E {
            header_checksum += data[i] as u16;
        }
        if (header_checksum & 0xFF) != 0 {
            panic!("Header checksum failed\n")
        }

        //if cart_type != consts::CartType::RomOnly {
        //    panic!("Only RomOnly cartridges are supported, got {:?}", cart_type);
        //}

        // FIXME: ram should be synced with .sav file
        let ram = vec![0; ram_size as usize];

        let debug = false;
        if debug {
            println!(
                "name         : {:<16} rom_version  : {:<16}",
                name, rom_version
            );
            println!(
                "is_gbc       : {:<16} is_sgb       : {:<16}",
                is_gbc, is_sgb
            );
            println!(
                "licensee     : {:<16} old_licensee : {:16?}",
                licensee, old_licensee
            );
            println!(
                "destination  : {:<16} cart_type    : {:16?}",
                format!("{:?}", destination),
                cart_type
            );
            println!(
                "rom_size     : {:<16} ram_size     : {:<16}",
                rom_size, ram_size
            );
            println!(
                "ccheck       : {:<16} checksum     : {:<16}",
                complement_check, checksum
            );
        }

        Ok(Cart {
            data,
            ram,

            logo,
            name,
            is_gbc,
            licensee,
            is_sgb,
            cart_type,
            rom_size,
            ram_size,
            destination,
            old_licensee,
            rom_version,
            complement_check,
            checksum,
        })
    }
}
