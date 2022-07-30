type
    Cart* = object
        data*: string
        ram*: string

        logo: string
        name*: string
        is_gbc: bool
        licensee: uint16
        is_sgb: bool
        cart_type: int  # FIXME
        rom_size: uint32
        ram_size: uint32
        destination: uint8
        old_licensee: uint8
        rom_version: uint8
        complement_check: uint8
        checksum: uint16

proc create*(rom: string): Cart =
    let data = readFile(rom)

    # FIXME: implement this
    return Cart(
      data: data,
      ram: "",
      name: "Fake Rom",
    )
