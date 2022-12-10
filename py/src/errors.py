import typing as t
from src.consts import u8


class EmuError(Exception):
    pass


class UnsupportedCart(EmuError):
    def __init__(self, cart_type: t.Any) -> None:
        self.cart_type = cart_type


# Controlled exit, ie we are deliberately stopping emulation
class ControlledExit(EmuError):
    """Inheriting from EmuError"""


class Quit(ControlledExit):
    def __str__(self) -> str:
        return "User has exited the emulator"


class Timeout(ControlledExit):
    def __init__(self, frames: int, duration: float) -> None:
        self.frames = frames
        self.duration = duration

    def __str__(self) -> str:
        return "Emulated %5d frames in %5.2fs (%.0ffps)" % (
            self.frames,
            self.duration,
            self.frames / self.duration,
        )


class UnitTestPassed(ControlledExit):
    def __str__(self) -> str:
        return "Unit test passed"


class UnitTestFailed(ControlledExit):
    def __str__(self) -> str:
        return "Unit test failed"


# Game error, ie the game developer has a bug
class GameException(EmuError):
    """Inheriting from EmuError"""


class InvalidOpcode(GameException):
    def __init__(self, opcode: u8) -> None:
        self.opcode = opcode

    def __str__(self) -> str:
        return f"Invalid opcode {self.opcode}"


class InvalidRamRead(GameException):
    def __init__(self, ram_bank: int, offset: int, ram_size: int) -> None:
        self.ram_bank = ram_bank
        self.offset = offset
        self.ram_size = ram_size

    def __str__(self) -> str:
        return f"Read from RAM bank {self.ram_bank} offset {self.offset} >= ram size {self.ram_size}"


class InvalidRamWrite(GameException):
    def __init__(self, ram_bank: int, offset: int, ram_size: int) -> None:
        self.ram_bank = ram_bank
        self.offset = offset
        self.ram_size = ram_size

    def __str__(self) -> str:
        return f"Write to RAM bank {self.ram_bank} offset {self.offset} >= ram size {self.ram_size}"


# User error, ie the user gave us an ivalid or corrupt input file
class UserException(EmuError):
    """Inheriting From EmuError"""


class RomMissing(UserException):
    def __init__(self, filename: str, err: Exception) -> None:
        self.filename = filename
        self.err = err

    def __str__(self) -> str:
        return f"Error opening {self.filename}: {self.err}"


class LogoChecksumFailed(UserException):
    def __init__(self, logo_checksum: int) -> None:
        self.logo_checksum = logo_checksum

    def __str__(self) -> str:
        return f"Logo checksum failed: {self.logo_checksum} != 5446"


class HeaderChecksumFailed(UserException):
    def __init__(self, header_checksum: int) -> None:
        self.header_checksum = header_checksum

    def __str__(self) -> str:
        return f"Header checksum failed: {self.header_checksum} != 0"
