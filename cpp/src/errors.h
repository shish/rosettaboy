#ifndef ROSETTABOY_ERRORS_H
#define ROSETTABOY_ERRORS_H

#include "consts.h"
#include <exception>
#include <string>

class EmuException : public std::exception {
protected:
    char buffer[1000] = "EmuException";
public:
    i32 exit_code = 1;
    virtual const char *what() const throw() {
        return this->buffer;
    }
};
class Quit : public EmuException {
public:
    Quit() {
        this->exit_code = 0;
    }
};
class Timeout : public EmuException {
public:
    Timeout(int frames, double duration) {
        this->exit_code = 0;
        snprintf(this->buffer, 1000, "Emulated %d frames in %.2fs (%.2ffps)", frames, duration, frames / duration);
    }
};
class CpuHalted : public EmuException {
public:
    CpuHalted() {
        this->exit_code = 0;
    }
};
class CartError : public EmuException {};
class CartOpenError : public CartError {
public:
    CartOpenError(const char *filename, int err) {
        snprintf(this->buffer, 1000, "Error opening %s: %s", filename, strerror(err));

    }
};
class LogoChecksumFailed : public CartError {};
class HeaderChecksumFailed : public CartError {};
class UnitTestPassed : public EmuException {
public:
    UnitTestPassed() {
        this->exit_code = 0;
        snprintf(this->buffer, 1000, "Unit test passed");
    }
};
class UnitTestFailed : public EmuException {
public:
    UnitTestFailed() {
        this->exit_code = 2;
        snprintf(this->buffer, 1000, "Unit test failed");
    }
};
class InvalidOpcode : public EmuException {
public:
    InvalidOpcode(u8 opcode) {
        snprintf(this->buffer, 1000, "Invalid opcode: %02X", opcode);
    }
};

#endif // ROSETTABOY_ERRORS_H
