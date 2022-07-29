#ifndef ROSETTABOY_ERRORS_H
#define ROSETTABOY_ERRORS_H

#include "consts.h"
#include <exception>
#include <string.h>
#include <string>

#define ERR_BUF_LEN 1000

class EmuException : public std::exception {
protected:
    char buffer[ERR_BUF_LEN] = "EmuException";

public:
    i32 exit_code = 1;
    virtual const char *what() const throw() { return this->buffer; }
};

// User exit
class Quit : public EmuException {
public:
    Quit() {
        this->exit_code = 0;
        snprintf(this->buffer, ERR_BUF_LEN, "User exited the emulator");
    }
};
class Timeout : public EmuException {
public:
    Timeout(int frames, double duration) {
        this->exit_code = 0;
        snprintf(
            this->buffer, ERR_BUF_LEN, "Emulated %d frames in %5.2fs (%.0ffps)", frames, duration, frames / duration);
    }
};

// Game errors, ie the game developer has a bug
class GameError : public EmuException {};
class InvalidOpcode : public GameError {
public:
    InvalidOpcode(u8 opcode) { snprintf(this->buffer, ERR_BUF_LEN, "Invalid opcode: 0x%02X", opcode); }
};
class InvalidRamRead : public GameError {
public:
    InvalidRamRead(u8 ram_bank, int offset, u32 ram_size) {
        snprintf(
            this->buffer, ERR_BUF_LEN, "Read from RAM bank 0x%02X offset 0x%04X >= ram size 0x%04X", ram_bank, offset,
            ram_size);
    }
};
class InvalidRamWrite : public GameError {
public:
    InvalidRamWrite(u8 ram_bank, int offset, u32 ram_size) {
        snprintf(
            this->buffer, ERR_BUF_LEN, "Write to RAM bank 0x%02X offset 0x%04X >= ram size 0x%04X", ram_bank, offset,
            ram_size);
    }
};

// Cart errors, ie the user passed an invalid .gb file on the command line
class CartError : public EmuException {};
class CartOpenError : public CartError {
public:
    CartOpenError(std::string filename, int err) {
        snprintf(this->buffer, ERR_BUF_LEN, "Error opening %s: %s", filename.c_str(), strerror(err));
    }
};
class LogoChecksumFailed : public CartError {
public:
    LogoChecksumFailed(int logo_checksum) {
        snprintf(this->buffer, ERR_BUF_LEN, "Invalid logo checksum: %d", logo_checksum);
    }
};
class HeaderChecksumFailed : public CartError {
public:
    HeaderChecksumFailed(int header_checksum) {
        snprintf(this->buffer, ERR_BUF_LEN, "Invalid header checksum: %d", header_checksum);
    }
};

// Testing
class UnitTestPassed : public EmuException {
public:
    UnitTestPassed() {
        this->exit_code = 0;
        snprintf(this->buffer, ERR_BUF_LEN, "Unit test passed");
    }
};
class UnitTestFailed : public EmuException {
public:
    UnitTestFailed() {
        this->exit_code = 2;
        snprintf(this->buffer, ERR_BUF_LEN, "Unit test failed");
    }
};

#endif // ROSETTABOY_ERRORS_H
