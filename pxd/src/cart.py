import typing as t
import struct
from enum import Enum

from .consts import u8
from .errors import LogoChecksumFailed, HeaderChecksumFailed


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

        self.rsts: bytes
        self.init: t.Tuple[int]
        self.logo: t.Tuple[int]
        self.name: str
        self.is_gbc: bool
        self.licensee: int
        self.is_sgb: bool
        self.cart_type: CartType
        self.rom_size: int
        self.ram_size: int
        self.destination: int
        self.old_licensee: int
        self.rom_version: int
        self.complement_check: int
        self.checksum: int

        fmts: t.List[t.Tuple[str, str, t.Optional[t.Callable[[t.Any], t.Any]]]] = [
            ("256s", "rsts", None),
            ("4B", "init", None),
            ("48B", "logo", None),
            ("15s", "name", lambda x: x.strip(b"\x00").decode()),
            ("B", "is_gbc", lambda x: x == 0x80),
            ("H", "licensee", None),
            ("B", "is_sgb", lambda x: x == 0x03),
            ("B", "cart_type", lambda x: CartType(x)),
            ("B", "rom_size", lambda x: parse_rom_size(x)),
            ("B", "ram_size", lambda x: parse_ram_size(x)),
            ("B", "destination", None),
            ("B", "old_licensee", None),
            ("B", "rom_version", None),
            ("B", "complement_check", None),
            # Checksum (higher byte first) produced by
            # adding all bytes of a cartridge except for
            # two checksum bytes and taking two lower
            # bytes of the result. (GameBoy ignores this
            # value.)
            (">H", "checksum", None),
        ]
        offset: int = 0
        for fmt, name, mod in fmts:
            val = struct.unpack_from(fmt, self.data, offset)
            offset += struct.calcsize(fmt)
            if len(val) == 1:
                val = val[0]
            if mod:
                val = mod(val)
            setattr(self, name, val)

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
