#ifndef ROSETTABOY_ERRORS_H
#define ROSETTABOY_ERRORS_H

#include "consts.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

ROSETTABOY_NORETURN
ROSETTABOY_ATTR_PRINTF(2, 3)
static void rosettaboy_err(int exit_code, const char *format, ...) {
    va_list args;
    va_start(args, format);
    vfprintf(stdout, format, args);
    va_end(args);
    exit(exit_code);
}

// Controlled exit, ie we are deliberately stopping emulation
ROSETTABOY_NORETURN
static void quit_emulator() {
    rosettaboy_err(0, "User exited the emulator");
}

ROSETTABOY_NORETURN
static void timeout_err(int frames, double duration) {
    rosettaboy_err(0, "Emulated %5d frames in %5.2fs (%.0ffps)", frames, duration, frames / duration);
}

ROSETTABOY_NORETURN
static void unit_test_passed() {
    rosettaboy_err(0, "Unit test passed");
}

// Controlled exit, ie we are deliberately stopping emulation - but error
ROSETTABOY_NORETURN
static void unit_test_failed() {
    rosettaboy_err(2, "Unit test failed");
}

// Game error, ie the game developer has a bug
ROSETTABOY_NORETURN
static void invalid_opcode_err(u8 opcode) {
    rosettaboy_err(3, "Invalid opcode: 0x%02X", opcode);
}

ROSETTABOY_NORETURN
static void invalid_argument_err(const char *msg) {
    rosettaboy_err(3, "%s", msg);
}

ROSETTABOY_NORETURN
static void invalid_ram_read_err(u8 ram_bank, int offset, u32 ram_size) {
    rosettaboy_err(3, "Read from RAM bank 0x%02X offset 0x%04X >= ram size 0x%04X", ram_bank, offset, ram_size);
}

ROSETTABOY_NORETURN
static void invalid_ram_write_err(u8 ram_bank, int offset, u32 ram_size) {
    rosettaboy_err(3, "Write to RAM bank 0x%02X offset 0x%04X >= ram size 0x%04X", ram_bank, offset, ram_size);
}

// User error, ie the user gave us an invalid or corrupt input file
ROSETTABOY_NORETURN
static void rom_missing_err(const char *filename, int err) {
    rosettaboy_err(4, "Error opening %s: %s\n", filename, strerror(err));
}

ROSETTABOY_NORETURN
static void logo_checksum_failed_err(int logo_checksum) {
    rosettaboy_err(4, "Invalid logo checksum: %d", logo_checksum);
}

ROSETTABOY_NORETURN
static void header_checksum_failed_err(int header_checksum) {
    rosettaboy_err(4, "Invalid header checksum: %d", header_checksum);
}

#endif // ROSETTABOY_ERRORS_H
