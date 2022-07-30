type
    CPU* = object
        debug: bool

proc create*(debug: bool): CPU =
    return CPU(
      debug: debug)

# FIXME: implement this
proc tick*(cpu: CPU) =
    return
