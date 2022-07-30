type
    APU* = object
        silent: bool
        debug: bool

proc create*(silent: bool, debug: bool): APU =
    return APU(
      silent: silent,
      debug: debug,
    )

# FIXME: implement this
proc tick*(apu: APU) =
    return

