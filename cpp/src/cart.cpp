#include <cstring>
#include <fcntl.h>
#include <iostream>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include "cart.h"
#include "consts.h"
#include "errors.h"

#define KB 1024

u32 parse_rom_size(u8 val) { return (32 * KB) << val; }

u32 parse_ram_size(u8 val) {
    switch(val) {
        case 0: return 0;
        case 2: return 8 * KB;
        case 3: return 32 * KB;
        case 4: return 128 * KB;
        case 5: return 64 * KB;
        default: return 0;
    }
}

Cart::Cart(std::string filename) {
    struct stat statbuf;
    int statok = stat(filename.c_str(), &statbuf);
    if(statok < 0) {
        throw new RomMissing(filename, errno);
    }

    if(debug) std::cout << "Reading " << statbuf.st_size << " bytes of cart data from " << filename << "\n";
    int fd = open(filename.c_str(), O_RDONLY);
    if(fd < 0) {
        throw new RomMissing(filename, errno);
    }
    this->data = (unsigned char *)mmap(nullptr, (size_t)statbuf.st_size, PROT_READ, MAP_SHARED, fd, 0);

    memcpy(this->logo, this->data + 0x0104, 48);
    memcpy(this->name, this->data + 0x0134, 16);
    this->is_gbc = this->data[0x143] == 0x80; // 0x80 = works on both, 0xC0 = colour only
    this->licensee = this->data[0x144] << 8 | this->data[0x145];
    this->is_sgb = this->data[0x146] == 0x03;
    this->cart_type = CartType(this->data[0x147]);
    this->rom_size = parse_rom_size(this->data[0x148]);
    this->ram_size = parse_ram_size(this->data[0x149]);
    this->destination = this->data[0x14A];
    this->old_licensee = this->data[0x14B];
    this->rom_version = this->data[0x14C];
    this->complement_check = this->data[0x14D];
    this->checksum = this->data[0x14E] << 8 | this->data[0x14F];

    u16 logo_checksum = 0;
    for(u8 i : this->logo) {
        logo_checksum += i;
    }
    if(logo_checksum != 5446) {
        throw new LogoChecksumFailed(logo_checksum);
    }

    u16 header_checksum = 25;
    for(int i = 0x0134; i < 0x014E; i++) {
        header_checksum += this->data[i];
    }
    if((header_checksum & 0xFF) != 0) {
        throw new HeaderChecksumFailed(header_checksum);
    }

    if(this->ram_size) {
        std::string fn2 = filename;
        fn2.replace(fn2.end() - 2, fn2.end(), "sav");
        int ram_fd = open(fn2.c_str(), O_RDWR | O_CREAT, 0600);
        if(ram_fd < 0) {
            throw new RomMissing(fn2, errno);
        }
        if(ftruncate(ram_fd, this->ram_size) != 0) {
            throw new RomMissing(fn2, errno);
        }
        this->ram =
            (unsigned char *)mmap(nullptr, (size_t)this->ram_size, PROT_READ | PROT_WRITE, MAP_SHARED, ram_fd, 0);
    }

    if(debug) {
        printf("name         : %s\n", name);
        printf("is_gbc       : %d\n", is_gbc);
        printf("is_sgb       : %d\n", is_sgb);
        printf("licensee     : %d\n", licensee);
        printf("old_licensee : %d\n", old_licensee);
        printf("destination  : %d\n", destination);
        printf("cart_type    : %d\n", cart_type);
        printf("rom_size     : %u\n", rom_size);
        printf("ram_size     : %u\n", ram_size);
        printf("rom_version  : %d\n", rom_version);
        printf("ccheck       : %d\n", complement_check);
        printf("checksum     : %d\n", checksum);
    }
}
