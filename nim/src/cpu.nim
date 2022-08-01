# import std/strformat
import std/bitops

import ram
import consts

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
        ram: ram.RAM
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

proc create*(ram: ram.RAM, debug: bool): CPU =
    return CPU(
        ram: ram,
        debug: debug
    )

proc interrupt*(cpu: var CPU, interrupt: uint8) =
    cpu.ram.mem_or(consts.Mem_IF, interrupt)
    cpu.halt = false # interrupts interrupt HALT state

proc tick_dma(self: var CPU) =
    # TODO: DMA should take 26 cycles, during which main self.ram is inaccessible
    if self.ram.get(consts.Mem_DMA) != 0:
        let dma_src: uint16 = self.ram.get(consts.Mem_DMA).uint16 shl 8;
        for i in 0..0x9F:
            self.ram.set(consts.Mem_OamBase + i.uint16, self.ram.get(dma_src + i.uint16));
        self.ram.set(consts.Mem_DMA, 0x00)

proc tick_clock(self: var CPU) =
    self.cycle += 1;

    # TODO: writing any value to consts.Mem_DIV should reset it to 0x00
    # increment at 16384Hz (each 64 cycles?)
    if self.cycle mod 64 == 0:
        self.ram.mem_inc(consts.Mem_DIV)

    if bitops.bitand(self.ram.get(consts.Mem_TAC), 1 shl 2) == 1 shl 2:
        # timer enable
        let speeds: array[4, int] = [256, 4, 16, 64] # increment per X cycles
        let speed = speeds[bitops.bitand(self.ram.get(consts.Mem_TAC), 0x03)]
        if self.cycle mod speed.uint32 == 0:
            if self.ram.get(consts.Mem_TIMA) == 0xFF:
                self.ram.set(consts.Mem_TIMA, self.ram.get(consts.Mem_TMA)) # if timer overflows, load base
                self.interrupt(consts.Interrupt_TIMER)
            self.ram.mem_inc(consts.Mem_TIMA)

proc push(self: var CPU, val: uint16) =
    self.ram.set(self.sp - 1, (bitops.bitand((bitops.bitand(val, 0xFF00)) shr 8, 0xFF)).uint8)
    self.ram.set(self.sp - 2, (bitops.bitand(val, 0xFF)).uint8)
    self.sp -= 2

proc pop(self: var CPU): uint16 =
    let val = bitops.bitor(((self.ram.get(self.sp + 1).uint16) shl 8), self.ram.get(self.sp).uint16)
    self.sp += 2
    return val

proc tick_interrupts(self: var CPU) =
    let queued_interrupts = bitops.bitand(self.ram.get(consts.Mem_IE), self.ram.get(consts.Mem_IF))
    if self.interrupts and queued_interrupts != 0:
        #tracing::debug!(
        #    "Handling interrupts: {:02X} & {:02X}",
        #    self.ram.get(consts.Mem_IE),
        #    self.ram.get(consts.Mem_IF)
        #);

        # no nested interrupts, RETI will re-enable
        self.interrupts = false

        # TODO: wait two cycles
        # TODO: push16(PC) should also take two cycles
        # TODO: one more cycle to store new PC
        if bitops.bitand(queued_interrupts, consts.Interrupt_VBLANK) != 0:
            self.push(self.pc);
            self.pc = consts.Mem_VBlankHandler
            self.ram.mem_and(consts.Mem_IF, bitops.bitnot(consts.Interrupt_VBLANK))
        elif bitops.bitand(queued_interrupts, consts.Interrupt_STAT) != 0:
            self.push(self.pc);
            self.pc = consts.Mem_LcdHandler
            self.ram.mem_and(consts.Mem_IF, bitops.bitnot(consts.Interrupt_STAT))
        elif bitops.bitand(queued_interrupts, consts.Interrupt_TIMER) != 0:
            self.push(self.pc);
            self.pc = consts.Mem_TimerHandler
            self.ram.mem_and(consts.Mem_IF, bitops.bitnot(consts.Interrupt_TIMER))
        elif bitops.bitand(queued_interrupts, consts.Interrupt_SERIAL) != 0:
            self.push(self.pc);
            self.pc = consts.Mem_SerialHandler
            self.ram.mem_and(consts.Mem_IF, bitops.bitnot(consts.Interrupt_SERIAL))
        elif bitops.bitand(queued_interrupts, consts.Interrupt_JOYPAD) != 0:
            self.push(self.pc);
            self.pc = consts.Mem_JoypadHandler
            self.ram.mem_and(consts.Mem_IF, bitops.bitnot(consts.Interrupt_JOYPAD))

# FIXME: implement this
proc tick_instructions(self: var CPU) =
    return

proc tick*(self: var CPU) =
    self.tick_dma()
    self.tick_clock()
    self.tick_interrupts()
    if self.halt:
        return
    if self.stop:
        return
    self.tick_instructions()

