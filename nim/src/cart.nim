import std/strformat
import std/bitops

import errors

type
    Cart* = object
        data*: string
        ram*: string

        logo: string
        name*: string
        is_gbc: bool
        licensee: uint16
        is_sgb: bool
        cart_type: int # FIXME
        rom_size*: uint32
        ram_size*: uint32
        destination: uint8
        old_licensee: uint8
        rom_version: uint8
        complement_check: uint8
        checksum: uint16

const KB: uint32 = 1024

proc parse_rom_size(val: uint8): uint32 =
    return (32 * KB) shl val

proc parse_ram_size(val: uint8): uint32 =
    case val:
        of 0: return 0
        of 2: return 8 * KB
        of 3: return 32 * KB
        of 4: return 128 * KB
        of 5: return 64 * KB
        else: return 0

proc create*(rom: string): Cart =
    let data = readFile(rom)

    let logo = data[0x104..0x104 + 47]
    let name = data[0x134..0x134 + 15] # FIXME: .trim()

    let is_gbc = data[0x143].int == 0x80 # 0x80 = works on both, 0xC0 = colour only
    let licensee: uint16 = bitops.bitor(data[0x144].int shl 8, data[0x145].int).uint16
    let is_sgb = data[0x146].int == 0x03
    let cart_type = data[0x147].int # CartType
    let rom_size = parse_rom_size(data[0x148].uint8)
    let ram_size = parse_ram_size(data[0x149].uint8)
    let destination = data[0x14A].uint8
    let old_licensee = data[0x14B].uint8
    let rom_version = data[0x14C].uint8
    let complement_check = data[0x14D].uint8
    let checksum: uint16 = bitor(data[0x14E].int shl 8, data[0x14F].int).uint16

    var logo_checksum: uint16 = 0
    for i in logo:
        logo_checksum += i.uint16
    if logo_checksum != 5446:
        raise errors.LogoChecksumFailed.newException(fmt"FIXME Logo checksum failed ({logo_checksum})")

    var header_checksum: uint16 = 25;
    for i in data[0x0134..0x014D]:
        header_checksum += i.uint16
    if bitops.bitand(header_checksum, 0xFF) != 0:
        raise errors.HeaderChecksumFailed.newException("FIXME Header checksum failed")

    #if cart_type != CartType::RomOnly && cart_type != CartType::RomMbc1 {
    #    raise errors.UnsupportedCart.newException("FIXME")
    #}

    # FIXME: ram should be synced with .sav file
    let ram = "" # array[ram_size, 0];

    return Cart(
        data: data,
        ram: ram,

        logo: logo,
        name: name,
        is_gbc: is_gbc,
        licensee: licensee,
        is_sgb: is_sgb,
        cart_type: cart_type,
        rom_size: rom_size,
        ram_size: ram_size,
        destination: destination,
        old_licensee: old_licensee,
        rom_version: rom_version,
        complement_check: complement_check,
        checksum: checksum,
    )
