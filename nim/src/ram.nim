import cart

type
    RAM* = object
        cart: cart.Cart
        ram_enable: bool
        ram_bank_mode: bool
        ram_bank_low: uint8
        ram_bank_high: uint8
        rom_bank: uint8
        ram_bank: uint8
        boot: array[0x100, uint8]
        data*: array[0xFFFF+1, uint8]

proc create*(cart: Cart): RAM =
    return RAM(
      cart: cart
    )
