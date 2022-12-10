import typing as t
import struct
from enum import Enum

from src.consts import u8, u16
from src.errors import LogoChecksumFailed, HeaderChecksumFailed


class CartType(Enum):
    ROM_ONLY: t.Final[u8] = 0x00
    ROM_MBC1: t.Final[u8] = 0x01
    ROM_MBC1_RAM: t.Final[u8] = 0x02
    ROM_MBC1_RAM_BATT: t.Final[u8] = 0x03
    ROM_MBC2: t.Final[u8] = 0x05
    ROM_MBC2_BATT: t.Final[u8] = 0x06
    ROM_RAM: t.Final[u8] = 0x08
    ROM_RAM_BATT: t.Final[u8] = 0x09
    ROM_MMM01: t.Final[u8] = 0x0B
    ROM_MMM01_SRAM: t.Final[u8] = 0x0C
    ROM_MMM01_SRAM_BATT: t.Final[u8] = 0x0D
    ROM_MBC3_TIMER_BATT: t.Final[u8] = 0x0F
    ROM_MBC3_TIMER_RAM_BATT: t.Final[u8] = 0x10
    ROM_MBC3: t.Final[u8] = 0x11
    ROM_MBC3_RAM: t.Final[u8] = 0x12
    ROM_MBC3_RAM_BATT: t.Final[u8] = 0x13
    ROM_MBC5: t.Final[u8] = 0x19
    ROM_MBC5_RAM: t.Final[u8] = 0x1A
    ROM_MBC5_RAM_BATT: t.Final[u8] = 0x1B
    ROM_MBC5_RUMBLE: t.Final[u8] = 0x1C
    ROM_MBC5_RUMBLE_RAM: t.Final[u8] = 0x1D
    ROM_MBC5_RUMBLE_RAM_BATT: t.Final[u8] = 0x1E
    POCKET_CAMERA: t.Final[u8] = 0x1F
    BANDAI_TAMA5: t.Final[u8] = 0xFD
    HUDSON_HUC3: t.Final[u8] = 0xFE
    HUDSON_HUC1: t.Final[u8] = 0xFF


KB: int = 1024


def parse_rom_size(val: u8) -> int:
    return (32 * KB) << val


def parse_ram_size(val: u8) -> int:
    return {
        0: 0,
        2: 8 * KB,
        3: 32 * KB,
        4: 128 * KB,
        5: 64 * KB,
    }.get(val, 0)


class Cart:
    def __init__(self, rom: str) -> None:
        with open(rom, "rb") as fp:
            self.data = fp.read()
            data = self.data

        self.logo = data[0x104 : 0x104 + 48]
        self.name = data[0x134 : 0x134 + 15].decode("ascii").strip()

        self.is_gbc = data[0x143] == 0x80  # 0x80 = works on both, 0xC0 = colour only
        self.licensee: u16 = data[0x144] << 8 | data[0x145]
        self.is_sgb = data[0x146] == 0x03
        self.cart_type = CartType(data[0x147])
        self.rom_size = parse_rom_size(data[0x148])
        self.ram_size = parse_ram_size(data[0x149])
        self.destination = data[0x14A]
        self.old_licensee = data[0x14B]
        self.rom_version = data[0x14C]
        self.complement_check = data[0x14D]
        self.checksum: u16 = data[0x14E] << 8 | data[0x14F]

        self.ram = [0] * self.ram_size

        logo_checksum = sum(list(self.logo))
        if logo_checksum != 5446:
            raise LogoChecksumFailed(logo_checksum)

        header_checksum = (
            sum(struct.unpack("26B", self.data[0x0134:0x014E])) + 25
        ) & 0xFF
        if header_checksum != 0:
            raise HeaderChecksumFailed(header_checksum)

    def __str__(self) -> str:
        return "\n".join(
            [
                f"{k}: {v}"
                for k, v in self.__dict__.items()
                if k not in {"data", "logo", "init", "rsts"}
            ]
        )
