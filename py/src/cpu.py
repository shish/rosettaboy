import typing as t
import sys

from .errors import UnitTestPassed, UnitTestFailed, InvalidOpcode
from .ram import RAM
from .consts import *


# fmt: off
OP_CYCLES: t.Final[t.List[int]] = [
    # 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    1, 3, 2, 2, 1, 1, 2, 1, 5, 2, 2, 2, 1, 1, 2, 1, # 0
    0, 3, 2, 2, 1, 1, 2, 1, 3, 2, 2, 2, 1, 1, 2, 1, # 1
    2, 3, 2, 2, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 2, 1, # 2
    2, 3, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 1, 1, 2, 1, # 3
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, # 4
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, # 5
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, # 6
    2, 2, 2, 2, 2, 2, 0, 2, 1, 1, 1, 1, 1, 1, 2, 1, # 7
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, # 8
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, # 9
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, # A
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, # B
    2, 3, 3, 4, 3, 4, 2, 4, 2, 4, 3, 0, 3, 6, 2, 4, # C
    2, 3, 3, 0, 3, 4, 2, 4, 2, 4, 3, 0, 3, 0, 2, 4, # D
    3, 3, 2, 0, 0, 4, 2, 4, 4, 1, 4, 0, 0, 0, 2, 4, # E
    3, 3, 2, 1, 0, 4, 2, 4, 3, 2, 4, 1, 0, 0, 2, 4, # F
]

OP_CB_CYCLES: t.Final[t.List[int]] = [
    # 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # 0
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # 1
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # 2
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # 3
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, # 4
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, # 5
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, # 6
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, # 7
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # 8
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # 9
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # A
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # B
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # C
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # D
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # E
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, # F
]

OP_TYPES: t.Final[t.List[int]] = [
    # 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 2, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 1, 0, # 0
    1, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, # 1
    3, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, # 2
    3, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, # 3
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, # 4
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, # 5
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, # 6
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, # 7
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, # 8
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, # 9
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, # A
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, # B
    0, 0, 2, 2, 2, 0, 1, 0, 0, 0, 2, 0, 2, 2, 1, 0, # C
    0, 0, 2, 0, 2, 0, 1, 0, 0, 0, 2, 0, 2, 0, 1, 0, # D
    1, 0, 0, 0, 0, 0, 1, 0, 3, 0, 2, 0, 0, 0, 1, 0, # E
    1, 0, 0, 0, 0, 0, 1, 0, 3, 0, 2, 0, 0, 0, 1, 0, # F
]

# no arg, u8, u16, i8
OP_LENS: t.Final[t.List[int]] = [0, 1, 2, 1]

OP_NAMES: t.Final[t.List[str]] = [
    "NOP",          "LD BC,$u16", "LD [BC],A",   "INC BC",    "INC B",        "DEC B",     "LD B,$u8",    "RCLA",
    "LD [$u16],SP", "ADD HL,BC",  "LD A,[BC]",   "DEC BC",    "INC C",        "DEC C",     "LD C,$u8",    "RRCA",
    "STOP",         "LD DE,$u16", "LD [DE],A",   "INC DE",    "INC D",        "DEC D",     "LD D,$u8",    "RLA",
    "JR i8",        "ADD HL,DE",  "LD A,[DE]",   "DEC DE",    "INC E",        "DEC E",     "LD E,$u8",    "RRA",
    "JR NZ,i8",     "LD HL,$u16", "LD [HL+],A",  "INC HL",    "INC H",        "DEC H",     "LD H,$u8",    "DAA",
    "JR Z,i8",      "ADD HL,HL",  "LD A,[HL+]",  "DEC HL",    "INC L",        "DEC L",     "LD L,$u8",    "CPL",
    "JR NC,i8",     "LD SP,$u16", "LD [HL-],A",  "INC SP",    "INC [HL]",     "DEC [HL]",  "LD [HL],$u8", "SCF",
    "JR C,i8",      "ADD HL,SP",  "LD A,[HL-]",  "DEC SP",    "INC A",        "DEC A",     "LD A,$u8",    "CCF",
    "LD B,B",       "LD B,C",     "LD B,D",      "LD B,E",    "LD B,H",       "LD B,L",    "LD B,[HL]",   "LD B,A",
    "LD C,B",       "LD C,C",     "LD C,D",      "LD C,E",    "LD C,H",       "LD C,L",    "LD C,[HL]",   "LD C,A",
    "LD D,B",       "LD D,C",     "LD D,D",      "LD D,E",    "LD D,H",       "LD D,L",    "LD D,[HL]",   "LD D,A",
    "LD E,B",       "LD E,C",     "LD E,D",      "LD E,E",    "LD E,H",       "LD E,L",    "LD E,[HL]",   "LD E,A",
    "LD H,B",       "LD H,C",     "LD H,D",      "LD H,E",    "LD H,H",       "LD H,L",    "LD H,[HL]",   "LD H,A",
    "LD L,B",       "LD L,C",     "LD L,D",      "LD L,E",    "LD L,H",       "LD L,L",    "LD L,[HL]",   "LD L,A",
    "LD [HL],B",    "LD [HL],C",  "LD [HL],D",   "LD [HL],E", "LD [HL],H",    "LD [HL],L", "HALT",        "LD [HL],A",
    "LD A,B",       "LD A,C",     "LD A,D",      "LD A,E",    "LD A,H",       "LD A,L",    "LD A,[HL]",   "LD A,A",
    "ADD A,B",      "ADD A,C",    "ADD A,D",     "ADD A,E",   "ADD A,H",      "ADD A,L",   "ADD A,[HL]",  "ADD A,A",
    "ADC A,B",      "ADC A,C",    "ADC A,D",     "ADC A,E",   "ADC A,H",      "ADC A,L",   "ADC A,[HL]",  "ADC A,A",
    "SUB A,B",      "SUB A,C",    "SUB A,D",     "SUB A,E",   "SUB A,H",      "SUB A,L",   "SUB A,[HL]",  "SUB A,A",
    "SBC A,B",      "SBC A,C",    "SBC A,D",     "SBC A,E",   "SBC A,H",      "SBC A,L",   "SBC A,[HL]",  "SBC A,A",
    "AND B",        "AND C",      "AND D",       "AND E",     "AND H",        "AND L",     "AND [HL]",    "AND A",
    "XOR B",        "XOR C",      "XOR D",       "XOR E",     "XOR H",        "XOR L",     "XOR [HL]",    "XOR A",
    "OR B",         "OR C",       "OR D",        "OR E",      "OR H",         "OR L",      "OR [HL]",     "OR A",
    "CP B",         "CP C",       "CP D",        "CP E",      "CP H",         "CP L",      "CP [HL]",     "CP A",
    "RET NZ",       "POP BC",     "JP NZ,$u16",  "JP $u16",   "CALL NZ,$u16", "PUSH BC",   "ADD A,$u8",   "RST 00",
    "RET Z",        "RET",        "JP Z,$u16",   "ERR CB",    "CALL Z,$u16",  "CALL $u16", "ADC A,$u8",   "RST 08",
    "RET NC",       "POP DE",     "JP NC,$u16",  "ERR D3",    "CALL NC,$u16", "PUSH DE",   "SUB A,$u8",   "RST 10",
    "RET C",        "RETI",       "JP C,$u16",   "ERR DB",    "CALL C,$u16",  "ERR DD",    "SBC A,$u8",   "RST 18",
    "LDH [$u8],A",  "POP HL",     "LDH [C],A",   "DBG",       "ERR E4",       "PUSH HL",   "AND $u8",     "RST 20",
    "ADD SP i8",    "JP HL",      "LD [$u16],A", "ERR EB",    "ERR EC",       "ERR ED",    "XOR $u8",     "RST 28",
    "LDH A,[$u8]",  "POP AF",     "LDH A,[C]",   "DI",        "ERR F4",       "PUSH AF",   "OR $u8",      "RST 30",
    "LD HL,SPi8",   "LD SP,HL",   "LD A,[$u16]", "EI",        "ERR FC",       "ERR FD",    "CP $u8",      "RST 38",
]

