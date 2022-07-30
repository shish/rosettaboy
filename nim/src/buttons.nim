type
    Buttons* = object
        headless: bool
        turbo*: bool
        cycle: int
        need_interrupt: bool
        up: bool
        down: bool
        left: bool
        right: bool
        a: bool
        b: bool
        start: bool
        select: bool

proc create*(headless: bool): Buttons =
    return Buttons(
      headless: headless
    )

# FIXME: implement this
proc tick*(buttons: Buttons) =
    return
