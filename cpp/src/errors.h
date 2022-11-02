#ifndef ROSETTABOY_ERRORS_H
#define ROSETTABOY_ERRORS_H

#include "consts.h"
#include <exception>
#include <stdarg.h>
#include <string.h>
#include <string>

#define ERR_BUF_LEN 1000

class EmuException : public std::exception {
protected:
    char buffer[ERR_BUF_LEN] = "EmuException";
    void set_msg(const char *format, ...) {
        va_list args;
        va_start(args, format);
        vsnprintf(this->buffer, ERR_BUF_LEN, format, args);
        va_end(args);
    }

public:
    virtual const char *what() const throw() { return this->buffer; }
};

// Controlled exit, ie we are deliberately stopping emulation
class ControlledExit : public EmuException {};
class Quit : public ControlledExit {
public:
    Quit() { this->set_msg("User exited the emulator"); }
};
class Timeout : public ControlledExit {
public:
    Timeout(int frames, double duration) {
        this->set_msg("Emulated %5d frames in %5.2fs (%.0ffps)", frames, duration, frames / duration);
    }
};
class UnitTestPassed : public ControlledExit {
public:
    UnitTestPassed() { this->set_msg("Unit test passed"); }
};
class UnitTestFailed : public ControlledExit {
public:
    UnitTestFailed() { this->set_msg("Unit test failed"); }
};

// Game error, ie the game developer has a bug
class GameException : public EmuException {};
class InvalidOpcode : public GameException {
public:
    InvalidOpcode(u8 opcode) { this->set_msg("Invalid opcode: 0x%02X", opcode); }
};
class InvalidRamRead : public GameException {
public:
    InvalidRamRead(u8 ram_bank, int offset, u32 ram_size) {
        this->set_msg("Read from RAM bank 0x%02X offset 0x%04X >= ram size 0x%04X", ram_bank, offset, ram_size);
    }
};
class InvalidRamWrite : public GameException {
public:
    InvalidRamWrite(u8 ram_bank, int offset, u32 ram_size) {
        this->set_msg("Write to RAM bank 0x%02X offset 0x%04X >= ram size 0x%04X", ram_bank, offset, ram_size);
    }
};

// User error, ie the user gave us an invalid or corrupt input file
class UserException : public EmuException {};
class RomMissing : public UserException {
public:
    RomMissing(std::string filename, int err) {
        this->set_msg("Error opening %s: %s", filename.c_str(), strerror(err));
    }
};
class LogoChecksumFailed : public UserException {
public:
    LogoChecksumFailed(int logo_checksum) { this->set_msg("Invalid logo checksum: %d", logo_checksum); }
};
class HeaderChecksumFailed : public UserException {
public:
    HeaderChecksumFailed(int header_checksum) { this->set_msg("Invalid header checksum: %d", header_checksum); }
};

#endif // ROSETTABOY_ERRORS_H
