use crate::errors::EmuError;
use anyhow::{anyhow, Result};
use num_enum::TryFromPrimitive;
use std::fs::File;
use std::io::Read;

#[repr(u8)]
#[derive(Debug, Eq, PartialEq, TryFromPrimitive)]
pub enum CartType {
    RomOnly = 0x00,
    RomMbc1 = 0x01,
    RomMbc1Ram = 0x02,
    RomMbc1RamBatt = 0x03,
    RomMbc2 = 0x05,
    RomMbc2Batt = 0x06,
    RomRam = 0x08,
    RomRamBatt = 0x09,
    RomMmm01 = 0x0B,
    RomMmm01Sram = 0x0C,
    RomMmm01SramBatt = 0x0D,
    RomMbc3TimerBatt = 0x0F,
    RomMbc3TimerRamBatt = 0x10,
    RomMbc3 = 0x11,
    RomMbc3Ram = 0x12,
    RomMbc3RamBatt = 0x13,
    RomMbc5 = 0x19,
    RomMbc5Ram = 0x1A,
    RomMbc5RamBatt = 0x1B,
    RomMbc5Rumble = 0x1C,
    RomMbc5RumbleRam = 0x1D,
    RomMbc5RumbleRamBatt = 0x1E,
    PocketCamera = 0x1F,
    BandaiTama5 = 0xFD,
    HudsonHuc3 = 0xFE,
    HudsonHuc1 = 0xFF,
}

pub struct Cart {
    pub data: Vec<u8>,
    pub ram: Vec<u8>,

    pub logo: [u8; 48],
    pub name: String,
    pub is_gbc: bool,
    pub licensee: u16,
    pub is_sgb: bool,
    pub cart_type: CartType,
    pub rom_size: u32,
    pub ram_size: u32,
    pub destination: u8,
    pub old_licensee: u8,
    pub rom_version: u8,
    pub complement_check: u8,
    pub checksum: u16,
}

const KB: u32 = 1024;

fn parse_rom_size(val: u8) -> u32 {
    (32 * KB) << val
}

fn parse_ram_size(val: u8) -> u32 {
    match val {
        0 => 0,
        2 => 8 * KB,
        3 => 32 * KB,
        4 => 128 * KB,
        5 => 64 * KB,
        _ => 0,
    }
}

impl Cart {
    pub fn new(filename: &str) -> Result<Cart> {
        let mut fp = File::open(filename)?;
        let mut data: Vec<u8> = Vec::new();
        fp.read_to_end(&mut data)?;

        let mut logo: [u8; 48] = [0; 48];
        logo.copy_from_slice(&data[0x104..0x104 + 48]);
        let mut name_bytes: [u8; 15] = [0; 15];
        name_bytes.copy_from_slice(&data[0x134..0x134 + 15]);
        let name = std::str::from_utf8(&name_bytes)?
            .trim_matches(char::from(0))
            .to_string();

        let is_gbc = data[0x143] == 0x80; // 0x80 = works on both, 0xC0 = colour only
        let licensee: u16 = (data[0x144] as u16) << 8 | (data[0x145] as u16);
        let is_sgb = data[0x146] == 0x03;
        let cart_type = CartType::try_from(data[0x147])?;
        let rom_size = parse_rom_size(data[0x148]);
        let ram_size = parse_ram_size(data[0x149]);
        let destination = data[0x14A];
        let old_licensee = data[0x14B];
        let rom_version = data[0x14C];
        let complement_check = data[0x14D];
        let checksum: u16 = (data[0x14E] as u16) << 8 | (data[0x14F] as u16);

        let mut logo_checksum: u16 = 0;
        for i in logo.iter() {
            logo_checksum += *i as u16;
        }
        if logo_checksum != 5446 {
            return Err(anyhow!(EmuError::LogoChecksumFailed(logo_checksum)));
        }

        let mut header_checksum: u16 = 25;
        for i in data[0x0134..0x014E].iter() {
            header_checksum += *i as u16;
        }
        if (header_checksum & 0xFF) != 0 {
            return Err(anyhow!(EmuError::HeaderChecksumFailed(header_checksum)));
        }

        if cart_type != CartType::RomOnly && cart_type != CartType::RomMbc1 {
            return Err(anyhow!(EmuError::UnsupportedCart(cart_type)));
        }

        // FIXME: ram should be synced with .sav file
        let ram = vec![0; ram_size as usize];

        tracing::debug!(
            "name         : {:<16} rom_version  : {:<16}",
            name,
            rom_version
        );
        tracing::debug!(
            "is_gbc       : {:<16} is_sgb       : {:<16}",
            is_gbc,
            is_sgb
        );
        tracing::debug!(
            "licensee     : {:<16} old_licensee : {:16?}",
            licensee,
            old_licensee
        );
        tracing::debug!(
            "destination  : {:<16} cart_type    : {:16?}",
            format!("{:?}", destination),
            cart_type
        );
        tracing::debug!(
            "rom_size     : {:<16} ram_size     : {:<16}",
            rom_size,
            ram_size
        );
        tracing::debug!(
            "ccheck       : {:<16} checksum     : {:<16}",
            complement_check,
            checksum
        );

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
