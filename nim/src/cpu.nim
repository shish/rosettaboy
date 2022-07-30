# import std/strformat

type
    R8 = object
        f: uint8
        a: uint8
        c: uint8
        b: uint8
        e: uint8
        d: uint8
        l: uint8
        h: uint8
    R16 = object
        af: uint16
        bc: uint16
        de: uint16
        hl: uint16
    Regs {.union.} = object
        r8: R8
        r16: R16
    CPU* = object
        stop*: bool
        interrupts: bool
        halt: bool
        debug: bool
        cycle: uint32
        owed_cycles: uint32
        regs: Regs
        sp: uint16
        pc: uint16
        flag_z: bool
        flag_n: bool
        flag_c: bool
        flag_h: bool

proc create*(debug: bool): CPU =
    return CPU(
      debug: debug
    )

# FIXME: implement this
proc tick*(cpu: var CPU) =
    # cpu.regs.r16.af = 0x1234
    # echo fmt"{cpu.regs.r8.a:02X} / {cpu.regs.r8.f:02X}"
    return
