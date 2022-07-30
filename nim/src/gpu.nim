type
    GPU* = object
        cart_name: string
        headless: bool
        debug: bool

proc create*(cart_name: string, headless: bool, debug: bool): GPU =
    return GPU(
      cart_name: cart_name,
      headless: headless,
      debug: debug,
    )

# FIXME: implement this
proc tick*(gpu: GPU) =
    return
