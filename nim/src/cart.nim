import std/strformat
import std/bitops

import errors

type
    Cart* = object
        data*: string
        ram*: string

        logo: string
        name*: string
        isGbc: bool
        licensee: uint16
        isSgb: bool
        cartType: int # FIXME
        romSize*: uint32
        ramSize*: uint32
        destination: uint8
        oldLicensee: uint8
        romVersion: uint8
        complementCheck: uint8
        checksum: uint16

const KB: uint32 = 1024

func parseRomSize(val: uint8): uint32 =
    return (32 * KB) shl val

func parseRamSize(val: uint8): uint32 =
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

    let isGbc = data[0x143].int == 0x80 # 0x80 = works on both, 0xC0 = colour only
    let licensee: uint16 = bitops.bitor(data[0x144].int shl 8, data[0x145].int).uint16
    let isSgb = data[0x146].int == 0x03
    let cartType = data[0x147].int # CartType
    let romSize = parseRomSize(data[0x148].uint8)
    let ramSize = parseRamSize(data[0x149].uint8)
    let destination = data[0x14A].uint8
    let oldLicensee = data[0x14B].uint8
    let romVersion = data[0x14C].uint8
    let complementCheck = data[0x14D].uint8
    let checksum: uint16 = bitor(data[0x14E].int shl 8, data[0x14F].int).uint16

    var logoChecksum: uint16 = 0
    for i in logo:
        logoChecksum += i.uint16
    if logoChecksum != 5446:
        raise errors.LogoChecksumFailed.newException(fmt"FIXME Logo checksum failed ({logoChecksum})")

    var headerChecksum: uint16 = 25;
    for i in data[0x0134..0x014D]:
        headerChecksum += i.uint16
    if bitops.bitand(headerChecksum, 0xFF) != 0:
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
        isGbc: isGbc,
        licensee: licensee,
        isSgb: isSgb,
        cartType: cartType,
        romSize: romSize,
        ramSize: ramSize,
        destination: destination,
        oldLicensee: oldLicensee,
        romVersion: romVersion,
        complementCheck: complementCheck,
        checksum: checksum,
    )