OP_CB_NAMES: t.Final[t.List[str]] = [
    "RLC B", "RLC C", "RLC D", "RLC E", "RLC H", "RLC L", "RLC [HL]", "RLC A",
    "RRC B", "RRC C", "RRC D", "RRC E", "RRC H", "RRC L", "RRC [HL]", "RRC A",
    "RL B", "RL C", "RL D", "RL E", "RL H", "RL L", "RL [HL]", "RL A",
    "RR B", "RR C", "RR D", "RR E", "RR H", "RR L", "RR [HL]", "RR A",
    "SLA B", "SLA C", "SLA D", "SLA E", "SLA H", "SLA L", "SLA [HL]", "SLA A",
    "SRA B", "SRA C", "SRA D", "SRA E", "SRA H", "SRA L", "SRA [HL]", "SRA A",
    "SWAP B", "SWAP C", "SWAP D", "SWAP E", "SWAP H", "SWAP L", "SWAP [HL]", "SWAP A",
    "SRL B", "SRL C", "SRL D", "SRL E", "SRL H", "SRL L", "SRL [HL]", "SRL A",
    "BIT 0,B", "BIT 0,C", "BIT 0,D", "BIT 0,E", "BIT 0,H", "BIT 0,L", "BIT 0,[HL]", "BIT 0,A",
    "BIT 1,B", "BIT 1,C", "BIT 1,D", "BIT 1,E", "BIT 1,H", "BIT 1,L", "BIT 1,[HL]", "BIT 1,A",
    "BIT 2,B", "BIT 2,C", "BIT 2,D", "BIT 2,E", "BIT 2,H", "BIT 2,L", "BIT 2,[HL]", "BIT 2,A",
    "BIT 3,B", "BIT 3,C", "BIT 3,D", "BIT 3,E", "BIT 3,H", "BIT 3,L", "BIT 3,[HL]", "BIT 3,A",
    "BIT 4,B", "BIT 4,C", "BIT 4,D", "BIT 4,E", "BIT 4,H", "BIT 4,L", "BIT 4,[HL]", "BIT 4,A",
    "BIT 5,B", "BIT 5,C", "BIT 5,D", "BIT 5,E", "BIT 5,H", "BIT 5,L", "BIT 5,[HL]", "BIT 5,A",
    "BIT 6,B", "BIT 6,C", "BIT 6,D", "BIT 6,E", "BIT 6,H", "BIT 6,L", "BIT 6,[HL]", "BIT 6,A",
    "BIT 7,B", "BIT 7,C", "BIT 7,D", "BIT 7,E", "BIT 7,H", "BIT 7,L", "BIT 7,[HL]", "BIT 7,A",
    "RES 0,B", "RES 0,C", "RES 0,D", "RES 0,E", "RES 0,H", "RES 0,L", "RES 0,[HL]", "RES 0,A",
    "RES 1,B", "RES 1,C", "RES 1,D", "RES 1,E", "RES 1,H", "RES 1,L", "RES 1,[HL]", "RES 1,A",
    "RES 2,B", "RES 2,C", "RES 2,D", "RES 2,E", "RES 2,H", "RES 2,L", "RES 2,[HL]", "RES 2,A",
    "RES 3,B", "RES 3,C", "RES 3,D", "RES 3,E", "RES 3,H", "RES 3,L", "RES 3,[HL]", "RES 3,A",
    "RES 4,B", "RES 4,C", "RES 4,D", "RES 4,E", "RES 4,H", "RES 4,L", "RES 4,[HL]", "RES 4,A",
    "RES 5,B", "RES 5,C", "RES 5,D", "RES 5,E", "RES 5,H", "RES 5,L", "RES 5,[HL]", "RES 5,A",
    "RES 6,B", "RES 6,C", "RES 6,D", "RES 6,E", "RES 6,H", "RES 6,L", "RES 6,[HL]", "RES 6,A",
    "RES 7,B", "RES 7,C", "RES 7,D", "RES 7,E", "RES 7,H", "RES 7,L", "RES 7,[HL]", "RES 7,A",
    "SET 0,B", "SET 0,C", "SET 0,D", "SET 0,E", "SET 0,H", "SET 0,L", "SET 0,[HL]", "SET 0,A",
    "SET 1,B", "SET 1,C", "SET 1,D", "SET 1,E", "SET 1,H", "SET 1,L", "SET 1,[HL]", "SET 1,A",
    "SET 2,B", "SET 2,C", "SET 2,D", "SET 2,E", "SET 2,H", "SET 2,L", "SET 2,[HL]", "SET 2,A",
    "SET 3,B", "SET 3,C", "SET 3,D", "SET 3,E", "SET 3,H", "SET 3,L", "SET 3,[HL]", "SET 3,A",
    "SET 4,B", "SET 4,C", "SET 4,D", "SET 4,E", "SET 4,H", "SET 4,L", "SET 4,[HL]", "SET 4,A",
    "SET 5,B", "SET 5,C", "SET 5,D", "SET 5,E", "SET 5,H", "SET 5,L", "SET 5,[HL]", "SET 5,A",
    "SET 6,B", "SET 6,C", "SET 6,D", "SET 6,E", "SET 6,H", "SET 6,L", "SET 6,[HL]", "SET 6,A",
    "SET 7,B", "SET 7,C", "SET 7,D", "SET 7,E", "SET 7,H", "SET 7,L", "SET 7,[HL]", "SET 7,A",
]
# fmt: on


