#include <cstring>
#include <iostream>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#include "consts.h"
#include "cart.h"

using namespace std;

#define KB 1024
#define MB 1024 * 1024

u32 parse_rom_size(u8 val) {
    switch(val) {
        case 0: return 32 * KB;
        case 1: return 64 * KB;
        case 2: return 128 * KB;
        case 3: return 256 * KB;
        case 4: return 512 * KB;
        case 5: return 1 * MB;
        case 6: return 2 * MB;
        case 7: return 4 * MB;
        case 8: return 8 * MB;
        case 0x52: return 1.1 * MB;
        case 0x53: return 1.2 * MB;
        case 0x54: return 1.5 * MB;
        default: return 0;
    }
}

u32 parse_ram_size(u8 val) {
    switch(val) {
        case 0: return 0;
        case 1: return 2 * KB;
        case 2: return 8 * KB;
        case 3: return 32 * KB;
        case 4: return 128 * KB;
        case 5: return 64 * KB;
        default: return 0;
    }
}

Cart::Cart(const char *filename) {
    struct stat statbuf;
    stat(filename, &statbuf);

    if(debug) cout << "Reading " << statbuf.st_size << " bytes of cart data from " << filename << "\n";
    int fd = open(filename, O_RDONLY);
    this->data = (unsigned char*)mmap(nullptr, (size_t)statbuf.st_size, PROT_READ, MAP_SHARED, fd, 0);

    memcpy(this->logo, this->data + 0x0104, 48);
    memcpy(this->name, this->data + 0x0134, 16);
    this->is_gbc = this->data[0x143] == 0x80;  // 0x80 = works on both, 0xC0 = colour only
    this->licensee = this->data[0x144] << 8 | this->data[0x145];
    this->is_sgb = this->data[0x146] == 0x03;
    this->cart_type = CartType(this->data[0x147]);
    this->rom_size = parse_rom_size(this->data[0x148]);
    this->ram_size = parse_ram_size(this->data[0x149]);
    this->destination = Destination(this->data[0x14A]);
    this->old_licensee = OldLicensee(this->data[0x14B]);
    this->rom_version = this->data[0x14C];
    this->complement_check = this->data[0x14D];
    this->checksum = this->data[0x14E] << 8 | this->data[0x14F];

    u16 logo_checksum = 0;
    for(u8 i : this->logo) {
        logo_checksum += i;
    }
    if(logo_checksum != 5446) {
        cout << "Logo checksum failed\n";
    }

    u16 header_checksum = 25;
    for(int i=0x0134; i<0x014E; i++) {
        header_checksum += this->data[i];
    }
    if((header_checksum & 0xFF) != 0) {
        cout << "Header checksum failed\n";
    }

    if(this->ram_size) {
        string fn2 = filename;
        fn2.replace(fn2.end() - 2,fn2.end(), "sav");
        truncate(fn2.c_str(), this->ram_size);
        int ram_fd = open(fn2.c_str(), O_RDWR|O_CREAT);
        this->ram = (unsigned char*)mmap(nullptr, (size_t)statbuf.st_size, PROT_READ|PROT_WRITE, MAP_SHARED, ram_fd, 0);
    }

    if(debug) {
        printf("name         : %s\n", name);
        printf("is_gbc       : %d\n", is_gbc);
        printf("is_sgb       : %d\n", is_sgb);
        printf("licensee     : %d\n", licensee);
        printf("old_licensee : %d\n", old_licensee);
        printf("destination  : %d\n", destination);
        printf("cart_type    : %d\n", cart_type);
        printf("rom_size     : %d\n", rom_size);
        printf("ram_size     : %d\n", ram_size);
        printf("rom_version  : %d\n", rom_version);
        printf("ccheck       : %d\n", complement_check);
        printf("checksum     : %d\n", checksum);
    }
}
