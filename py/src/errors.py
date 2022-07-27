class EmuError(Exception):
    exit_code = 1


class Quit(EmuError):
    exit_code = 0


class Timeout(EmuError):
    exit_code = 0

    def __init__(self, frames: int, duration: float):
        self.frames = frames
        self.duration = duration

    def __str__(self) -> str:
        return "Emulated %d frames in %.2fs (%.2ffps)" % (
            self.frames,
            self.duration,
            self.frames / self.duration,
        )


class CpuHalted(EmuError):
    exit_code = 0


class UnsupportedCart(EmuError):
    def __init__(self, cart_type):
        self.cart_type = cart_type


class LogoChecksumFailed(EmuError):
    def __init__(self, logo_checksum: int) -> None:
        self.logo_checksum = logo_checksum


class HeaderChecksumFailed(EmuError):
    def __init__(self, header_checksum: int) -> None:
        self.header_checksum = header_checksum


class UnitTestPassed(EmuError):
    exit_code = 0


class UnitTestFailed(EmuError):
    exit_code = 2


class InvalidOpcode(EmuError):
    def __init__(self, opcode):
        self.opcode = opcode