class OpArg:
    def __init__(self, ram: RAM, addr: u16, arg_type: int):
        self.u8: u8 = 0
        self.i8: i8 = 0
        self.u16: u16 = 0

        if arg_type == 0:
            pass
        elif arg_type == 1:
            self.u8 = ram[addr]
        elif arg_type == 2:
            self.u16 = ram[addr] | ram[addr + 1] << 8
        elif arg_type == 3:
            self.i8 = ram[addr]
            if self.i8 > 127:
                self.i8 -= 256
        else:
            raise Exception(f"Unknown arg type: {arg_type}")


class CPU:
    def __init__(self, ram: RAM, debug: bool = False) -> None:
        self.ram = ram
        self.interrupts = True
        self.halt = False
        self.stop = False
        self.cycle = 0
        self._nopslide = 0
        self._debug = debug
        self._debug_str = ""
        self._owed_cycles = 0

        # registers
        self.A = 0
        self.B = 0
        self.C = 0
        self.D = 0
        self.E = 0
        self.H = 0
        self.L = 0

        self.SP = 0x0000
        self.PC = 0x0000

        self.FLAG_Z: bool = False
        self.FLAG_N: bool = False
        self.FLAG_H: bool = False
        self.FLAG_C: bool = False

    @property
    def AF(self) -> int:
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
            self.A << 8
            | (self.FLAG_Z or 0) << 7
            | (self.FLAG_N or 0) << 6
            | (self.FLAG_H or 0) << 5
            | (self.FLAG_C or 0) << 4
        )

    @AF.setter
    def AF(self, val: int) -> None:
        self.A = val >> 8 & 0xFF
        self.FLAG_Z = bool(val & 0b10000000)
        self.FLAG_N = bool(val & 0b01000000)
        self.FLAG_H = bool(val & 0b00100000)
        self.FLAG_C = bool(val & 0b00010000)

    @property
    def BC(self) -> int:
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
    def BC(self, val: int) -> None:
        self.B = val >> 8 & 0xFF
        self.C = val & 0xFF

    @property
    def DE(self) -> int:
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
    def DE(self, val: int) -> None:
        self.D = val >> 8 & 0xFF
        self.E = val & 0xFF

    @property
    def HL(self) -> int:
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
    def HL(self, val: int) -> None:
        self.H = val >> 8 & 0xFF
        self.L = val & 0xFF

    @property
    def MEM_AT_HL(self) -> int:
        return self.ram[self.HL]

    @MEM_AT_HL.setter
    def MEM_AT_HL(self, val: int) -> None:
        self.ram[self.HL] = val

    def dump_regs(self) -> None:
        # stack
        sp_val = self.ram[self.SP] | self.ram[(self.SP + 1) & 0xFFFF] << 8

        # interrupts
        ien = self.ram[Mem.IE]
        ifl = self.ram[Mem.IF]

        def flag(i: int, c: str) -> str:
            if ien & i != 0:
                if ifl & i != 0:
                    return c.upper()
                else:
                    return c
            else:
                return "_"

        v = flag(Interrupt.VBLANK, "v")
        l = flag(Interrupt.STAT, "l")
        t = flag(Interrupt.TIMER, "t")
        s = flag(Interrupt.SERIAL, "s")
        j = flag(Interrupt.JOYPAD, "j")

        # opcode & args
        op = self.ram[self.PC]
        if op == 0xCB:
            op = self.ram[self.PC + 1]
            op_str = OP_CB_NAMES[op]
        else:
            base = OP_NAMES[op]
            arg = OpArg(self.ram, self.PC + 1, OP_TYPES[op])
            match OP_TYPES[op]:
                case 0:
                    op_str = base
                case 1:
                    op_str = base.replace("u8", f"{arg.u8:02X}")
                case 2:
                    op_str = base.replace("u16", f"{arg.u16:04X}")
                case 3:
                    op_str = base.replace("i8", f"{arg.i8:+d}")
                case _:
                    raise Exception("Unreachable")

        # print
        print(
            "{:04X} {:04X} {:04X} {:04X} : {:04X} = {:04X} : {}{}{}{} : {}{}{}{}{} : {:04X} = {:02X} : {}".format(
                self.AF,
                self.BC,
                self.DE,
                self.HL,
                self.SP,
                sp_val,
                "Z" if self.FLAG_Z else "z",
                "N" if self.FLAG_N else "n",
                "H" if self.FLAG_H else "h",
                "C" if self.FLAG_C else "c",
                v,
                l,
                t,
                s,
                j,
                self.PC,
                op,
                op_str,
            )
        )

    def interrupt(self, i: int) -> None:
        """
        Set a given interrupt bit - on the next tick, if the interrupt
        handler for this interrupt is enabled (and interrupts in general
        are enabled), then the interrupt handler will be called.
        """
        self.ram[Mem.IF] |= i
        self.halt = False  # interrupts interrupt HALT state

    def tick(self) -> None:
        self.tick_dma()
        self.tick_clock()
        self.tick_interrupts()
        if self.halt:
            return
        if self.stop:
            return
        self.tick_instructions()

    def tick_dma(self) -> None:
        """
        If there is a non-zero value in ram[Mem.DMA], eg 0x42, then
        we should copy memory from eg 0x4200 to OAM space.
        """
        # TODO: DMA should take 26 cycles, during which main RAM is inaccessible
        if self.ram[Mem.DMA]:
            dma_src = self.ram[Mem.DMA] << 8
            for i in range(0, 0xA0):
                self.ram[Mem.OAM_BASE + i] = self.ram[dma_src + i]
            self.ram[Mem.DMA] = 0x00

    def tick_clock(self) -> None:
        """
        Increment the timer registers, and send an interrupt
        when `ram[Mem.TIMA]` wraps around.
        """
        self.cycle += 1

        # TODO: writing any value to Mem.:DIV should reset it to 0x00
        # increment at 16384Hz (each 64 cycles?)
        if self.cycle % 64 == 0:
            self.ram[Mem.DIV] = (self.ram[Mem.DIV] + 1) & 0xFF

        if self.ram[Mem.TAC] & 1 << 2 == 1 << 2:
            # timer enable
            speeds = [256, 4, 16, 64]  # increment per X cycles
            speed = speeds[self.ram[Mem.TAC] & 0x03]
            if self.cycle % speed == 0:
                if self.ram[Mem.TIMA] == 0xFF:
                    self.ram[Mem.TIMA] = self.ram[
                        Mem.TMA
                    ]  # if timer overflows, load base
                    self.interrupt(Interrupt.TIMER)
                self.ram[Mem.TIMA] += 1

    def check_interrupt(self, queue: u8, i: u8, handler: u16) -> bool:
        if queue & i:
            # TODO: wait two cycles
            # TODO: push(PC) should also take two cycles
            # TODO: one more cycle to store new PC
            self.push(self.PC)
            self.PC = handler
            self.ram[Mem.IF] &= ~i
            return True
        return False

    def tick_interrupts(self) -> None:
        """
        Compare Interrupt Enabled and Interrupt Flag registers - if
        there are any interrupts which are both enabled and flagged,
        clear the flag and call the handler for the first of them.
        """
        queue = self.ram[Mem.IE] & self.ram[Mem.IF]
        if self.interrupts and queue:
            if self._debug:
                print(
                    f"Handling interrupts: {self.ram[Mem.IE]:02X} & {self.ram[Mem.IF]:02X}"
                )

            # no nested interrupts, RETI will re-enable
            self.interrupts = False

            (
                self.check_interrupt(queue, Interrupt.VBLANK, Mem.VBLANK_HANDLER)
                or self.check_interrupt(queue, Interrupt.STAT, Mem.LCD_HANDLER)
                or self.check_interrupt(queue, Interrupt.TIMER, Mem.TIMER_HANDLER)
                or self.check_interrupt(queue, Interrupt.SERIAL, Mem.SERIAL_HANDLER)
                or self.check_interrupt(queue, Interrupt.JOYPAD, Mem.JOYPAD_HANDLER)
            )

    def tick_instructions(self) -> None:
        # if the previous instruction was large, let's not run any
        # more instructions until other subsystems have caught up
        if self._owed_cycles > 0:
            self._owed_cycles -= 1
            return

        if self._debug:
            self.dump_regs()

        op = self.ram[self.PC]
        self.PC += 1
        if op == 0xCB:
            op = self.ram[self.PC]
            self.PC += 1
            self.tick_cb(op)
            self._owed_cycles = OP_CB_CYCLES[op]
        else:
            self.tick_main(op)
            self._owed_cycles = OP_CYCLES[op]

        # HALT has cycles=0
        if self._owed_cycles > 0:
            self._owed_cycles -= 1

    def tick_main(self, op: int) -> None:
        arg_type = OP_TYPES[op]
        arg_len = OP_LENS[arg_type]
        arg = OpArg(self.ram, self.PC, arg_type)
        self.PC += arg_len
        ram = self.ram

        match op:
            case 0x00:
                pass  # NOP
            case 0x01:
                self.BC = arg.u16

            case 0x02:
                ram[self.BC] = self.A

            case 0x03:
                self.BC = (self.BC + 1) & 0xFFFF

            case 0x08:
                ram[arg.u16 + 1] = (self.SP >> 8) & 0xFF
                ram[arg.u16] = self.SP & 0xFF

            case 0x0A:
                self.A = ram[self.BC]

            case 0x0B:
                self.BC = (self.BC - 1) & 0xFFFF

            case 0x10:
                self.stop = True

            case 0x11:
                self.DE = arg.u16

            case 0x12:
                ram[self.DE] = self.A

            case 0x13:
                self.DE = (self.DE + 1) & 0xFFFF

            case 0x18:
                self.PC = (self.PC + arg.i8) & 0xFFFF

            case 0x1A:
                self.A = ram[self.DE]

            case 0x1B:
                self.DE = (self.DE - 1) & 0xFFFF

            case 0x20:
                if not self.FLAG_Z:
                    self.PC = (self.PC + arg.i8) & 0xFFFF

            case 0x21:
                self.HL = arg.u16

            case 0x22:
                ram[self.HL] = self.A
                self.HL = (self.HL + 1) & 0xFFFF

            case 0x23:
                self.HL = (self.HL + 1) & 0xFFFF

            case 0x27:
                val16 = self.A
                if not self.FLAG_N:
                    if self.FLAG_H or (val16 & 0x0F) > 9:
                        val16 = (val16 + 6) & 0xFFFF

                    if self.FLAG_C or val16 > 0x9F:
                        val16 = (val16 + 0x60) & 0xFFFF

                else:
                    if self.FLAG_H:
                        val16 = (val16 - 6) & 0xFFFF
                        if not self.FLAG_C:
                            val16 &= 0xFF

                    if self.FLAG_C:
                        val16 = (val16 - 0x60) & 0xFFFF

                self.FLAG_H = False
                if val16 & 0x100 != 0:
                    self.FLAG_C = True

                self.A = val16 & 0xFF
                self.FLAG_Z = self.A == 0

            case 0x28:
                if self.FLAG_Z:
                    self.PC = (self.PC + arg.i8) & 0xFFFF

            case 0x2A:
                self.A = ram[self.HL]
                self.HL = (self.HL + 1) & 0xFFFF

            case 0x2B:
                self.HL = (self.HL - 1) & 0xFFFF

            case 0x2F:
                self.A ^= 0xFF
                self.FLAG_N = True
                self.FLAG_H = True

            case 0x30:
                if not self.FLAG_C:
                    self.PC = (self.PC + arg.i8) & 0xFFFF

            case 0x31:
                self.SP = arg.u16

            case 0x32:
                ram[self.HL] = self.A
                self.HL = (self.HL - 1) & 0xFFFF
            case 0x33:
                self.SP = (self.SP + 1) & 0xFFFF

            case 0x37:
                self.FLAG_N = False
                self.FLAG_H = False
                self.FLAG_C = True

            case 0x38:
                if self.FLAG_C:
                    self.PC = (self.PC + arg.i8) & 0xFFFF

            case 0x3A:
                self.A = ram[self.HL]
                self.HL = (self.HL - 1) & 0xFFFF

            case 0x3B:
                self.SP = (self.SP - 1) & 0xFFFF

            case 0x3F:
                self.FLAG_C = not self.FLAG_C
                self.FLAG_N = False
                self.FLAG_H = False

            # INC r
            case 0x04 | 0x0C | 0x14 | 0x1C | 0x24 | 0x2C | 0x34 | 0x3C:
                val = self.get_reg((op - 0x04) >> 3)
                self.FLAG_H = (val & 0x0F) == 0x0F
                self.FLAG_Z = (val + 1) & 0xFF == 0
                self.FLAG_N = False
                self.set_reg((op - 0x04) >> 3, (val + 1) & 0xFF)

            # DEC r
            case 0x05 | 0x0D | 0x15 | 0x1D | 0x25 | 0x2D | 0x35 | 0x3D:
                val = self.get_reg((op - 0x05) >> 3)
                self.FLAG_H = ((val - 1) & 0xFF & 0x0F) == 0x0F
                self.FLAG_Z = (val - 1) & 0xFF == 0
                self.FLAG_N = True
                self.set_reg((op - 0x05) >> 3, (val - 1) & 0xFF)

            # LD r,n
            case 0x06 | 0x0E | 0x16 | 0x1E | 0x26 | 0x2E | 0x36 | 0x3E:
                self.set_reg((op - 0x06) >> 3, arg.u8)

            # RCLA, RLA, RRCA, RRA
            case 0x07 | 0x17 | 0x0F | 0x1F:
                carry = 1 if self.FLAG_C else 0
                if op == 0x07:
                    # RCLA
                    self.FLAG_C = (self.A & 1 << 7) != 0
                    self.A = (self.A << 1) | (self.A >> 7)

                if op == 0x17:
                    # RLA
                    self.FLAG_C = (self.A & 1 << 7) != 0
                    self.A = (self.A << 1) | carry

                if op == 0x0F:
                    # RRCA
                    self.FLAG_C = (self.A & 1 << 0) != 0
                    self.A = (self.A >> 1) | (self.A << 7)

                if op == 0x1F:
                    # RRA
                    self.FLAG_C = (self.A & 1 << 0) != 0
                    self.A = (self.A >> 1) | (carry << 7)

                self.A &= 0xFF

                self.FLAG_N = False
                self.FLAG_H = False
                self.FLAG_Z = False

            # ADD HL,rr
            case 0x09 | 0x19 | 0x29 | 0x39:
                match op:
                    case 0x09:
                        val16 = self.BC
                    case 0x19:
                        val16 = self.DE
                    case 0x29:
                        val16 = self.HL
                    case 0x39:
                        val16 = self.SP
                    case _:
                        raise Exception("Unreachable")

                self.FLAG_H = (self.HL & 0x0FFF) + (val16 & 0x0FFF) > 0x0FFF
                self.FLAG_C = (self.HL + val16) > 0xFFFF
                self.HL = (self.HL + val16) & 0xFFFF
                self.FLAG_N = False

            case 0x40 | 0x41 | 0x42 | 0x43 | 0x44 | 0x45 | 0x46 | 0x47 | 0x48 | 0x49 | 0x4A | 0x4B | 0x4C | 0x4D | 0x4E | 0x4F | 0x50 | 0x51 | 0x52 | 0x53 | 0x54 | 0x55 | 0x56 | 0x57 | 0x58 | 0x59 | 0x5A | 0x5B | 0x5C | 0x5D | 0x5E | 0x5F | 0x60 | 0x61 | 0x62 | 0x63 | 0x64 | 0x65 | 0x66 | 0x67 | 0x68 | 0x69 | 0x6A | 0x6B | 0x6C | 0x6D | 0x6E | 0x6F | 0x70 | 0x71 | 0x72 | 0x73 | 0x74 | 0x75 | 0x76 | 0x77 | 0x78 | 0x79 | 0x7A | 0x7B | 0x7C | 0x7D | 0x7E | 0x7F:
                # LD r,r
                if op == 0x76:
                    # FIXME: weird timing side effects
                    self.halt = True

                self.set_reg((op - 0x40) >> 3, self.get_reg(op - 0x40))

            # <math> <reg>
            case 0x80 | 0x81 | 0x82 | 0x83 | 0x84 | 0x85 | 0x86 | 0x87:
                self._add(self.get_reg(op))
            case 0x88 | 0x89 | 0x8A | 0x8B | 0x8C | 0x8D | 0x8E | 0x8F:
                self._adc(self.get_reg(op))
            case 0x90 | 0x91 | 0x92 | 0x93 | 0x94 | 0x95 | 0x96 | 0x97:
                self._sub(self.get_reg(op))
            case 0x98 | 0x99 | 0x9A | 0x9B | 0x9C | 0x9D | 0x9E | 0x9F:
                self._sbc(self.get_reg(op))
            case 0xA0 | 0xA1 | 0xA2 | 0xA3 | 0xA4 | 0xA5 | 0xA6 | 0xA7:
                self._and(self.get_reg(op))
            case 0xA8 | 0xA9 | 0xAA | 0xAB | 0xAC | 0xAD | 0xAE | 0xAF:
                self._xor(self.get_reg(op))
            case 0xB0 | 0xB1 | 0xB2 | 0xB3 | 0xB4 | 0xB5 | 0xB6 | 0xB7:
                self._or(self.get_reg(op))
            case 0xB8 | 0xB9 | 0xBA | 0xBB | 0xBC | 0xBD | 0xBE | 0xBF:
                self._cp(self.get_reg(op))

            case 0xC0:
                if not self.FLAG_Z:
                    self.PC = self.pop()

            case 0xC1:
                self.BC = self.pop()

            case 0xC2:
                if not self.FLAG_Z:
                    self.PC = arg.u16

            case 0xC3:
                self.PC = arg.u16

            case 0xC4:
                if not self.FLAG_Z:
                    self.push(self.PC)
                    self.PC = arg.u16

            case 0xC5:
                self.push(self.BC)

            case 0xC6:
                self._add(arg.u8)

            case 0xC7:
                self.push(self.PC)
                self.PC = 0x00

            case 0xC8:
                if self.FLAG_Z:
                    self.PC = self.pop()

            case 0xC9:
                self.PC = self.pop()

            case 0xCA:
                if self.FLAG_Z:
                    self.PC = arg.u16

            case 0xCC:
                if self.FLAG_Z:
                    self.push(self.PC)
                    self.PC = arg.u16

            case 0xCD:
                self.push(self.PC)
                self.PC = arg.u16

            case 0xCE:
                self._adc(arg.u8)

            case 0xCF:
                self.push(self.PC)
                self.PC = 0x08

            case 0xD0:
                if not self.FLAG_C:
                    self.PC = self.pop()

            case 0xD1:
                self.DE = self.pop()

            case 0xD2:
                if not self.FLAG_C:
                    self.PC = arg.u16

            case 0xD4:
                if not self.FLAG_C:
                    self.push(self.PC)
                    self.PC = arg.u16

            case 0xD5:
                self.push(self.DE)

            case 0xD6:
                self._sub(arg.u8)

            case 0xD7:
                self.push(self.PC)
                self.PC = 0x10

            case 0xD8:
                if self.FLAG_C:
                    self.PC = self.pop()

            case 0xD9:
                self.PC = self.pop()
                self.interrupts = True

            case 0xDA:
                if self.FLAG_C:
                    self.PC = arg.u16

            case 0xDC:
                if self.FLAG_C:
                    self.push(self.PC)
                    self.PC = arg.u16

            case 0xDE:
                self._sbc(arg.u8)

            case 0xDF:
                self.push(self.PC)
                self.PC = 0x18

            case 0xE0:
                ram[0xFF00 + arg.u8] = self.A
                if arg.u8 == 0x01:
                    sys.stdout.write(chr(self.A))

            case 0xE1:
                self.HL = self.pop()

            case 0xE2:
                ram[0xFF00 + self.C] = self.A
                if self.C == 0x01:
                    sys.stdout.write(chr(self.A))

            # 0xE3 => self._err(op),
            # 0xE4 => self._err(op),
            case 0xE5:
                self.push(self.HL)

            case 0xE6:
                self._and(arg.u8)

            case 0xE7:
                self.push(self.PC)
                self.PC = 0x20

            case 0xE8:
                val16 = (self.SP + arg.i8) & 0xFFFF
                # self.FLAG_H = ((self.SP & 0x0FFF) + (arg.i8 & 0x0FFF) > 0x0FFF)
                # self.FLAG_C = (self.SP + arg.i8 > 0xFFFF)
                self.FLAG_H = ((self.SP ^ arg.i8 ^ val16) & 0x10) != 0
                self.FLAG_C = ((self.SP ^ arg.i8 ^ val16) & 0x100) != 0
                self.SP = (self.SP + arg.i8) & 0xFFFF

                self.FLAG_Z = False
                self.FLAG_N = False

            case 0xE9:
                self.PC = self.HL

            case 0xEA:
                ram[arg.u16] = self.A

            case 0xEE:
                self._xor(arg.u8)

            case 0xEF:
                self.push(self.PC)
                self.PC = 0x28

            case 0xF0:
                self.A = ram[0xFF00 + arg.u8]

            case 0xF1:
                self.AF = self.pop() & 0xFFF0

            case 0xF2:
                self.A = ram[0xFF00 + self.C]

            case 0xF3:
                self.interrupts = False

            case 0xF5:
                self.push(self.AF)

            case 0xF6:
                self._or(arg.u8)
            case 0xF7:
                self.push(self.PC)
                self.PC = 0x30

            case 0xF8:
                new_hl = (self.SP + arg.i8) & 0xFFFF
                if arg.i8 >= 0:
                    self.FLAG_C = ((self.SP & 0xFF) + arg.i8) > 0xFF
                    self.FLAG_H = ((self.SP & 0x0F) + (arg.i8 & 0x0F)) > 0x0F
                else:
                    self.FLAG_C = (new_hl & 0xFF) <= (self.SP & 0xFF)
                    self.FLAG_H = (new_hl & 0x0F) <= (self.SP & 0x0F)

                self.HL = new_hl
                self.FLAG_Z = False
                self.FLAG_N = False

            case 0xF9:
                self.SP = self.HL
            case 0xFA:
                self.A = ram[arg.u16]
            case 0xFB:
                self.interrupts = True
            case 0xFC:
                raise UnitTestPassed()  # unofficial
            case 0xFD:
                raise UnitTestFailed()  # unofficial
            case 0xFE:
                self._cp(arg.u8)
            case 0xFF:
                self.push(self.PC)
                self.PC = 0x38

            case _:
                raise InvalidOpcode(op)

    def tick_cb(self, op: int) -> None:
        val = self.get_reg(op)
        match op & 0xF8:
            # RLC
            case 0x00 | 0x01 | 0x02 | 0x03 | 0x04 | 0x05 | 0x06 | 0x07:
                self.FLAG_C = (val & 1 << 7) != 0
                val <<= 1
                if self.FLAG_C:
                    val |= 1 << 0

                self.FLAG_N = False
                self.FLAG_H = False
                self.FLAG_Z = val == 0

            # RRC
            case 0x08 | 0x09 | 0x0A | 0x0B | 0x0C | 0x0D | 0x0E | 0x0F:
                self.FLAG_C = (val & 1 << 0) != 0
                val >>= 1
                if self.FLAG_C:
                    val |= 1 << 7

                self.FLAG_N = False
                self.FLAG_H = False
                self.FLAG_Z = val == 0

            # RL
            case 0x10 | 0x11 | 0x12 | 0x13 | 0x14 | 0x15 | 0x16 | 0x17:
                orig_c = self.FLAG_C
                self.FLAG_C = (val & 1 << 7) != 0
                val <<= 1
                if orig_c:
                    val |= 1 << 0

                self.FLAG_N = False
                self.FLAG_H = False
                self.FLAG_Z = val & 0xFF == 0

            # RR
            case 0x18 | 0x19 | 0x1A | 0x1B | 0x1C | 0x1D | 0x1E | 0x1F:
                orig_c = self.FLAG_C
                self.FLAG_C = (val & 1 << 0) != 0
                val >>= 1
                if orig_c:
                    val |= 1 << 7

                self.FLAG_N = False
                self.FLAG_H = False
                self.FLAG_Z = val == 0

            # SLA
            case 0x20 | 0x21 | 0x22 | 0x23 | 0x24 | 0x25 | 0x26 | 0x27:
                self.FLAG_C = (val & 1 << 7) != 0
                val <<= 1
                val &= 0xFF
                self.FLAG_N = False
                self.FLAG_H = False
                self.FLAG_Z = val == 0

            # SRA
            case 0x28 | 0x29 | 0x2A | 0x2B | 0x2C | 0x2D | 0x2E | 0x2F:
                self.FLAG_C = (val & 1 << 0) != 0
                val >>= 1
                if val & 1 << 6 != 0:
                    val |= 1 << 7

                self.FLAG_N = False
                self.FLAG_H = False
                self.FLAG_Z = val == 0

            # SWAP
            case 0x30 | 0x31 | 0x32 | 0x33 | 0x34 | 0x35 | 0x36 | 0x37:
                val = ((val & 0xF0) >> 4) | ((val & 0x0F) << 4)
                self.FLAG_C = False
                self.FLAG_N = False
                self.FLAG_H = False
                self.FLAG_Z = val == 0

            # SRL
            case 0x38 | 0x39 | 0x3A | 0x3B | 0x3C | 0x3D | 0x3E | 0x3F:
                self.FLAG_C = (val & 1 << 0) != 0
                val >>= 1
                self.FLAG_N = False
                self.FLAG_H = False
                self.FLAG_Z = val == 0

            # BIT
            case 0x40 | 0x41 | 0x42 | 0x43 | 0x44 | 0x45 | 0x46 | 0x47 | 0x48 | 0x49 | 0x4A | 0x4B | 0x4C | 0x4D | 0x4E | 0x4F | 0x50 | 0x51 | 0x52 | 0x53 | 0x54 | 0x55 | 0x56 | 0x57 | 0x58 | 0x59 | 0x5A | 0x5B | 0x5C | 0x5D | 0x5E | 0x5F | 0x60 | 0x61 | 0x62 | 0x63 | 0x64 | 0x65 | 0x66 | 0x67 | 0x68 | 0x69 | 0x6A | 0x6B | 0x6C | 0x6D | 0x6E | 0x6F | 0x70 | 0x71 | 0x72 | 0x73 | 0x74 | 0x75 | 0x76 | 0x77 | 0x78 | 0x79 | 0x7A | 0x7B | 0x7C | 0x7D | 0x7E | 0x7F:
                bit = (op & 0b00111000) >> 3
                self.FLAG_Z = (val & (1 << bit)) == 0
                self.FLAG_N = False
                self.FLAG_H = True

            # RES
            case 0x80 | 0x81 | 0x82 | 0x83 | 0x84 | 0x85 | 0x86 | 0x87 | 0x88 | 0x89 | 0x8A | 0x8B | 0x8C | 0x8D | 0x8E | 0x8F | 0x90 | 0x91 | 0x92 | 0x93 | 0x94 | 0x95 | 0x96 | 0x97 | 0x98 | 0x99 | 0x9A | 0x9B | 0x9C | 0x9D | 0x9E | 0x9F | 0xA0 | 0xA1 | 0xA2 | 0xA3 | 0xA4 | 0xA5 | 0xA6 | 0xA7 | 0xA8 | 0xA9 | 0xAA | 0xAB | 0xAC | 0xAD | 0xAE | 0xAF | 0xB0 | 0xB1 | 0xB2 | 0xB3 | 0xB4 | 0xB5 | 0xB6 | 0xB7 | 0xB8 | 0xB9 | 0xBA | 0xBB | 0xBC | 0xBD | 0xBE | 0xBF:
                bit = (op & 0b00111000) >> 3
                val &= (1 << bit) ^ 0xFF

            # SET
            case 0xC0 | 0xC1 | 0xC2 | 0xC3 | 0xC4 | 0xC5 | 0xC6 | 0xC7 | 0xC8 | 0xC9 | 0xCA | 0xCB | 0xCC | 0xCD | 0xCE | 0xCF | 0xD0 | 0xD1 | 0xD2 | 0xD3 | 0xD4 | 0xD5 | 0xD6 | 0xD7 | 0xD8 | 0xD9 | 0xDA | 0xDB | 0xDC | 0xDD | 0xDE | 0xDF | 0xE0 | 0xE1 | 0xE2 | 0xE3 | 0xE4 | 0xE5 | 0xE6 | 0xE7 | 0xE8 | 0xE9 | 0xEA | 0xEB | 0xEC | 0xED | 0xEE | 0xEF | 0xF0 | 0xF1 | 0xF2 | 0xF3 | 0xF4 | 0xF5 | 0xF6 | 0xF7 | 0xF8 | 0xF9 | 0xFA | 0xFB | 0xFC | 0xFD | 0xFE | 0xFF:
                bit = (op & 0b00111000) >> 3
                val |= 1 << bit

        self.set_reg(op, val & 0xFF)

    def _xor(self, val: u8) -> None:
        self.A ^= val

        self.FLAG_Z = self.A == 0
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_C = False

    def _or(self, val: u8) -> None:
        self.A |= val

        self.FLAG_Z = self.A == 0
        self.FLAG_N = False
        self.FLAG_H = False
        self.FLAG_C = False

    def _and(self, val: u8) -> None:
        self.A &= val

        self.FLAG_Z = self.A == 0
        self.FLAG_N = False
        self.FLAG_H = True
        self.FLAG_C = False

    def _cp(self, val: u8) -> None:
        self.FLAG_Z = self.A == val
        self.FLAG_N = True
        self.FLAG_H = (self.A & 0x0F) < (val & 0x0F)
        self.FLAG_C = self.A < val

    def _add(self, val: u8) -> None:
        self.FLAG_C = self.A + val > 0xFF
        self.FLAG_H = (self.A & 0x0F) + (val & 0x0F) > 0x0F
        self.FLAG_N = False
        self.A = (self.A + val) & 0xFF
        self.FLAG_Z = self.A == 0

    def _adc(self, val: u8) -> None:
        carry: u8 = u8(self.FLAG_C)
        self.FLAG_C = self.A + val + carry > 0xFF
        self.FLAG_H = (self.A & 0x0F) + (val & 0x0F) + carry > 0x0F
        self.FLAG_N = False
        self.A = (self.A + val + carry) & 0xFF
        self.FLAG_Z = self.A == 0

    def _sub(self, val: u8) -> None:
        self.FLAG_C = self.A < val
        self.FLAG_H = (self.A & 0x0F) < (val & 0x0F)
        self.A = (self.A - val) & 0xFF
        self.FLAG_Z = self.A == 0
        self.FLAG_N = True

    def _sbc(self, val: u8) -> None:
        carry: u8 = u8(self.FLAG_C)
        res = self.A - val - carry
        self.FLAG_H = ((self.A ^ val ^ (res & 0xFF)) & (1 << 4)) != 0
        self.FLAG_C = res < 0
        self.A = (self.A - val - carry) & 0xFF
        self.FLAG_Z = self.A == 0
        self.FLAG_N = True

    def push(self, val: u16) -> None:
        self.ram[self.SP - 1] = (val >> 8) & 0xFF
        self.ram[self.SP - 2] = val & 0xFF
        self.SP -= 2

    def pop(self) -> u16:
        val = (self.ram[self.SP + 1] << 8) | self.ram[self.SP]
        self.SP += 2
        return val

    def get_reg(self, n: u8) -> u8:
        match n & 0x07:
            case 0:
                return self.B
            case 1:
                return self.C
            case 2:
                return self.D
            case 3:
                return self.E
            case 4:
                return self.H
            case 5:
                return self.L
            case 6:
                return self.ram[self.HL]
            case 7:
                return self.A
        raise Exception("This should never happen")

    def set_reg(self, n: u8, val: u8) -> None:
        match n & 0x07:
            case 0:
                self.B = val
            case 1:
                self.C = val
            case 2:
                self.D = val
            case 3:
                self.E = val
            case 4:
                self.H = val
            case 5:
                self.L = val
            case 6:
                self.ram[self.HL] = val
            case 7:
                self.A = val
