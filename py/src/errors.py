class EmuError(Exception):
    exit_code = 1


class UnsupportedCart(EmuError):
    def __init__(self, cart_type):
        self.cart_type = cart_type


# Controlled exit, ie we are deliberately stopping emulation
class ControlledExit(EmuError):
    """Inheriting from EmuError"""


class Quit(ControlledExit):
    exit_code = 0

    def __str__(self) -> str:
        return "User has exited the emulator"


class Timeout(ControlledExit):
    exit_code = 0

    def __init__(self, frames: int, duration: float):
        self.frames = frames
        self.duration = duration

    def __str__(self) -> str:
        return "Emulated %5d frames in %5.2fs (%.0ffps)" % (
            self.frames,
            self.duration,
            self.frames / self.duration,
        )


class UnitTestPassed(ControlledExit):
    exit_code = 0

    def __str__(self) -> str:
        return "Unit test passed"


class UnitTestFailed(ControlledExit):
    exit_code = 2

    def __str__(self) -> str:
        return "Unit test failed"


# Game error, ie the game developer has a bug
class GameException(EmuError):
    """Inheriting from EmuError"""

    exit_code = 3


class InvalidOpcode(GameException):
    def __init__(self, opcode):
        self.opcode = opcode

    def __str__(self) -> str:
        return f"Invalid opcode {self.opcode}"


class InvalidRamRead(GameException):
    def __init__(self, ram_bank, offset, ram_size):
        self.ram_bank = ram_bank
        self.offset = offset
        self.ram_size = ram_size

    def __str__(self) -> str:
        return f"Read from RAM bank {self.ram_bank} offset {self.offset} >= ram size {self.ram_size}"


class InvalidRamWrite(GameException):
    def __init__(self, ram_bank, offset, ram_size):
        self.ram_bank = ram_bank
        self.offset = offset
        self.ram_size = ram_size

    def __str__(self) -> str:
        return f"Write to RAM bank {self.ram_bank} offset {self.offset} >= ram size {self.ram_size}"


# User error, ie the user gave us an ivalid or corrupt input file
class UserException(EmuError):
    """Inheriting From EmuError"""

    exit_code = 4


class RomMissing(UserException):
    def __init__(self, filename, err):
        self.filename = filename
        self.err = err

    def __str__(self) -> str:
        return f"Error opening {self.filename}: {self.err}"


class LogoChecksumFailed(UserException):
    def __init__(self, logo_checksum):
        self.logo_checksum = logo_checksum

    def __str__(self) -> str:
        return f"Logo checksum failed: {self.logo_checksum} != 5446"


class HeaderChecksumFailed(UserException):
    def __init_(self, header_checksum):
        self.header_checksum = header_checksum

    def __str__(self) -> str:
        return f"Header checksum failed: {self.header_checksum} != 0"
