type
    Cart* = object
        name*: string

proc create*(rom: string): Cart =
    return Cart(
      name: rom
    )

# FIXME: implement this
