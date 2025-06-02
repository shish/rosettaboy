
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include "cart.h"
#include "consts.h"
#include "errors.h"

#define KB 1024

u32 parse_rom_size(u8 val) {
    return (32 * KB) << val;
}

u32 parse_ram_size(u8 val) {
    switch (val) {
        case 0:
            return 0;
        case 2:
            return 8 * KB;
        case 3:
            return 32 * KB;
        case 4:
            return 128 * KB;
        case 5:
            return 64 * KB;
        default:
            return 0;
    }
}

void cart_ctor(struct Cart *self, const char *filename, bool debug) {
    *self = (struct Cart){.debug = debug};

    struct stat statbuf = {0};
    int statok = stat(filename, &statbuf);
    if (statok < 0) {
        rom_missing_err(filename, errno);
    }

    if (self->debug) {
        printf("Reading %ld bytes of cart data from %s\n", statbuf.st_size, filename);
    }

    int fd = open(filename, O_RDONLY);
    if (fd < 0) {
        rom_missing_err(filename, errno);
    }
    self->data = (unsigned char *) mmap(NULL, (size_t) statbuf.st_size, PROT_READ, MAP_SHARED, fd, 0);

    memcpy(self->logo, self->data + 0x0104, 48);
    memcpy(self->name, self->data + 0x0134, 16);
    self->is_gbc = self->data[0x143] == 0x80; // 0x80 = works on both, 0xC0 = colour only
    self->licensee = self->data[0x144] << 8 | self->data[0x145];
    self->is_sgb = self->data[0x146] == 0x03;
    self->cart_type = /*CartType(*/ self->data[0x147] /*)*/;
    self->rom_size = parse_rom_size(self->data[0x148]);
    self->ram_size = parse_ram_size(self->data[0x149]);
    self->destination = self->data[0x14A];
    self->old_licensee = self->data[0x14B];
    self->rom_version = self->data[0x14C];
    self->complement_check = self->data[0x14D];
    self->checksum = self->data[0x14E] << 8 | self->data[0x14F];

    u16 logo_checksum = 0;
    for (u8 i = 0; i < 48; i++) {
        logo_checksum += self->logo[i];
    }
    if (logo_checksum != 5446) {
        logo_checksum_failed_err(logo_checksum);
    }

    u16 header_checksum = 25;
    for (int i = 0x0134; i < 0x014E; i++) {
        header_checksum += self->data[i];
    }
    if ((header_checksum & 0xFF) != 0) {
        header_checksum_failed_err(header_checksum);
    }

    if (self->ram_size) {
        size_t filename_len = strlen(filename);
        char *filename2 = calloc(filename_len + 2, sizeof(char));
        strncpy(filename2, filename, filename_len - 2);
        strncpy(filename2 + filename_len - 2, "sav", 3);

        int ram_fd = open(filename2, O_RDWR | O_CREAT, 0600);
        if (ram_fd < 0) {
            rom_missing_err(filename2, errno);
        }
        if (ftruncate(ram_fd, self->ram_size) != 0) {
            rom_missing_err(filename2, errno);
        }
        self->ram =
            (unsigned char *) mmap(NULL, (size_t) self->ram_size, PROT_READ | PROT_WRITE, MAP_SHARED, ram_fd, 0);
        free(filename2);
    }

    if (self->debug) {
        printf("name         : %s\n", self->name);
        printf("is_gbc       : %d\n", self->is_gbc);
        printf("is_sgb       : %d\n", self->is_sgb);
        printf("licensee     : %d\n", self->licensee);
        printf("old_licensee : %d\n", self->old_licensee);
        printf("destination  : %d\n", self->destination);
        printf("cart_type    : %d\n", self->cart_type);
        printf("rom_size     : %u\n", self->rom_size);
        printf("ram_size     : %u\n", self->ram_size);
        printf("rom_version  : %d\n", self->rom_version);
        printf("ccheck       : %d\n", self->complement_check);
        printf("checksum     : %d\n", self->checksum);
    }
}
