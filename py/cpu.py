from enum import Enum
from cart import Cart, TestCart
from textwrap import dedent


# 01 - special:     PASS
# 02 - interrupts:  Fail...
# 03 - op sp,hl:    PASS
# 04 - op r,imm:    PASS
# 05 - op rp:       PASS
# 06 - ld r,r:      PASS
# 07 - jumps:       PASS
# 08 - misc:        PASS
# 09 - op r,r:      PASS
# 10 - bit ops:     PASS
# 11 - op a,(hl):   PASS

try:
    # boot with the logo scroll if we have a boot rom
    with open("boot.gb", "rb") as fp:
        BOOT = list(fp.read(0x100))
        # NOP the DRM
        BOOT[0xE9] = 0x00
        BOOT[0xEA] = 0x00
        BOOT[0xFA] = 0x00
        BOOT[0xFB] = 0x00
except IOError:
    # Directly set CPU registers as
    # if the logo had been scrolled
    BOOT = [
        # prod memory
        0x31, 0xFE, 0xFF,  # LD SP,$FFFE

        # set flags
        0x3E, 0x01,  # LD A,$00
        0xCB, 0x7F,  # BIT 7,A (sets Z,n,H)
        0x37,        # SCF (sets C)

        # set registers
        0x3E, 0x01,  # LD A,$01
        0x06, 0x00,  # LD B,$01
        0x0E, 0x13,  # LD C,$13
        0x16, 0x00,  # LD D,$00
        0x1E, 0xD8,  # LD E,$D8
        0x26, 0x01,  # LD H,$01
        0x2E, 0x4D,  # LD L,$4D
    ]

    # these 5 instructions must be the final 2 --
    # after these finish executing, PC needs to be 0x100
    BOOT += [0x00] * (0xFE - len(BOOT))
    BOOT += [0xE0, 0x50]  # LDH 50,A (disable boot rom)

assert len(BOOT) == 0x100, f"Bootloader must be 256 bytes ({len(BOOT)})"


class Reg(Enum):
    A = "A"
    B = "B"
    C = "C"
    D = "D"
    E = "E"
    F = "F"
    H = "H"
    L = "L"

    BC = "BC"
    DE = "DE"
    AF = "AF"
    HL = "HL"

    SP = "SP"
    PC = "PC"

    MEM_AT_HL = "MEM_AT_HL"


GEN_REGS = ["B", "C", "D", "E", "H", "L", "[HL]", "A"]


class OpNotImplemented(Exception):
    pass


def opcode(name, cycles, args=""):
    def dec(fn):
        fn.name = name
        fn.cycles = cycles
        fn.args = args
        return fn
    return dec


class CPU:
    # <editor-fold description="Init">
    def __init__(self, cart: Cart=None, debug=False):
        self.cart = cart or TestCart()
        self.interrupts = True
        self.halt = False
        self.stop = False
        self._nopslide = 0
        self._debug = debug
        self._debug_str = ""

        # registers
        self.A = 0x01  # GB / SGB. FF=GBP, 11=GBC
        self.B = 0x00
        self.C = 0x13
        self.D = 0x00
        self.E = 0xD8
        self.H = 0x01
        self.L = 0x4D

        self.SP = 0xFFFE
        self.PC = 0x0000

        # flags
        self.FLAG_Z: bool = True  # zero
        self.FLAG_N: bool = False  # subtract
        self.FLAG_H: bool = True  # half-carry
        self.FLAG_C: bool = True  # carry

        self.ram = [0] * (0xFFFF+1)

        # 16KB ROM bank 0
        for x in range(0x0000, 0x4000):
            self.ram[x] = self.cart.data[x]

        # 16KB Switchable ROM bank
        for x in range(0x4000, 0x8000):
            self.ram[x] = self.cart.data[x]

        # 8KB VRAM
        # 0x8000 - 0xA000
        # from random import randint
        # for x in range(0x8000, 0xA000):
        #   self.ram[x] = randint(0, 256)

        # 8KB Switchable RAM bank
        # 0xA000 - 0xC000

        # 8KB Internal RAM
        # 0xC000 - 0xE000

        # Echo internal RAM
        # 0xE000 - 0xFE00

        # Sprite Attrib Memory (OAM)
        # 0xFE00 - 0xFEA0

        # Empty
        # 0xFEA0 - 0xFF00

        # IO Ports
        # 0xFF00 - 0xFF4C
        self.ram[0xFF00] = 0x00  # BUTTONS

        self.ram[0xFF01] = 0x00  # SB (Serial Data)
        self.ram[0xFF02] = 0x00  # SC (Serial Control)

        self.ram[0xFF04] = 0x00  # DIV
        self.ram[0xFF05] = 0x00  # TIMA
        self.ram[0xFF06] = 0x00  # TMA
        self.ram[0xFF07] = 0x00  # TAC

        self.ram[0xFF0F] = 0x00  # IF

        self.ram[0xFF10] = 0x80  # NR10
        self.ram[0xFF11] = 0xBF  # NR11
        self.ram[0xFF12] = 0xF3  # NR12
        self.ram[0xFF14] = 0xBF  # NR14
        self.ram[0xFF16] = 0x3F  # NR21
        self.ram[0xFF17] = 0x00  # NR22
        self.ram[0xFF19] = 0xBF  # NR24
        self.ram[0xFF1A] = 0x7F  # NR30
        self.ram[0xFF1B] = 0xFF  # NR31
        self.ram[0xFF1C] = 0x9F  # NR32
        self.ram[0xFF1E] = 0xBF  # NR33
        self.ram[0xFF20] = 0xFF  # NR41
        self.ram[0xFF21] = 0x00  # NR42
        self.ram[0xFF22] = 0x00  # NR43
        self.ram[0xFF23] = 0xBF  # NR30
        self.ram[0xFF24] = 0x77  # NR50
        self.ram[0xFF25] = 0xF3  # NR51
        self.ram[0xFF26] = 0xF1  # NR52  # 0xF0 on SGB

        self.ram[0xFF40] = 0x91  # LCDC
        self.ram[0xFF41] = 0x00  # STAT
        self.ram[0xFF42] = 0x00  # SCX aka SCROLL_Y
        self.ram[0xFF43] = 0x00  # SCY aka SCROLL_X
        self.ram[0xFF44] = 144  # LY aka currently drawn line, 0-153, >144 = vblank
        self.ram[0xFF45] = 0x00  # LYC
        self.ram[0xFF46] = 0x00  # DMA
        self.ram[0xFF47] = 0xFC  # BGP
        self.ram[0xFF48] = 0xFF  # OBP0
        self.ram[0xFF49] = 0xFF  # OBP1
        self.ram[0xFF4A] = 0x00  # WY
        self.ram[0xFF4B] = 0x00  # WX

        # Empty
        # 0xFF4C - 0xFF80

        # Internal RAM
        # 0xFF80 - 0xFFFF

        # Interrupt Enabled Register
        self.ram[0xFFFF] = 0x00  # IE

        # TODO: ram[E000-FE00] mirrors ram[C000-DE00]

        self.ops = [
            getattr(self, "op%02X" % n)
            for n in range(0x00, 0xFF+1)
        ]
        self.cb_ops = [
            getattr(self, "opCB%02X" % n)
            for n in range(0x00, 0xFF+1)
        ]

    def __str__(self):
        s = (
            "ZNHC PC   SP   STACK:\n"
            "%d%d%d%d %04X %04X (%02X%02X)\n"
            f"A  {self.A:02X} {self.A:08b} {self.A}\n"
            f"B  {self.B:02X} {self.B:08b} {self.B}\n"
            f"C  {self.C:02X} {self.C:08b} {self.C}\n"
            f"D  {self.D:02X} {self.D:08b} {self.D}\n"
            f"E  {self.E:02X} {self.E:08b} {self.E}\n"
            f"H  {self.H:02X} {self.H:08b} {self.H}\n"
            f"L  {self.L:02X} {self.L:08b} {self.L}\n"
            % (
                self.FLAG_Z or 0, self.FLAG_N or 0, self.FLAG_H or 0, self.FLAG_C or 0,
                self.PC, self.SP,
                self.ram[self.SP], self.ram[self.SP+1],
            )
        )
        if (
            self.A > 0xFF or self.A < 0x00 or
            self.B > 0xFF or self.B < 0x00 or
            self.C > 0xFF or self.C < 0x00 or
            self.D > 0xFF or self.D < 0x00 or
            self.E > 0xFF or self.E < 0x00 or
            self.H > 0xFF or self.H < 0x00 or
            self.L > 0xFF or self.L < 0x00
        ):
            raise Exception("Register value out of range:" + s)
        return s

    # </editor-fold>

    # <editor-fold description="Tick">
    def tick(self):
        # TODO: extra cycles when conditional jumps are taken

        if self.ram[0xFF50] == 0:
            src = BOOT
        else:
            src = self.ram

        if self.PC >= 0xFF00:
            raise Exception("PC reached IO ports (0x%04X) after %d NOPs" % (self.PC, self._nopslide))

        ins = src[self.PC]
        if ins == 0x00:
            self._nopslide += 1
            self.PC += 1
            if self._nopslide > 0xFF and False:
                raise Exception("NOP slide")
            return 4
        else:
            self._nopslide = 0

        if ins == 0xCB:
            ins = src[self.PC + 1]
            cmd = self.cb_ops[ins]
            self.PC += 1
        else:
            cmd = self.ops[ins]

        if cmd.args == "B":
            param = src[self.PC + 1]
            self._debug_str = f"[{self.PC:04X}({ins:02X})]: {cmd.name.replace('n', '$%02X' % param)}"
            self.PC += 2
        elif cmd.args == "b":
            param = src[self.PC + 1]
            if param > 128:
                param -= 256
            self._debug_str = f"[{self.PC:04X}({ins:02X})]: {cmd.name.replace('n', '%d' % param)}"
            self.PC += 2
        elif cmd.args == "H":
            param = (src[self.PC + 1]) | (src[self.PC + 2] << 8)
            self._debug_str = f"[{self.PC:04X}({ins:02X})]: {cmd.name.replace('nn', '$%04X' % param)}"
            self.PC += 3
        else:
            param = None
            self._debug_str = f"[{self.PC:04X}({ins:02X})]: {cmd.name}"
            self.PC += 1

        if self._debug:
            print(self._debug_str)
        if param is not None:
            cmd(param)
        else:
            cmd()
        if self._debug:
            print(self)

        return cmd.cycles
    # </editor-fold>

    # <editor-fold description="Debugger">
    def debugger(self):
        while True:
            cmd = input("dbg> ").split()
            if cmd[0] == "cpu":
                print(self)
            if cmd[0] == "ram":
                print("%02X" % self.ram[int(cmd[1], 16)])
            if cmd[0] == "run":
                break
    # </editor-fold>

    # <editor-fold description="Registers">
    @property
    def AF(self):
        """
        >>> cpu = CPU()
        >>> cpu.A = 0x01
        >>> cpu.FLAG_Z = True
        >>> cpu.FLAG_N = True
        >>> cpu.FLAG_H = True
        >>> cpu.FLAG_C = True
        >>> cpu.AF
        496
        """
        return (
            self.A << 8 |
            (self.FLAG_Z or 0) << 7 |
            (self.FLAG_N or 0) << 6 |
            (self.FLAG_H or 0) << 5 |
            (self.FLAG_C or 0) << 4
        )

    @AF.setter
    def AF(self, val):
        self.A = val >> 8 & 0xFF
        self.FLAG_Z = bool(val & 0b10000000)
        self.FLAG_N = bool(val & 0b01000000)
        self.FLAG_H = bool(val & 0b00100000)
        self.FLAG_C = bool(val & 0b00010000)

    @property
    def BC(self):
        """
        >>> cpu = CPU()
        >>> cpu.BC = 0x1234
        >>> cpu.B, cpu.C
        (18, 52)

        >>> cpu.B, cpu.C = 1, 2
        >>> cpu.BC
        258
        """
        return self.B << 8 | self.C

    @BC.setter
    def BC(self, val):
        self.B = val >> 8 & 0xFF
        self.C = val & 0xFF

    @property
    def DE(self):
        """
        >>> cpu = CPU()
        >>> cpu.DE = 0x1234
        >>> cpu.D, cpu.E
        (18, 52)

        >>> cpu.D, cpu.E = 1, 2
        >>> cpu.DE
        258
        """
        return self.D << 8 | self.E

    @DE.setter
    def DE(self, val):
        self.D = val >> 8 & 0xFF
        self.E = val & 0xFF

    @property
    def HL(self):
        """
        >>> cpu = CPU()
        >>> cpu.HL = 0x1234
        >>> cpu.H, cpu.L
        (18, 52)

        >>> cpu.H, cpu.L = 1, 2
        >>> cpu.HL
        258
        """
        return self.H << 8 | self.L

    @HL.setter
    def HL(self, val):
        self.H = val >> 8 & 0xFF
        self.L = val & 0xFF

    @property
    def MEM_AT_HL(self):
        return self.ram[self.HL]

    @MEM_AT_HL.setter
    def MEM_AT_HL(self, val):
        self.ram[self.HL] = val
    # </editor-fold>

    # <editor-fold description="Empty Instructions">
    @opcode("ERR CB", 4)
    def opCB(self):
        raise OpNotImplemented("CB is special cased, you shouldn't get here")

    def _err(self, op):
        raise OpNotImplemented("Opcode D3 not implemented")

    opD3 = opcode("ERR D3", 4)(lambda self: self._err("D3"))
    opDB = opcode("ERR DB", 4)(lambda self: self._err("DB"))
    opDD = opcode("ERR DD", 4)(lambda self: self._err("DD"))
    # opE3 = opcode("ERR E3", 4)(lambda self: self._err("E3"))
    opE4 = opcode("ERR E4", 4)(lambda self: self._err("E4"))
    opEB = opcode("ERR EB", 4)(lambda self: self._err("EB"))
    opEC = opcode("ERR EC", 4)(lambda self: self._err("EC"))
    opED = opcode("ERR ED", 4)(lambda self: self._err("ED"))
    opF4 = opcode("ERR F4", 4)(lambda self: self._err("F4"))
    opFC = opcode("ERR FC", 4)(lambda self: self._err("FC"))
    opFD = opcode("ERR FD", 4)(lambda self: self._err("FD"))

    @opcode("DBG", 4)
    def opE3(self):
        print(self)
        self.debugger()
    # </editor-fold>

    # <editor-fold description="3.3.1 8-Bit Loads">
    # ===================================
    # 1. LD nn,n
    for base, reg_to in enumerate(GEN_REGS):
        cycles = 12 if "[HL]" in {reg_to} else 8
        op = 0x06 + base * 8
        reg_to_name = reg_to.replace('[HL]', 'MEM_AT_HL')
        exec(dedent(f"""
            @opcode("LD {reg_to},n", {cycles}, "B")
            def op{op:02X}(self, val):
                self.{reg_to_name} = val
        """))

    # ===================================
    # 2. LD r1,r2
    # Put r2 into r1
    for base, reg_to in enumerate(GEN_REGS):
        for offset, reg_from in enumerate(GEN_REGS):
            if reg_from == "[HL]" and reg_to == "[HL]":
                continue

            cycles = 8 if "[HL]" in {reg_from, reg_to} else 4
            op = 0x40 + base * 8 + offset
            reg_to_name = reg_to.replace('[HL]', 'MEM_AT_HL')
            reg_from_name = reg_from.replace('[HL]', 'MEM_AT_HL')
            exec(dedent(f"""
                @opcode("LD {reg_to},{reg_from}", {cycles})
                def op{op:02X}(self):
                    self.{reg_to_name} = self.{reg_from_name}
            """))

    # ===================================
    # 3. LD A,n
    # Put n into A
    def _ld_val_to_a(self, val):
        self.A = val

    op0A = opcode("LD A,[BC]", 8)(lambda self: self._ld_val_to_a(self.ram[self.BC]))
    op1A = opcode("LD A,[DE]", 8)(lambda self: self._ld_val_to_a(self.ram[self.DE]))
    opFA = opcode("LD A,[nn]", 16, "H")(lambda self, val: self._ld_val_to_a(self.ram[val]))

    # ===================================
    # 4. LD [nn],A
    def _ld_a_to_mem(self, val):
        self.ram[val] = self.A

    op02 = opcode("LD [BC],A", 8)(lambda self: self._ld_a_to_mem(self.BC))
    op12 = opcode("LD [DE],A", 8)(lambda self: self._ld_a_to_mem(self.DE))
    opEA = opcode("LD [nn],A", 16, 'H')(lambda self, val: self._ld_a_to_mem(val))

    # ===================================
    # 5. LD A,(C)
    @opcode("LD A,[C]", 8)
    def opF2(self):
        self.A = self.ram[0xFF00 + self.C]

    # ===================================
    # 6. LD (C),A
    @opcode("LD A,[C]", 8)
    def opE2(self):
        self.ram[0xFF00 + self.C] = self.A

    # ===================================
    # 7. LD A,[HLD]
    # 8. LD A,[HL-]
    # 9. LDD A,[HL]
    @opcode("LD A,[HL-]", 8)
    def op3A(self):
        self.A = self.ram[self.HL]
        self.HL -= 1

    # ===================================
    # 10. LD [HLD],A
    # 11. LD [HL-],A
    # 12. LDD [HL],A
    @opcode("LD [HL-],A", 8)
    def op32(self):
        self.ram[self.HL] = self.A
        self.HL -= 1

    # ===================================
    # 13. LD A,[HLI]
    # 14. LD A,[HL+]
    # 15. LDI A,[HL]
    @opcode("LD A,[HL+]", 8)
    def op2A(self):
        self.A = self.ram[self.HL]
        self.HL += 1

    # ===================================
    # 16. LD [HLI],A
    # 17. LD [HL+],A
    # 18. LDI [HL],A
    @opcode("LD [HL+],A", 8)
    def op22(self):
        self.ram[self.HL] = self.A
        self.HL += 1

    # ===================================
    # 19. LDH [n],A
    @opcode("LDH [n],A", 12, "B")
    def opE0(self, val):
        if val == 0x01:
            print(chr(self.A), end="")
            # print("0xFF%02X = 0x%02X (%s)" % (val, self.A, chr(self.A)))
        self.ram[0xFF00 + val] = self.A

    # ===================================
    # 20. LDH A,[n]
    @opcode("LDH A,[n]", 12, "B")
    def opF0(self, val):
        self.A = self.ram[0xFF00 + val]
    # </editor-fold>

    # <editor-fold description="3.3.2 16-Bit Loads">
    # ===================================
    # 1. LD n,nn
    def _ld_val_to_reg(self, val, reg: Reg):
        setattr(self, reg.value, val)

    op01 = opcode("LD BC,nn", 12, "H")(lambda self, val: self._ld_val_to_reg(val, Reg.BC))
    op11 = opcode("LD DE,nn", 12, "H")(lambda self, val: self._ld_val_to_reg(val, Reg.DE))
    op21 = opcode("LD HL,nn", 12, "H")(lambda self, val: self._ld_val_to_reg(val, Reg.HL))
    op31 = opcode("LD SP,nn", 12, "H")(lambda self, val: self._ld_val_to_reg(val, Reg.SP))

    # ===================================
    # 2. LD SP,HL

    @opcode("LD SP,HL", 8)
    def opF9(self):
        self.SP = self.HL

    # ===================================
    # 3. LD HL,SP+n
    # 4. LDHL SP,n
    @opcode("LD HL,SP+n", 12, "b")
    def opF8(self, val):
        self.FLAG_H = ((((self.SP & 0x0f) + (val & 0x0f)) & 0x10) != 0)
        self.FLAG_C = ((((self.SP & 0xff) + (val & 0xff)) & 0x100) != 0)
        self.HL = self.SP + val
        self.FLAG_Z = False
        self.FLAG_N = False

    # ===================================
    # 5. LD [nn],SP
    @opcode("LD [nn],SP", 20, "H")
    def op08(self, val):
        self.ram[val+1] = (self.SP >> 8) & 0xFF
        self.ram[val] = self.SP & 0xFF

    # ===================================
    # 6. PUSH nn
    def _push16(self, reg: Reg):
        """
        >>> c = CPU()
        >>> c.BC = 1234
        >>> c.opC5()
        >>> c.opD1()
        >>> c.DE
        1234
        """
        val = getattr(self, reg.value)
        self.ram[self.SP - 1] = (val & 0xFF00) >> 8
        self.ram[self.SP - 2] = val & 0xFF
        self.SP -= 2
        # print("Pushing %r to stack at %r [%r]" % (val, self.SP, self.ram[-10:]))

    opF5 = opcode("PUSH AF", 16)(lambda self: self._push16(Reg.AF))
    opC5 = opcode("PUSH BC", 16)(lambda self: self._push16(Reg.BC))
    opD5 = opcode("PUSH DE", 16)(lambda self: self._push16(Reg.DE))
    opE5 = opcode("PUSH HL", 16)(lambda self: self._push16(Reg.HL))

    # ===================================
    # 6. POP nn
    def _pop16(self, reg: Reg):
        val = (self.ram[self.SP+1] << 8) | self.ram[self.SP]
        # print("Set %r to %r from %r, %r" % (reg, val, self.SP, self.ram[-10:]))
        setattr(self, reg.value, val)
        self.SP += 2

    opF1 = opcode("POP AF", 12)(lambda self: self._pop16(Reg.AF))
    opC1 = opcode("POP BC", 12)(lambda self: self._pop16(Reg.BC))
    opD1 = opcode("POP DE", 12)(lambda self: self._pop16(Reg.DE))
    opE1 = opcode("POP HL", 12)(lambda self: self._pop16(Reg.HL))

    # </editor-fold>

    # <editor-fold description="3.3.3 8-Bit Arithmetic">

    # ===================================
    # 1. ADD A,n
    def _add(self, val):
        self.FLAG_C = self.A + val > 0xFF
        self.FLAG_H = (self.A & 0x0F) + (val & 0x0F) > 0x0F
        self.FLAG_N = False
        self.A += val
        self.A &= 0xFF
        self.FLAG_Z = self.A == 0

    op80 = opcode("ADD A,B", 4)(lambda self: self._add(self.B))
    op81 = opcode("ADD A,C", 4)(lambda self: self._add(self.C))
    op82 = opcode("ADD A,D", 4)(lambda self: self._add(self.D))
    op83 = opcode("ADD A,E", 4)(lambda self: self._add(self.E))
    op84 = opcode("ADD A,H", 4)(lambda self: self._add(self.H))
    op85 = opcode("ADD A,L", 4)(lambda self: self._add(self.L))
    op86 = opcode("ADD A,[HL]", 8)(lambda self: self._add(self.MEM_AT_HL))
    op87 = opcode("ADD A,A", 4)(lambda self: self._add(self.A))

    opC6 = opcode("ADD A,n", 8, "B")(lambda self, val: self._add(val))

    # ===================================
    # 2. ADC A,n
    def _adc(self, val):
        """
        >>> c = CPU()
        >>> c.FLAG_C = True
        >>> c.A = 10
        >>> c.B = 5
        >>> c.op88()
        >>> c.A
        16
        """
        carry = int(self.FLAG_C)
        self.FLAG_C = bool(self.A + val + int(self.FLAG_C) > 0xFF)
        self.FLAG_H = (self.A & 0x0F) + (val & 0x0F) + carry > 0x0F
        self.FLAG_N = False
        self.A += val + carry
        self.A &= 0xFF
        self.FLAG_Z = self.A == 0

    op88 = opcode("ADC A,B", 4)(lambda self: self._adc(self.B))
    op89 = opcode("ADC A,C", 4)(lambda self: self._adc(self.C))
    op8A = opcode("ADC A,D", 4)(lambda self: self._adc(self.D))
    op8B = opcode("ADC A,E", 4)(lambda self: self._adc(self.E))
    op8C = opcode("ADC A,H", 4)(lambda self: self._adc(self.H))
    op8D = opcode("ADC A,L", 4)(lambda self: self._adc(self.L))
    op8E = opcode("ADC A,[HL]", 8)(lambda self: self._adc(self.MEM_AT_HL))
    op8F = opcode("ADC A,A", 4)(lambda self: self._adc(self.A))

    opCE = opcode("ADC A,n", 8, "B")(lambda self, val: self._adc(val))

    # ===================================
    # 3. SUB n
    def _sub(self, val):
        self.FLAG_C = self.A < val
        self.FLAG_H = (self.A & 0x0F) < (val & 0x0F)
        self.A -= val
        self.A &= 0xFF
        self.FLAG_Z = self.A == 0
        self.FLAG_N = True

    op90 = opcode("SUB A,B", 4)(lambda self: self._sub(self.B))
    op91 = opcode("SUB A,C", 4)(lambda self: self._sub(self.C))
    op92 = opcode("SUB A,D", 4)(lambda self: self._sub(self.D))
    op93 = opcode("SUB A,E", 4)(lambda self: self._sub(self.E))
    op94 = opcode("SUB A,H", 4)(lambda self: self._sub(self.H))
    op95 = opcode("SUB A,L", 4)(lambda self: self._sub(self.L))
    op96 = opcode("SUB A,[HL]", 8)(lambda self: self._sub(self.MEM_AT_HL))
    op97 = opcode("SUB A,A", 4)(lambda self: self._sub(self.A))

    opD6 = opcode("SUB A,n", 8, "B")(lambda self, val: self._sub(val))

    # ===================================
    # 4. SBC n
    def _sbc(self, val):
        """
        >>> c = CPU()
        >>> c.FLAG_C = True
        >>> c.A = 10
        >>> c.B = 5
        >>> c.op98()
        >>> c.A
        4
        """
        byte1 = self.A
        byte2 = val
        res = byte1 - byte2 - int(self.FLAG_C)
        self._sub(val + int(self.FLAG_C))
        self.FLAG_H = ((byte1 ^ byte2 ^ (res & 0xff)) & (1 << 4)) != 0

    op98 = opcode("SBC A,B", 4)(lambda self: self._sbc(self.B))
    op99 = opcode("SBC A,C", 4)(lambda self: self._sbc(self.C))
    op9A = opcode("SBC A,D", 4)(lambda self: self._sbc(self.D))
    op9B = opcode("SBC A,E", 4)(lambda self: self._sbc(self.E))
    op9C = opcode("SBC A,H", 4)(lambda self: self._sbc(self.H))
    op9D = opcode("SBC A,L", 4)(lambda self: self._sbc(self.L))
    op9E = opcode("SBC A,[HL]", 8)(lambda self: self._sbc(self.MEM_AT_HL))
    op9F = opcode("SBC A,A", 4)(lambda self: self._sbc(self.A))

    opDE = opcode("SBC A,n", 8, "B")(lambda self, val: self._sbc(val))

    # ===================================
    # 5. AND n
    def _and(self, val):
        """
        >>> c = CPU()
        >>> c.A = 0b0101
        >>> c.B = 0b0011
        >>> c.opA0()
        >>> f"{c.A:04b}"
        '0001'
        """
        self.A &= val
        self.FLAG_Z = int(self.A == 0)
        self.FLAG_N = False
        self.FLAG_H = True
        self.FLAG_C = False

    opA0 = opcode("AND B", 4)(lambda self: self._and(self.B))
    opA1 = opcode("AND C", 4)(lambda self: self._and(self.C))
    opA2 = opcode("AND D", 4)(lambda self: self._and(self.D))
    opA3 = opcode("AND E", 4)(lambda self: self._and(self.E))
    opA4 = opcode("AND H", 4)(lambda self: self._and(self.H))
    opA5 = opcode("AND L", 4)(lambda self: self._and(self.L))
    opA6 = opcode("AND [HL]", 8)(lambda self: self._and(self.MEM_AT_HL))
    opA7 = opcode("AND A", 4)(lambda self: self._and(self.A))

    opE6 = opcode("AND n", 8, "B")(lambda self, n: self._and(n))

    # ===================================
    # 6. OR n
    def _or(self, val):
        """
        >>> c = CPU()
        >>> c.A = 0b0101
        >>> c.B = 0b0011
        >>> c.opB0()
        >>> f"{c.A:04b}"
        '0111'
        """
        self.A |= val
        self.FLAG_Z = int(self.A == 0)
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_C = False

    opB0 = opcode("OR B", 4)(lambda self: self._or(self.B))
    opB1 = opcode("OR C", 4)(lambda self: self._or(self.C))
    opB2 = opcode("OR D", 4)(lambda self: self._or(self.D))
    opB3 = opcode("OR E", 4)(lambda self: self._or(self.E))
    opB4 = opcode("OR H", 4)(lambda self: self._or(self.H))
    opB5 = opcode("OR L", 4)(lambda self: self._or(self.L))
    opB6 = opcode("OR [HL]", 8)(lambda self: self._or(self.MEM_AT_HL))
    opB7 = opcode("OR A", 4)(lambda self: self._or(self.A))

    opF6 = opcode("OR n", 8, "B")(lambda self, n: self._or(n))

    # ===================================
    # 7. XOR
    def _xor(self, val):
        """
        >>> c = CPU()
        >>> c.A = 0b0101
        >>> c.B = 0b0011
        >>> c.opA8()
        >>> f"{c.A:04b}"
        '0110'
        """
        self.A ^= val
        self.FLAG_Z = int(self.A == 0)
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_C = False

    opA8 = opcode("XOR B", 4)(lambda self: self._xor(self.B))
    opA9 = opcode("XOR C", 4)(lambda self: self._xor(self.C))
    opAA = opcode("XOR D", 4)(lambda self: self._xor(self.D))
    opAB = opcode("XOR E", 4)(lambda self: self._xor(self.E))
    opAC = opcode("XOR H", 4)(lambda self: self._xor(self.H))
    opAD = opcode("XOR L", 4)(lambda self: self._xor(self.L))
    opAE = opcode("XOR [HL]", 8)(lambda self: self._xor(self.MEM_AT_HL))
    opAF = opcode("XOR A", 4)(lambda self: self._xor(self.A))

    opEE = opcode("XOR n", 8, "B")(lambda self, n: self._xor(n))

    # ===================================
    # 8. CP
    # Compare A with n
    def _cp(self, n):
        self.FLAG_Z = self.A == n
        self.FLAG_N = True
        self.FLAG_H = (self.A & 0x0F) < (n & 0x0F)
        self.FLAG_C = self.A < n

    opB8 = opcode("CP B", 4)(lambda self: self._cp(self.B))
    opB9 = opcode("CP C", 4)(lambda self: self._cp(self.C))
    opBA = opcode("CP D", 4)(lambda self: self._cp(self.D))
    opBB = opcode("CP E", 4)(lambda self: self._cp(self.E))
    opBC = opcode("CP H", 4)(lambda self: self._cp(self.H))
    opBD = opcode("CP L", 4)(lambda self: self._cp(self.L))
    opBE = opcode("CP [HL]", 8)(lambda self: self._cp(self.MEM_AT_HL))
    opBF = opcode("CP A", 4)(lambda self: self._cp(self.A))

    opFE = opcode("CP n", 8, "B")(lambda self, val: self._cp(val))

    # ===================================
    # 9. INC
    def _inc8(self, reg: Reg):
        val = getattr(self, reg.value)
        self.FLAG_H = val & 0x0F == 0x0F
        val = (val + 1) & 0xFF
        setattr(self, reg.value, val)
        self.FLAG_Z = val == 0
        self.FLAG_N = False

    op04 = opcode("INC B", 4)(lambda self: self._inc8(Reg.B))
    op0C = opcode("INC C", 4)(lambda self: self._inc8(Reg.C))
    op14 = opcode("INC D", 4)(lambda self: self._inc8(Reg.D))
    op1C = opcode("INC E", 4)(lambda self: self._inc8(Reg.E))
    op24 = opcode("INC H", 4)(lambda self: self._inc8(Reg.H))
    op2C = opcode("INC L", 4)(lambda self: self._inc8(Reg.L))
    op34 = opcode("INC [HL]", 12)(lambda self: self._inc8(Reg.MEM_AT_HL))
    op3C = opcode("INC A", 4)(lambda self: self._inc8(Reg.A))

    # ===================================
    # 10. DEC
    def _dec8(self, reg: Reg):
        val = getattr(self, reg.value)
        val = (val - 1) & 0xFF
        self.FLAG_H = val & 0x0F == 0x0F
        setattr(self, reg.value, val)
        self.FLAG_Z = val == 0
        self.FLAG_N = True

    op05 = opcode("DEC B", 4)(lambda self: self._dec8(Reg.B))
    op0D = opcode("DEC C", 4)(lambda self: self._dec8(Reg.C))
    op15 = opcode("DEC D", 4)(lambda self: self._dec8(Reg.D))
    op1D = opcode("DEC E", 4)(lambda self: self._dec8(Reg.E))
    op25 = opcode("DEC H", 4)(lambda self: self._dec8(Reg.H))
    op2D = opcode("DEC L", 4)(lambda self: self._dec8(Reg.L))
    op35 = opcode("DEC [HL]", 12)(lambda self: self._dec8(Reg.MEM_AT_HL))
    op3D = opcode("DEC A", 4)(lambda self: self._dec8(Reg.A))
    # </editor-fold>

    # <editor-fold description="3.3.4 16-Bit Arithmetic">

    # ===================================
    # 1. ADD HL,nn
    def _add_hl(self, val):
        self.FLAG_H = ((self.HL & 0x0fff) + (val & 0x0fff) > 0x0fff)
        self.FLAG_C = (self.HL + val > 0xffff)
        self.HL += val
        self.HL &= 0xFFFF
        self.FLAG_N = False

    op09 = opcode("ADD HL,BC", 8)(lambda self: self._add_hl(self.BC))
    op19 = opcode("ADD HL,DE", 8)(lambda self: self._add_hl(self.DE))
    op29 = opcode("ADD HL,HL", 8)(lambda self: self._add_hl(self.HL))
    op39 = opcode("ADD HL,SP", 8)(lambda self: self._add_hl(self.SP))

    # ===================================
    # 2. ADD SP,n
    @opcode("ADD SP n", 16, "b")
    def opE8(self, val):
        tmp = self.SP + val
        self.FLAG_H = bool((self.SP ^ val ^ tmp) & 0x10)
        self.FLAG_C = bool((self.SP ^ val ^ tmp) & 0x100)
        self.SP += val
        self.SP &= 0xFFFF
        self.FLAG_Z = False
        self.FLAG_N = False

    # ===================================
    # 3. INC nn
    def _inc16(self, reg):
        val = getattr(self, reg)
        val = (val + 1) & 0xFFFF
        setattr(self, reg, val)

    op03 = opcode("INC BC", 8)(lambda self: self._inc16("BC"))
    op13 = opcode("INC DE", 8)(lambda self: self._inc16("DE"))
    op23 = opcode("INC HL", 8)(lambda self: self._inc16("HL"))
    op33 = opcode("INC SP", 8)(lambda self: self._inc16("SP"))

    # ===================================
    # 4. DEC nn
    def _dec16(self, reg):
        val = getattr(self, reg)
        val = (val - 1) & 0xFFFF
        setattr(self, reg, val)

    op0B = opcode("DEC BC", 8)(lambda self: self._dec16("BC"))
    op1B = opcode("DEC DE", 8)(lambda self: self._dec16("DE"))
    op2B = opcode("DEC HL", 8)(lambda self: self._dec16("HL"))
    op3B = opcode("DEC SP", 8)(lambda self: self._dec16("SP"))

    # </editor-fold>

    # <editor-fold description="3.3.5 Miscellaneous">
    # ===================================
    # 1. SWAP
    # FIXME: CB36 takes 16 cycles, not 8
    def _swap(self, reg: Reg):
        val = getattr(self, reg.value)
        val = ((val & 0xF0) >> 4) | ((val & 0x0F) << 4)
        setattr(self, reg.value, val)
        self.FLAG_Z = val == 0
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_C = False

    # ===================================
    # 2. DAA
    # A = Binary Coded Decimal of A
    @opcode("DAA", 4)
    def op27(self):
        """
        >>> c = CPU()
        >>> c.A = 92
        >>> c.op27()
        >>> bin(c.A)
        '0b11000010'
        """
        tmp = self.A

        if self.FLAG_N == 0:
            if self.FLAG_H or (tmp & 0x0F) > 9:
                tmp += 6
            if self.FLAG_C or tmp > 0x9F:
                tmp += 0x60
        else:
            if self.FLAG_H:
                tmp -= 6
                if self.FLAG_C == 0:
                    tmp &= 0xFF

            if self.FLAG_C:
                tmp -= 0x60

        self.FLAG_H = False
        self.FLAG_Z = False
        if tmp & 0x100:
            self.FLAG_C = True
        self.A = tmp & 0xFF
        if self.A == 0:
            self.FLAG_Z = True

    # ===================================
    # 3. CPL
    # Flip all bits in A
    @opcode("CPL", 4)
    def op2F(self):
        """
        >>> c = CPU()
        >>> c.A = 0b10101010
        >>> c.op2F()
        >>> bin(c.A)
        '0b1010101'
        """
        self.A ^= 0xFF
        self.FLAG_N = True
        self.FLAG_H = True

    # ===================================
    # 4. CCF
    @opcode("CCF", 4)
    def op3F(self):
        """
        >>> c = CPU()
        >>> c.FLAG_C = False
        >>> c.op3F()
        >>> c.FLAG_C
        True
        >>> c.op3F()
        >>> c.FLAG_C
        False
        """
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_C = not self.FLAG_C

    # ===================================
    # 5. SCF
    @opcode("SCF", 4)
    def op37(self):
        """
        >>> c = CPU()
        >>> c.FLAG_C = False
        >>> c.op37()
        >>> c.FLAG_C
        True
        """
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_C = True

    # ===================================
    # 6. NOP
    @opcode("NOP", 4)
    def op00(self):
        pass

    # ===================================
    # 7. HALT
    # Power down CPU until interrupt occurs

    @opcode("HALT", 0)  # doc says 4
    def op76(self):
        self.halt = True
        # FIXME: weird instruction skipping behaviour when interrupts are disabled

    # ===================================
    # 8. STOP
    # Halt CPU & LCD until button pressed

    @opcode("STOP", 4, "B")
    def op10(self, sub):  # 10 00
        if sub == 00:
            self.stop = True
        else:
            raise OpNotImplemented("Missing sub-command 10:%02X" % sub)

    # ===================================
    # 9. DI
    @opcode("DI", 4)
    def opF3(self):
        # FIXME: supposed to take effect after the following instruction
        self.interrupts = False

    # ===================================
    # 10. EI
    @opcode("EI", 4)
    def opFB(self):
        # FIXME: supposed to take effect after the following instruction
        self.interrupts = True

    # </editor-fold>

    # <editor-fold description="3.3.6 Rotates & Shifts">
    for base, ins in enumerate(["RLC", "RRC", "RL", "RR", "SLA", "SRA", "SWAP", "SRL"]):
        for offset, reg in enumerate(GEN_REGS):
            op = (base * 8) + offset
            time = 16 if reg == "[HL]" else 8
            regn = reg.replace("[HL]", "MEM_AT_HL")
            exec(dedent(f"""
                @opcode("{ins} {reg}", {time})
                def opCB{op:02X}(self):
                    self._{ins.lower()}(Reg.{regn})
            """))

    # ===================================
    # 1. RCLA
    @opcode("RCLA", 4)
    def op07(self):
        """
        >>> c = CPU()
        >>> c.A = 0b10101010
        >>> c.FLAG_C = False
        >>> c.op07()
        >>> bin(c.A), c.FLAG_C
        ('0b1010100', True)
        """
        self.FLAG_C = (self.A & 0b10000000) != 0
        self.A = ((self.A << 1) | (self.A >> 7)) & 0xFF
        self.FLAG_Z = False
        self.FLAG_N = False
        self.FLAG_H = False

    # ===================================
    # 2. RLA
    @opcode("RLA", 4)
    def op17(self):
        """
        >>> c = CPU()
        >>> c.A = 0b10101010
        >>> c.FLAG_C = True
        >>> c.op17()
        >>> bin(c.A), c.FLAG_C
        ('0b1010101', True)
        """
        old_c = self.FLAG_C
        self.FLAG_C = (self.A & 0b10000000) != 0
        self.A = ((self.A << 1) | old_c) & 0xFF
        self.FLAG_Z = False
        self.FLAG_N = False
        self.FLAG_H = False

    # ===================================
    # 3. RRCA
    @opcode("RRCA", 4)
    def op0F(self):
        """
        >>> c = CPU()
        >>> c.A = 0b10101010
        >>> c.FLAG_C = True
        >>> c.op0F()
        >>> bin(c.A), c.FLAG_C
        ('0b1010101', False)
        """
        self.FLAG_C = (self.A & 0b00000001) != 0
        self.A = ((self.A >> 1) | (self.A << 7)) & 0xFF
        self.FLAG_Z = False
        self.FLAG_N = False
        self.FLAG_H = False

    # ===================================
    # 4. RRA
    @opcode("RRA", 4)
    def op1F(self):
        """
        >>> c = CPU()
        >>> c.A = 0b10101010
        >>> c.FLAG_C = True
        >>> c.op1F()
        >>> bin(c.A), c.FLAG_C
        ('0b11010101', False)
        """
        old_c = self.FLAG_C
        self.FLAG_C = (self.A & 0b00000001) != 0
        self.A = (self.A >> 1) | (old_c << 7)
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_Z = False

    # ===================================
    # 5. RLC
    def _rlc(self, reg: Reg):
        val = getattr(self, reg.value)
        self.FLAG_C = bool(val & 0b10000000)
        val <<= 1
        if self.FLAG_C:
            val |= 1
        val &= 0xFF
        setattr(self, reg.value, val)
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_Z = val == 0

    # ===================================
    # 6. RL
    def _rl(self, reg: Reg):
        """
        >>> c = CPU()
        >>> c.A = 0xAA
        >>> c.FLAG_C = True

        >>> c._rl(Reg.A)
        >>> hex(c.A), c.FLAG_C
        ('0x55', True)
        >>> c._rl(Reg.A)
        >>> hex(c.A), c.FLAG_C
        ('0xab', False)
        >>> c._rl(Reg.A)
        >>> hex(c.A), c.FLAG_C
        ('0x56', True)
        >>> c._rl(Reg.A)
        >>> hex(c.A), c.FLAG_C
        ('0xad', False)
        """
        orig_c = self.FLAG_C
        val = getattr(self, reg.value)
        self.FLAG_C = bool(val & 0b10000000)
        val = ((val << 1) | orig_c) & 0xFF
        setattr(self, reg.value, val)
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_Z = val == 0

    # ===================================
    # 7. RRC
    def _rrc(self, reg: Reg):
        val = getattr(self, reg.value)
        self.FLAG_C = bool(val & 0x1)
        val >>= 1
        if self.FLAG_C:
            val |= 0b10000000
        setattr(self, reg.value, val)
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_Z = val == 0

    # ===================================
    # 8. RR
    def _rr(self, reg: Reg):
        orig_c = self.FLAG_C
        val = getattr(self, reg.value)
        self.FLAG_C = bool(val & 0x1)
        val >>= 1
        if orig_c:
            val |= 1 << 7
        setattr(self, reg.value, val)
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_Z = val == 0

    # ===================================
    # 9. SLA
    def _sla(self, reg: Reg):
        val = getattr(self, reg.value)
        self.FLAG_C = bool(val & 0b10000000)
        val <<= 1
        val &= 0xFF
        setattr(self, reg.value, val)
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_Z = val == 0

    # ===================================
    # 10. SRA
    def _sra(self, reg: Reg):
        val = getattr(self, reg.value)
        self.FLAG_C = bool(val & 0x1)
        val >>= 1
        if val & 0b01000000:
            val |= 0b10000000
        setattr(self, reg.value, val)
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_Z = val == 0

    # ===================================
    # 11. SRL
    def _srl(self, reg: Reg):
        val = getattr(self, reg.value)
        self.FLAG_C = bool(val & 0x1)
        val >>= 1
        setattr(self, reg.value, val)
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_Z = val == 0

    # </editor-fold>

    # <editor-fold description="3.3.7 Bit Opcodes">
    # ===================================
    # 1. BIT b,r
    def _test_bit(self):
        """
        >>> c = CPU()
        >>> c.B = 0xFF
        >>> c.opCB40()  # BIT 0,B
        >>> c.FLAG_Z
        True
        >>> c.opCB78()  # BIT 7,B
        >>> c.FLAG_Z
        True
        >>> c.B = 0x00
        >>> c.opCB40()
        >>> c.FLAG_Z
        False
        >>> c.opCB78()
        >>> c.FLAG_Z
        False
        """
    for b in range(8):
        for offset, reg in enumerate(GEN_REGS):
            op = 0x40 + b * 0x08 + offset
            time = 16 if reg == "[HL]" else 8
            arg = reg.replace("[HL]", "MEM_AT_HL")
            exec(dedent(f"""
                @opcode("BIT {b},{reg}", {time})
                def opCB{op:02X}(self):
                    self.FLAG_Z = not bool(self.{arg} & (1 << {b}))
                    self.FLAG_N = False
                    self.FLAG_H = True
            """))

    # ===================================
    # 2. SET b,r
    for b in range(8):
        for offset, arg in enumerate(GEN_REGS):
            op = 0x80 + b * 0x08 + offset
            time = 16 if arg == "[HL]" else 8
            arg = arg.replace("[HL]", "MEM_AT_HL")
            exec(dedent(f"""
                @opcode("RES {b},{arg}", {time})
                def opCB{op:02X}(self):
                    self.{arg} &= ((0x01 << {b}) ^ 0xFF)
            """))

    # ===================================
    # 3. RES b,r
    for b in range(8):
        for offset, arg in enumerate(GEN_REGS):
            op = 0xC0 + b * 0x08 + offset
            time = 16 if arg == "[HL]" else 8
            arg = arg.replace("[HL]", "MEM_AT_HL")
            exec(dedent(f"""
                @opcode("SET {b},{arg}", {time})
                def opCB{op:02X}(self):
                    self.{arg} |= (0x01 << {b})
            """))

    # </editor-fold>

    # <editor-fold description="3.3.8 Jumps">
    # ===================================
    # 1. JP nn
    @opcode("JP nn", 16, "H")  # doc says 12
    def opC3(self, nn):
        self.PC = nn

    # ===================================
    # 2. JP cc,nn
    # Absolute jump if given flag is not set / set
    @opcode("JP NZ,n", 12, "H")
    def opC2(self, n):
        if not self.FLAG_Z:
            self.PC = n

    @opcode("JP Z,n", 12, "H")
    def opCA(self, n):
        if self.FLAG_Z:
            self.PC = n

    @opcode("JP NC,n", 12, "H")
    def opD2(self, n):
        if not self.FLAG_C:
            self.PC = n

    @opcode("JP C,n", 12, "H")
    def opDA(self, n):
        if self.FLAG_C:
            self.PC = n

    # ===================================
    # 3. JP [HL]
    @opcode("JP HL", 4)
    def opE9(self):
        # ERROR: docs say this is [HL], not HL...
        self.PC = self.HL

    # ===================================
    # 4. JR n
    @opcode("JR n", 12, "b")  # doc says 8
    def op18(self, n):
        self.PC += n

    # ===================================
    # 5. JR cc,n
    # Relative jump if given flag is not set / set
    @opcode("JR NZ,n", 8, "b")
    def op20(self, n):
        if not self.FLAG_Z:
            self.PC += n

    @opcode("JR Z,n", 8, "b")
    def op28(self, n):
        if self.FLAG_Z:
            self.PC += n

    @opcode("JR NC,n", 8, "b")
    def op30(self, n):
        if not self.FLAG_C:
            self.PC += n

    @opcode("JR C,n", 8, "b")
    def op38(self, n):
        if self.FLAG_C:
            self.PC += n
    # </editor-fold>

    # <editor-fold description="3.3.9 Calls">
    # ===================================
    # 1. CALL nn
    @opcode("CALL nn", 24, "H")  # doc says 12
    def opCD(self, nn):
        self._push16(Reg.PC)
        self.PC = nn

    # ===================================
    # 2. CALL cc,nn
    # Absolute call if given flag is not set / set
    @opcode("CALL NZ,nn", 12, "H")
    def opC4(self, n):
        if not self.FLAG_Z:
            self._push16(Reg.PC)
            self.PC = n

    @opcode("CALL Z,nn", 12, "H")
    def opCC(self, n):
        if self.FLAG_Z:
            self._push16(Reg.PC)
            self.PC = n

    @opcode("CALL NC,nn", 12, "H")
    def opD4(self, n):
        if not self.FLAG_C:
            self._push16(Reg.PC)
            self.PC = n

    @opcode("CALL C,nn", 12, "H")
    def opDC(self, n):
        if self.FLAG_C:
            self._push16(Reg.PC)
            self.PC = n

    # </editor-fold>

    # <editor-fold description="3.3.10 Restarts">
    # ===================================
    # 1. RST n
    # Push present address onto stack.
    # Jump to address $0000 + n.
    # n = $00,$08,$10,$18,$20,$28,$30,$38
    def _rst(self, val):
        self._push16(Reg.PC)
        self.PC = val

    # doc says 32 cycles, test says 16
    opC7 = opcode("RST 00", 16)(lambda self: self._rst(0x00))
    opCF = opcode("RST 08", 16)(lambda self: self._rst(0x08))
    opD7 = opcode("RST 10", 16)(lambda self: self._rst(0x10))
    opDF = opcode("RST 18", 16)(lambda self: self._rst(0x18))
    opE7 = opcode("RST 20", 16)(lambda self: self._rst(0x20))
    opEF = opcode("RST 28", 16)(lambda self: self._rst(0x28))
    opF7 = opcode("RST 30", 16)(lambda self: self._rst(0x30))
    opFF = opcode("RST 38", 16)(lambda self: self._rst(0x38))
    # </editor-fold>

    # <editor-fold description="3.3.11 Returns">

    # ===================================
    # 1. RET
    @opcode("RET", 16)  # doc says 8
    def opC9(self):
        self._pop16(Reg.PC)

    # ===================================
    # 2. RET cc
    @opcode("RET NZ", 8)
    def opC0(self):
        if not self.FLAG_Z:
            self._pop16(Reg.PC)

    @opcode("RET Z", 8)
    def opC8(self):
        if self.FLAG_Z:
            self._pop16(Reg.PC)

    @opcode("RET NC", 8)
    def opD0(self):
        if not self.FLAG_C:
            self._pop16(Reg.PC)

    @opcode("RET C", 8)
    def opD8(self):
        if self.FLAG_C:
            self._pop16(Reg.PC)

    # ===================================
    # 3. RETI
    @opcode("RETI", 16)  # doc says 8
    def opD9(self):
        self._pop16(Reg.PC)
        self.interrupts = True

    # </editor-fold>
