<?php

$OP_CYCLES = [
    1, 3, 2, 2, 1, 1, 2, 1, 5, 2, 2, 2, 1, 1, 2, 1,
    0, 3, 2, 2, 1, 1, 2, 1, 3, 2, 2, 2, 1, 1, 2, 1,
    2, 3, 2, 2, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 2, 1,
    2, 3, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    2, 2, 2, 2, 2, 2, 0, 2, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    2, 3, 3, 4, 3, 4, 2, 4, 2, 4, 3, 0, 3, 6, 2, 4,
    2, 3, 3, 0, 3, 4, 2, 4, 2, 4, 3, 0, 3, 0, 2, 4,
    3, 3, 2, 0, 0, 4, 2, 4, 4, 1, 4, 0, 0, 0, 2, 4,
    3, 3, 2, 1, 0, 4, 2, 4, 3, 2, 4, 1, 0, 0, 2, 4,
];

$OP_CB_CYCLES = [
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2,
];

$OP_ARG_TYPES = [
    //1 2 3 4 5 6 7 8 9 A B C D E F
    0, 2, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 1, 0, // 0
    1, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, // 1
    3, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, // 2
    3, 2, 0, 0, 0, 0, 1, 0, 3, 0, 0, 0, 0, 0, 1, 0, // 3
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 4
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 5
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 6
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 7
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // A
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // B
    0, 0, 2, 2, 2, 0, 1, 0, 0, 0, 2, 0, 2, 2, 1, 0, // C
    0, 0, 2, 0, 2, 0, 1, 0, 0, 0, 2, 0, 2, 0, 1, 0, // D
    1, 0, 0, 0, 0, 0, 1, 0, 3, 0, 2, 0, 0, 0, 1, 0, // E
    1, 0, 0, 0, 0, 0, 1, 0, 3, 0, 2, 0, 0, 0, 1, 0, // F
];

$OP_ARG_BYTES = [0, 1, 2, 1];

$OP_NAMES = [
    "NOP", "LD BC,$%04X", "LD [BC],A", "INC BC", "INC B", "DEC B", "LD B,$%02X", "RCLA", "LD [$%04X],SP",
    "ADD HL,BC", "LD A,[BC]", "DEC BC", "INC C", "DEC C", "LD C,$%02X", "RRCA", "STOP", "LD DE,$%04X",
    "LD [DE],A", "INC DE", "INC D", "DEC D", "LD D,$%02X", "RLA", "JR %+d", "ADD HL,DE", "LD A,[DE]",
    "DEC DE", "INC E", "DEC E", "LD E,$%02X", "RRA", "JR NZ,%+d", "LD HL,$%04X", "LD [HL+],A", "INC HL",
    "INC H", "DEC H", "LD H,$%02X", "DAA", "JR Z,%+d", "ADD HL,HL", "LD A,[HL+]", "DEC HL", "INC L",
    "DEC L", "LD L,$%02X", "CPL", "JR NC,%+d", "LD SP,$%04X", "LD [HL-],A", "INC SP", "INC [HL]",
    "DEC [HL]", "LD [HL],$%02X", "SCF", "JR C,%+d", "ADD HL,SP", "LD A,[HL-]", "DEC SP", "INC A",
    "DEC A", "LD A,$%02X", "CCF",
    "LD B,B", "LD B,C", "LD B,D", "LD B,E", "LD B,H", "LD B,L", "LD B,[HL]", "LD B,A",
    "LD C,B", "LD C,C", "LD C,D", "LD C,E", "LD C,H", "LD C,L", "LD C,[HL]", "LD C,A",
    "LD D,B", "LD D,C", "LD D,D", "LD D,E", "LD D,H", "LD D,L", "LD D,[HL]", "LD D,A",
    "LD E,B", "LD E,C", "LD E,D", "LD E,E", "LD E,H", "LD E,L", "LD E,[HL]", "LD E,A",
    "LD H,B", "LD H,C", "LD H,D", "LD H,E", "LD H,H", "LD H,L", "LD H,[HL]", "LD H,A",
    "LD L,B", "LD L,C", "LD L,D", "LD L,E", "LD L,H", "LD L,L", "LD L,[HL]", "LD L,A",
    "LD [HL],B", "LD [HL],C", "LD [HL],D", "LD [HL],E", "LD [HL],H", "LD [HL],L", "HALT", "LD [HL],A",
    "LD A,B", "LD A,C", "LD A,D", "LD A,E", "LD A,H", "LD A,L", "LD A,[HL]", "LD A,A",
    "ADD A,B", "ADD A,C", "ADD A,D", "ADD A,E", "ADD A,H", "ADD A,L", "ADD A,[HL]", "ADD A,A",
    "ADC A,B", "ADC A,C", "ADC A,D", "ADC A,E", "ADC A,H", "ADC A,L", "ADC A,[HL]", "ADC A,A",
    "SUB A,B", "SUB A,C", "SUB A,D", "SUB A,E", "SUB A,H", "SUB A,L", "SUB A,[HL]", "SUB A,A",
    "SBC A,B", "SBC A,C", "SBC A,D", "SBC A,E", "SBC A,H", "SBC A,L", "SBC A,[HL]", "SBC A,A",
    "AND B", "AND C", "AND D", "AND E", "AND H", "AND L", "AND [HL]", "AND A",
    "XOR B", "XOR C", "XOR D", "XOR E", "XOR H", "XOR L", "XOR [HL]", "XOR A",
    "OR B", "OR C", "OR D", "OR E", "OR H", "OR L", "OR [HL]", "OR A",
    "CP B", "CP C", "CP D", "CP E", "CP H", "CP L", "CP [HL]", "CP A",
    "RET NZ", "POP BC", "JP NZ,$%04X", "JP $%04X", "CALL NZ,$%04X", "PUSH BC", "ADD A,$%02X", "RST 00",
    "RET Z", "RET", "JP Z,$%04X", "ERR CB", "CALL Z,$%04X", "CALL $%04X", "ADC A,$%02X", "RST 08",
    "RET NC", "POP DE", "JP NC,$%04X", "ERR D3", "CALL NC,$%04X", "PUSH DE", "SUB A,$%02X", "RST 10",
    "RET C", "RETI", "JP C,$%04X", "ERR DB", "CALL C,$%04X", "ERR DD", "SBC A,$%02X", "RST 18",
    "LDH [$%02X],A", "POP HL", "LDH [C],A", "DBG", "ERR E4", "PUSH HL", "AND $%02X", "RST 20",
    "ADD SP %+d", "JP HL", "LD [$%04X],A", "ERR EB", "ERR EC", "ERR ED", "XOR $%02X", "RST 28",
    "LDH A,[$%02X]", "POP AF", "LDH A,[C]", "DI", "ERR F4", "PUSH AF", "OR $%02X", "RST 30",
    "LD HL,SP%+d", "LD SP,HL", "LD A,[$%04X]", "EI", "ERR FC", "ERR FD", "CP $%02X", "RST 38",
];

$CB_OP_NAMES = [
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
];

class oparg
{
    // FIXME should be a union
    public int $as_u8 = 0;  // B
    public int $as_i8 = 0;  // b
    public int $as_u16 = 0; // H
}

function int8(int $val): int
{
    $val = $val & 0xFF;
    if ($val > 127) {
        $val -= 0x100;
    }
    return $val;
}

function uint8(int $val): int
{
    return $val & 0xFF;
}

function uint16(int $val): int
{
    return $val & 0xFFFF;
}

function split16(int $val): array
{
    return [uint8($val >> 8), uint8($val & 0xFF)];
}

function join16(int $a, int $b): int
{
    return (uint16($a) << 8) | uint16($b);
}


class CPU
{
    private bool $FLAG_C;
    private bool $FLAG_H;
    private bool $FLAG_N;
    private bool $FLAG_Z;
    private int $PC;
    private int $SP;
    private int $HL;
    private int $F;
    private int $E;
    private int $D;
    private int $C;
    private int $B;
    private int $A;
    private int $cycle;
    private bool $interrupts;
    private int $owed_cycles;
    private bool $halt;
    public bool $stop;
    private bool $debug;
    public RAM $ram;

    public function __construct(RAM $ram, bool $debug)
    {
        $this->ram = $ram;
        $this->debug = $debug;

        $this->stop = false;
        $this->halt = false;
        $this->owed_cycles = 0;
        $this->interrupts = false;
        $this->cycle = 0;

        // FIXME: these should be unioned
        // A, B, C, D, E, H, L, F         uint8
        // AF, BC, DE, HL, SP, PC         uint16
        $this->A = 0;
        $this->B = 0;
        $this->C = 0;
        $this->D = 0;
        $this->E = 0;
        $this->F = 0;
        $this->HL = 0;
        $this->SP = 0;
        $this->PC = 0;
        $this->FLAG_Z = false;
        $this->FLAG_N = false;
        $this->FLAG_H = false;
        $this->FLAG_C = false;
    }

    public function tick(): bool
    {
        $this->tick_dma();
        if (!$this->tick_clock()) {
            return false;
        }
        if (!$this->tick_interrupts()) {
            return false;
        }
        if ($this->halt) {
            return true;
        }
        if ($this->stop) {
            return false;
        }
        if (!$this->tick_instructions()) {
            return false;
        }
        return true;
    }

    public function interrupt(int $i)
    {
        // Set a given interrupt bit - on the next tick, if the interrupt
        // handler for self interrupt is enabled (and interrupts in general
        // are enabled), then the interrupt handler will be called.
        $this->ram->data[Mem::$IF] |= $i;
        $this->halt = false; // interrupts interrupt HALT state
    }

    public function dump_regs()
    {
        global $CB_OP_NAMES, $OP_ARG_TYPES, $OP_NAMES;
        $IE = $this->ram->get(Mem::$IE);
        $IF = $this->ram->get(Mem::$IF);
        $z = (($this->F >> 7) & 1) ? 'Z' : 'z';
        $n = (($this->F >> 6) & 1) ? 'N' : 'n';
        $h = (($this->F >> 5) & 1) ? 'H' : 'h';
        $c = (($this->F >> 4) & 1) ? 'C' : 'c';
        $v = ($IE >> 0) & 1 ? ((($IF >> 0) & 1) ? 'V' : 'v') : '_';
        $l = ($IE >> 1) & 1 ? ((($IF >> 1) & 1) ? 'L' : 'l') : '_';
        $t = ($IE >> 2) & 1 ? ((($IF >> 2) & 1) ? 'T' : 't') : '_';
        $s = ($IE >> 3) & 1 ? ((($IF >> 3) & 1) ? 'S' : 's') : '_';
        $j = ($IE >> 4) & 1 ? ((($IF >> 4) & 1) ? 'J' : 'j') : '_';
        $op = $this->ram->get($this->PC);
        $op_str = "";
        if ($op == 0xCB) {
            $op = $this->ram->get($this->PC + 1);
            $op_str = $CB_OP_NAMES[$op];
        } else {
            switch ($OP_ARG_TYPES[$op]) {
                case 0:
                    $op_str = $OP_NAMES[$op];
                    break;
                case 1:
                    $op_str = sprintf($OP_NAMES[$op], $this->ram->get($this->PC + 1));
                    break;
                case 2:
                    $op_str = sprintf($OP_NAMES[$op], uint16($this->ram->get($this->PC + 2)) << 8 | uint16($this->ram->get($this->PC + 1)));
                    break;
                case 3:
                    $op_str = sprintf($OP_NAMES[$op], int8($this->ram->get($this->PC + 1)));
                    break;
            }
        }
        // if(cycle % 10 == 0)
        // printf("A F  B C  D E  H L  : SP   = [SP] : F    : IE/IF : PC   = OP : INSTR\n");
        printf(
            "%02X%02X %02X%02X %02X%02X %04X : %04X = %02X%02X : %s%s%s%s : %s%s%s%s%s : %04X = %02X : %s\n",
            $this->A,
            $this->F,
            $this->B,
            $this->C,
            $this->D,
            $this->E,
            $this->HL,
            $this->SP,
            $this->ram->get(($this->SP + 1) & 0xFFFF),
            $this->ram->get($this->SP),
            $z,
            $n,
            $h,
            $c,
            $v,
            $l,
            $t,
            $s,
            $j,
            $this->PC,
            $op,
            $op_str,
        );
    }

    public function tick_dma()
    {
        // TODO: DMA should take 26 cycles, during which main RAM is inaccessible
        if ($this->ram->get(Mem::$DMA) > 0) {
            $dma_src = uint16($this->ram->get(Mem::$DMA)) << 8;
            for ($i = 0; $i < 0x60; $i++) {
                $this->ram->set(uint16(Mem::$OAM_BASE + $i), $this->ram->get($dma_src + uint16($i)));
            }
            $this->ram->set(Mem::$DMA, 0x00);
        }
    }

    public function tick_clock(): bool
    {
        $this->cycle++;

        // TODO: writing any $value to Mem::$DIV should reset it to 0x00
        // increment at 16384Hz (each 64 cycles?)
        if ($this->cycle % 64 == 0) {
            $this->ram->_inc(Mem::$DIV);
        }

        if ($this->ram->get(Mem::$TAC) & (1 << 2) > 0) { // timer enable
            $speeds = [256, 4, 16, 64]; // increment per X cycles
            $speed = $speeds[$this->ram->get(Mem::$TAC) & 0x03];
            if ($this->cycle % $speed == 0) {
                if ($this->ram->get(Mem::$TIMA) == 0xFF) {
                    $this->ram->set(Mem::$TIMA, $this->ram->get(Mem::$TMA)); // if timer overflows, load base
                    $this->interrupt(Interrupt::$TIMER);
                }
                $this->ram->_inc(Mem::$TIMA);
            }
        }
        return true;
    }

    public function tick_interrupts(): bool
    {
        $queued_interrupts = $this->ram->get(Mem::$IE) & $this->ram->get(Mem::$IF);
        if ($this->interrupts && ($queued_interrupts != 0x00)) {
            if ($this->debug) {
                printf("Handling interrupts: %02X & %02X\n", $this->ram->get(Mem::$IE), $this->ram->get(Mem::$IF));
            }
            $this->interrupts = false; // no nested interrupts, RETI will re-enable
            // TODO: wait two cycles
            // TODO: push16(PC) should also take two cycles
            // TODO: one more cycle to store new PC
            if (($queued_interrupts & Interrupt::$VBLANK) > 0) {
                $this->push($this->PC);
                $this->PC = Mem::$VBLANK_HANDLER;
                $this->ram->_and(Mem::$IF, ~Interrupt::$VBLANK);
            } elseif (($queued_interrupts & Interrupt::$STAT) > 0) {
                $this->push($this->PC);
                $this->PC = Mem::$LCD_HANDLER;
                $this->ram->_and(Mem::$IF, ~Interrupt::$STAT);
            } elseif (($queued_interrupts & Interrupt::$TIMER) > 0) {
                $this->push($this->PC);
                $this->PC = Mem::$TIMER_HANDLER;
                $this->ram->_and(Mem::$IF, ~Interrupt::$TIMER);
            } elseif (($queued_interrupts & Interrupt::$SERIAL) > 0) {
                $this->push($this->PC);
                $this->PC = Mem::$SERIAL_HANDLER;
                $this->ram->_and(Mem::$IF, ~Interrupt::$SERIAL);
            } elseif (($queued_interrupts & Interrupt::$JOYPAD) > 0) {
                $this->push($this->PC);
                $this->PC = Mem::$JOYPAD_HANDLER;
                $this->ram->_and(Mem::$IF, ~Interrupt::$JOYPAD);
            }
        }
        return true;
    }

    public function tick_instructions(): bool
    {
        global $OP_CYCLES, $OP_CB_CYCLES;
        // if the previous instruction was large, let's not run any
        // more instructions until other subsystems have caught up
        if ($this->owed_cycles > 0) {
            $this->owed_cycles--;
            return true;
        }

        if ($this->debug) {
            $this->dump_regs();
        }

        $op = $this->ram->get($this->PC);
        $this->PC++;
        if ($op == 0xCB) {
            $op = $this->ram->get($this->PC);
            $this->PC++;
            $this->tick_cb($op);
            $this->owed_cycles = $OP_CB_CYCLES[$op] - 1;
        } else {
            $this->tick_main($op);
            $this->owed_cycles = $OP_CYCLES[$op] - 1;
        }

        // Flags should be union'ed with the F register, but php doesn't
        // support that, so let's manually sync from flags to register
        // after every instruction...
        $this->F = 0;
        if ($this->FLAG_Z) {
            $this->F |= 1 << 7;
        }
        if ($this->FLAG_N) {
            $this->F |= 1 << 6;
        }
        if ($this->FLAG_H) {
            $this->F |= 1 << 5;
        }
        if ($this->FLAG_C) {
            $this->F |= 1 << 4;
        }

        // HALT has cycles=0
        if ($this->owed_cycles < 0) {
            $this->owed_cycles = 0;
        }
        return true;
    }

    public function tick_main(int $op)
    {
        global $OP_ARG_BYTES, $OP_ARG_TYPES;
        // Load arg
        $arg = new oparg();
        $nargs = $OP_ARG_BYTES[$OP_ARG_TYPES[$op]];
        if ($nargs == 1) {
            $arg->as_u8 = $this->ram->get($this->PC);
            $arg->as_i8 = int8($arg->as_u8);
            $this->PC++;
        }
        if ($nargs == 2) {
            $low = $this->ram->get($this->PC);
            $this->PC++;
            $high = $this->ram->get($this->PC);
            $this->PC++;
            $arg->as_u16 = uint16($high) << 8 | uint16($low);
        }

        // Execute
        switch ($op) {
            case 0x00: /* NOP */
                break;
            case 0x01:
                [$this->B, $this->C] = split16($arg->as_u16);
                break;
            case 0x02:
                $this->ram->set(join16($this->B, $this->C), $this->A);
                break;
            case 0x03:
                [$this->B, $this->C] = split16(join16($this->B, $this->C) + 1);
                break;
            case 0x08:
                $this->ram->set($arg->as_u16 + 1, uint8(($this->SP >> 8) & 0xFF));
                $this->ram->set($arg->as_u16, uint8($this->SP & 0xFF));
                break;
            case 0x0A:
                $this->A = $this->ram->get(join16($this->B, $this->C));
                break;
            case 0x0B:
                [$this->B, $this->C] = split16(join16($this->B, $this->C) - 1);
                break;
            case 0x10:
                $this->stop = true;
                break;
            case 0x11:
                [$this->D, $this->E] = split16($arg->as_u16);
                break;
            case 0x12:
                $this->ram->set(join16($this->D, $this->E), $this->A);
                break;
            case 0x13:
                [$this->D, $this->E] = split16(join16($this->D, $this->E) + 1);
                break;
            case 0x18:
                $this->PC += $arg->as_i8;
                break;
            case 0x1A:
                $this->A = $this->ram->get(join16($this->D, $this->E));
                break;
            case 0x1B:
                [$this->D, $this->E] = split16(join16($this->D, $this->E) - 1);
                break;

            case 0x20:
                if (!$this->FLAG_Z) {
                    $this->PC += $arg->as_i8;
                }
                break;
            case 0x21:
                $this->HL = $arg->as_u16;
                break;
            case 0x22:
                $this->ram->set($this->HL, $this->A);
                $this->HL = ($this->HL+1) & 0xFFFF;
                break;
            case 0x23:
                $this->HL = ($this->HL+1) & 0xFFFF;
                break;
            case 0x27:
                $val16 = uint16($this->A);
                if (!$this->FLAG_N) {
                    if ($this->FLAG_H || ($val16 & 0x0F) > 9) {
                        $val16 += 6;
                    }
                    if ($this->FLAG_C || $val16 > 0x9F) {
                        $val16 += 0x60;
                    }
                } else {
                    if ($this->FLAG_H) {
                        $val16 -= 6;
                        if (!$this->FLAG_C) {
                            $val16 &= 0xFF;
                        }
                    }
                    if ($this->FLAG_C) {
                        $val16 -= 0x60;
                    }
                }
                $this->FLAG_H = false;
                if (($val16 & 0x100) > 0) {
                    $this->FLAG_C = true;
                }
                $this->A = uint8($val16 & 0xFF);
                $this->FLAG_Z = $this->A == 0;
                break;
            case 0x28:
                if ($this->FLAG_Z) {
                    $this->PC += $arg->as_i8;
                }
                break;
            case 0x2A:
                $this->A = $this->ram->get($this->HL);
                $this->HL = ($this->HL+1) & 0xFFFF;
                break;
            case 0x2B:
                $this->HL = ($this->HL-1) & 0xFFFF;
                break;
            case 0x2F:
                $this->A ^= 0xFF;
                $this->FLAG_N = true;
                $this->FLAG_H = true;
                break;
            case 0x30:
                if (!$this->FLAG_C) {
                    $this->PC += $arg->as_i8;
                }
                break;
            case 0x31:
                $this->SP = $arg->as_u16;
                break;
            case 0x32:
                $this->ram->set($this->HL, $this->A);
                $this->HL = ($this->HL-1) & 0xFFFF;
                break;
            case 0x33:
                $this->SP = ($this->SP+1) & 0xFFFF;
                break;
            case 0x37:
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                $this->FLAG_C = true;
                break;
            case 0x38:
                if ($this->FLAG_C) {
                    $this->PC += $arg->as_i8;
                }
                break;
            case 0x3A:
                $this->A = $this->ram->get($this->HL);
                $this->HL = ($this->HL-1) & 0xFFFF;
                break;
            case 0x3B:
                $this->SP = ($this->SP-1) & 0xFFFF;
                break;
            case 0x3F:
                $this->FLAG_C = !$this->FLAG_C;
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                break;

            // INC r
            case 0x04:
            case 0x0C:
            case 0x14:
            case 0x1C:
            case 0x24:
            case 0x2C:
            case 0x34:
            case 0x3C:
                $val = $this->get_reg(($op - 0x04) / 8);
                $this->FLAG_H = ($val & 0x0F) == 0x0F;
                $val = ($val+1) & 0xFF;
                $this->FLAG_Z = $val == 0;
                $this->FLAG_N = false;
                $this->set_reg(($op - 0x04) / 8, $val);
                break;

            // DEC r
            case 0x05:
            case 0x0D:
            case 0x15:
            case 0x1D:
            case 0x25:
            case 0x2D:
            case 0x35:
            case 0x3D:
                $val = $this->get_reg(($op - 0x05) / 8);
                $val = ($val-1) & 0xFF;
                $this->FLAG_H = ($val & 0x0F) == 0x0F;
                $this->FLAG_Z = $val == 0;
                $this->FLAG_N = true;
                $this->set_reg(($op - 0x05) / 8, $val);
                break;

            // LD r,n
            case 0x06:
            case 0x0E:
            case 0x16:
            case 0x1E:
            case 0x26:
            case 0x2E:
            case 0x36:
            case 0x3E:
                $this->set_reg(($op - 0x06) / 8, $arg->as_u8);
                break;

            // RCLA, RLA, RRCA, RRA
            case 0x07:
            case 0x17:
            case 0x0F:
            case 0x1F:
                if ($this->FLAG_C) {
                    $carry = 1;
                } else {
                    $carry = 0;
                }
                if ($op == 0x07) { // RCLA
                    $this->FLAG_C = ($this->A & (1 << 7)) != 0;
                    $this->A = ($this->A << 1) | ($this->A >> 7);
                }
                if ($op == 0x17) { // RLA
                    $this->FLAG_C = ($this->A & (1 << 7)) != 0;
                    $this->A = ($this->A << 1) | $carry;
                }
                if ($op == 0x0F) { // RRCA
                    $this->FLAG_C = ($this->A & (1 << 0)) != 0;
                    $this->A = ($this->A >> 1) | ($this->A << 7);
                }
                if ($op == 0x1F) { // RRA
                    $this->FLAG_C = ($this->A & (1 << 0)) != 0;
                    $this->A = ($this->A >> 1) | ($carry << 7);
                }
                $this->A &= 0xFF;
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                $this->FLAG_Z = false;
                break;

            // ADD HL,rr
            case 0x09:
            case 0x19:
            case 0x29:
            case 0x39:
                if ($op == 0x09) {
                    $val16 = join16($this->B, $this->C);
                }
                if ($op == 0x19) {
                    $val16 = join16($this->D, $this->E);
                }
                if ($op == 0x29) {
                    $val16 = $this->HL;
                }
                if ($op == 0x39) {
                    $val16 = $this->SP;
                }
                $this->FLAG_H = (($this->HL & 0x0FFF) + ($val16 & 0x0FFF) > 0x0FFF);
                $this->FLAG_C = (($this->HL + $val16) > 0xFFFF);
                $this->HL = ($this->HL + $val16) & 0xFFFF;
                $this->FLAG_N = false;
                break;

            // LD r,r
            case 0x40:
            case 0x41:
            case 0x42:
            case 0x43:
            case 0x44:
            case 0x45:
            case 0x46:
            case 0x47:
            case
            0x48:
            case 0x49:
            case 0x4A:
            case 0x4B:
            case 0x4C:
            case 0x4D:
            case 0x4E:
            case 0x4F:
            case
            0x50:
            case 0x51:
            case 0x52:
            case 0x53:
            case 0x54:
            case 0x55:
            case 0x56:
            case 0x57:
            case
            0x58:
            case 0x59:
            case 0x5A:
            case 0x5B:
            case 0x5C:
            case 0x5D:
            case 0x5E:
            case 0x5F:
            case
            0x60:
            case 0x61:
            case 0x62:
            case 0x63:
            case 0x64:
            case 0x65:
            case 0x66:
            case 0x67:
            case
            0x68:
            case 0x69:
            case 0x6A:
            case 0x6B:
            case 0x6C:
            case 0x6D:
            case 0x6E:
            case 0x6F:
            case
            0x70:
            case 0x71:
            case 0x72:
            case 0x73:
            case 0x74:
            case 0x75:
            case 0x76:
            case 0x77:
            case
            0x78:
            case 0x79:
            case 0x7A:
            case 0x7B:
            case 0x7C:
            case 0x7D:
            case 0x7E:
            case 0x7F:
                if ($op == 0x76) {
                    // FIXME: weird timing side effects
                    $this->halt = true;
                    break;
                }
                $this->set_reg(($op - 0x40) >> 3, $this->get_reg($op - 0x40));
                break;
            case 0x80:
            case 0x81:
            case 0x82:
            case 0x83:
            case 0x84:
            case 0x85:
            case 0x86:
            case 0x87:
                $this->_add($this->get_reg($op));
                break;
            case 0x88:
            case 0x89:
            case 0x8A:
            case 0x8B:
            case 0x8C:
            case 0x8D:
            case 0x8E:
            case 0x8F:
                $this->_adc($this->get_reg($op));
                break;
            case 0x90:
            case 0x91:
            case 0x92:
            case 0x93:
            case 0x94:
            case 0x95:
            case 0x96:
            case 0x97:
                $this->_sub($this->get_reg($op));
                break;
            case 0x98:
            case 0x99:
            case 0x9A:
            case 0x9B:
            case 0x9C:
            case 0x9D:
            case 0x9E:
            case 0x9F:
                $this->_sbc($this->get_reg($op));
                break;
            case 0xA0:
            case 0xA1:
            case 0xA2:
            case 0xA3:
            case 0xA4:
            case 0xA5:
            case 0xA6:
            case 0xA7:
                $this->_and($this->get_reg($op));
                break;
            case 0xA8:
            case 0xA9:
            case 0xAA:
            case 0xAB:
            case 0xAC:
            case 0xAD:
            case 0xAE:
            case 0xAF:
                $this->_xor($this->get_reg($op));
                break;
            case 0xB0:
            case 0xB1:
            case 0xB2:
            case 0xB3:
            case 0xB4:
            case 0xB5:
            case 0xB6:
            case 0xB7:
                $this->_or($this->get_reg($op));
                break;
            case 0xB8:
            case 0xB9:
            case 0xBA:
            case 0xBB:
            case 0xBC:
            case 0xBD:
            case 0xBE:
            case 0xBF:
                $this->_cp($this->get_reg($op));
                break;

            case 0xC0:
                if (!$this->FLAG_Z) {
                    $this->PC = $this->pop();
                }
                break;
            case 0xC1:
                [$this->B, $this->C] = split16($this->pop());
                break;
            case 0xC2:
                if (!$this->FLAG_Z) {
                    $this->PC = $arg->as_u16;
                }
                break;
            case 0xC3:
                $this->PC = $arg->as_u16;
                break;
            case 0xC4:
                if (!$this->FLAG_Z) {
                    $this->push($this->PC);
                    $this->PC = $arg->as_u16;
                }
                break;
            case 0xC5:
                $this->push(join16($this->B, $this->C));
                break;
            case 0xC6:
                $this->_add($arg->as_u8);
                break;
            case 0xC7:
                $this->push($this->PC);
                $this->PC = 0x00;
                break;
            case 0xC8:
                if ($this->FLAG_Z) {
                    $this->PC = $this->pop();
                }
                break;
            case 0xC9:
                $this->PC = $this->pop();
                break;
            case 0xCA:
                if ($this->FLAG_Z) {
                    $this->PC = $arg->as_u16;
                }
                break;
            // case 0xCB: break;
            case 0xCC:
                if ($this->FLAG_Z) {
                    $this->push($this->PC);
                    $this->PC = $arg->as_u16;
                }
                break;
            case 0xCD:
                $this->push($this->PC);
                $this->PC = $arg->as_u16;
                break;
            case 0xCE:
                $this->_adc($arg->as_u8);
                break;
            case 0xCF:
                $this->push($this->PC);
                $this->PC = 0x08;
                break;

            case 0xD0:
                if (!$this->FLAG_C) {
                    $this->PC = $this->pop();
                }
                break;
            case 0xD1:
                [$this->D, $this->E] = split16($this->pop());
                break;
            case 0xD2:
                if (!$this->FLAG_C) {
                    $this->PC = $arg->as_u16;
                }
                break;
            // case 0xD3: break;
            case 0xD4:
                if (!$this->FLAG_C) {
                    $this->push($this->PC);
                    $this->PC = $arg->as_u16;
                }
                break;
            case 0xD5:
                $this->push(join16($this->D, $this->E));
                break;
            case 0xD6:
                $this->_sub($arg->as_u8);
                break;
            case 0xD7:
                $this->push($this->PC);
                $this->PC = 0x10;
                break;
            case 0xD8:
                if ($this->FLAG_C) {
                    $this->PC = $this->pop();
                }
                break;
            case 0xD9:
                $this->PC = $this->pop();
                $this->interrupts = true;
                break;
            case 0xDA:
                if ($this->FLAG_C) {
                    $this->PC = $arg->as_u16;
                }
                break;
            // case 0xDB: break;
            case 0xDC:
                if ($this->FLAG_C) {
                    $this->push($this->PC);
                    $this->PC = $arg->as_u16;
                }
                break;
            // case 0xDD: break;
            case 0xDE:
                $this->_sbc($arg->as_u8);
                break;
            case 0xDF:
                $this->push($this->PC);
                $this->PC = 0x18;
                break;
            case 0xE0:
                $this->ram->set(0xFF00 + uint16($arg->as_u8), $this->A);
                if ($arg->as_u8 == 0x01) {
                    print(chr($this->A));
                }
                break;
            case 0xE1:
                $this->HL = $this->pop();
                break;
            case 0xE2:
                $this->ram->set(0xFF00 + uint16($this->C), $this->A);
                if ($this->C == 0x01) {
                    print(chr($this->A));
                }
                break;
            // case 0xE3: break;
            // case 0xE4: break;
            case 0xE5:
                $this->push($this->HL);
                break;
            case 0xE6:
                $this->_and($arg->as_u8);
                break;
            case 0xE7:
                $this->push($this->PC);
                $this->PC = 0x20;
                break;
            case 0xE8:
                $val16 = ($this->SP + $arg->as_i8) & 0xFFFF;
                //$this->FLAG_H = (($this->SP & 0x0FFF) + ($arg->as_i8 & 0x0FFF) > 0x0FFF);
                //$this->FLAG_C = ($this->SP + $arg->as_i8 > 0xFFFF);
                $this->FLAG_H = (($this->SP ^ uint16($arg->as_i8) ^ $val16) & 0x10) > 0;
                $this->FLAG_C = (($this->SP ^ uint16($arg->as_i8) ^ $val16) & 0x100) > 0;
                $this->SP = ($this->SP + $arg->as_i8) & 0xFFFF;
                $this->FLAG_Z = false;
                $this->FLAG_N = false;
                break;
            case 0xE9:
                $this->PC = $this->HL;
                break;
            case 0xEA:
                $this->ram->set($arg->as_u16, $this->A);
                break;
            // case 0xEB: break;
            // case 0xEC: break;
            // case 0xED: break;
            case 0xEE:
                $this->_xor($arg->as_u8);
                break;
            case 0xEF:
                $this->push($this->PC);
                $this->PC = 0x28;
                break;

            case 0xF0:
                $this->A = $this->ram->get(0xFF00 + uint16($arg->as_u8));
                break;
            case 0xF1:
                [$this->A, $this->F] = split16($this->pop() & 0xFFF0);
                $this->FLAG_Z = ($this->F & (1 << 7)) > 0;
                $this->FLAG_N = ($this->F & (1 << 6)) > 0;
                $this->FLAG_H = ($this->F & (1 << 5)) > 0;
                $this->FLAG_C = ($this->F & (1 << 4)) > 0;
                break;
            case 0xF2:
                $this->A = $this->ram->get(0xFF00 + uint16($this->C));
                break;
            case 0xF3:
                $this->interrupts = false;
                break;
            // case 0xF4: break;
            case 0xF5:
                $this->push(join16($this->A, $this->F));
                break;
            case 0xF6:
                $this->_or($arg->as_u8);
                break;
            case 0xF7:
                $this->push($this->PC);
                $this->PC = 0x30;
                break;
            case 0xF8:
                if ($arg->as_i8 >= 0) {
                    $this->FLAG_C = (($this->SP & 0xFF) + ($arg->as_i8 & 0xFF)) > 0xFF;
                    $this->FLAG_H = (($this->SP & 0x0F) + ($arg->as_i8 & 0x0F)) > 0x0F;
                } else {
                    $this->FLAG_C = uint8(($this->SP + $arg->as_i8) & 0xFF) <= uint8($this->SP & 0xFF);
                    $this->FLAG_H = uint8(($this->SP + $arg->as_i8) & 0x0F) <= uint8($this->SP & 0x0F);
                }
                // $this->FLAG_H = (((($this->SP & 0x0f) + ($arg->as_u8 & 0x0f)) & 0x10) != 0);
                // $this->FLAG_C = (((($this->SP & 0xff) + ($arg->as_u8 & 0xff)) & 0x100) != 0);
                $this->HL = ($this->SP + $arg->as_i8) & 0xFFFF;
                $this->FLAG_Z = false;
                $this->FLAG_N = false;
                break;
            case 0xF9:
                $this->SP = $this->HL;
                break;
            case 0xFA:
                $this->A = $this->ram->get($arg->as_u16);
                break;
            case 0xFB:
                $this->interrupts = true;
                break;
            // case 0xFC: break;
            // case 0xFD: break;
            case 0xFE:
                $this->_cp($arg->as_u8);
                break;
            case 0xFF:
                $this->push($this->PC);
                $this->PC = 0x38;
                break;

            // missing ops
            default:
                printf("Op %02X not implemented\n", $op);
                die("Op not implemented");
        }
    }

    public function tick_cb(int $op)
    {
        $val = $this->get_reg($op);
        switch (true) {
            // RLC
            case $op <= 0x07:
                $this->FLAG_C = ($val & (1 << 7)) != 0;
                $val <<= 1;
                $val &= 0xFF;
                if ($this->FLAG_C) {
                    $val |= (1 << 0);
                }
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                $this->FLAG_Z = $val == 0;
                break;

            // RRC
            case $op <= 0x0F:
                $this->FLAG_C = ($val & (1 << 0)) != 0;
                $val >>= 1;
                if ($this->FLAG_C) {
                    $val |= (1 << 7);
                }
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                $this->FLAG_Z = $val == 0;
                break;

            // RL
            case $op <= 0x17:
                $orig_c = $this->FLAG_C;
                $this->FLAG_C = ($val & (1 << 7)) != 0;
                $val <<= 1;
                $val &= 0xFF;
                if ($orig_c) {
                    $val |= (1 << 0);
                }
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                $this->FLAG_Z = $val == 0;
                break;

            // RR
            case $op <= 0x1F:
                $orig_c = $this->FLAG_C;
                $this->FLAG_C = ($val & (1 << 0)) != 0;
                $val >>= 1;
                if ($orig_c) {
                    $val |= (1 << 7);
                }
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                $this->FLAG_Z = $val == 0;
                break;

            // SLA
            case $op <= 0x27:
                $this->FLAG_C = ($val & (1 << 7)) != 0;
                $val <<= 1;
                $val &= 0xFF;
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                $this->FLAG_Z = $val == 0;
                break;

            // SRA
            case $op <= 0x2F:
                $this->FLAG_C = ($val & (1 << 0)) != 0;
                $val >>= 1;
                if (($val & (1 << 6)) > 0) {
                    $val |= (1 << 7);
                }
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                $this->FLAG_Z = $val == 0;
                break;

            // SWAP
            case $op <= 0x37:
                $val = (($val & 0xF0) >> 4) | (($val & 0x0F) << 4);
                $this->FLAG_C = false;
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                $this->FLAG_Z = $val == 0;
                break;

            // SRL
            case $op <= 0x3F:
                $this->FLAG_C = ($val & (1 << 0)) != 0;
                $val >>= 1;
                $this->FLAG_N = false;
                $this->FLAG_H = false;
                $this->FLAG_Z = $val == 0;
                break;

            // BIT
            case $op <= 0x7F:
                $bit = ($op & 0b00111000) >> 3;
                $this->FLAG_Z = ($val & (1 << $bit)) == 0;
                $this->FLAG_N = false;
                $this->FLAG_H = true;
                break;

            // RES
            case $op <= 0xBF:
                $bit = ($op & 0b00111000) >> 3;
                $val &= ((1 << $bit) ^ 0xFF);
                break;

            // SET
            case $op <= 0xFF:
                $bit = ($op & 0b00111000) >> 3;
                $val |= (1 << $bit);
                break;

            // Should never get here
            default:
                printf("Op CB %02X not implemented\n", $op);
                die("Op not implemented");
        }
        $this->set_reg($op, $val);
    }

    public function _xor(int $val)
    {
        $this->A ^= $val;

        $this->FLAG_Z = $this->A == 0;
        $this->FLAG_N = false;
        $this->FLAG_H = false;
        $this->FLAG_C = false;
    }

    public function _or(int $val)
    {
        $this->A |= $val;

        $this->FLAG_Z = $this->A == 0;
        $this->FLAG_N = false;
        $this->FLAG_H = false;
        $this->FLAG_C = false;
    }

    public function _and(int $val)
    {
        $this->A &= $val;

        $this->FLAG_Z = $this->A == 0;
        $this->FLAG_N = false;
        $this->FLAG_H = true;
        $this->FLAG_C = false;
    }

    public function _cp(int $val)
    {
        $this->FLAG_Z = $this->A == $val;
        $this->FLAG_N = true;
        $this->FLAG_H = ($this->A & 0x0F) < ($val & 0x0F);
        $this->FLAG_C = $this->A < $val;
    }

    public function _add(int $val)
    {
        $this->FLAG_C = uint16($this->A) + uint16($val) > 0xFF;
        $this->FLAG_H = ($this->A & 0x0F) + ($val & 0x0F) > 0x0F;
        $this->FLAG_N = false;
        $this->A = ($this->A + $val) & 0xFF;
        $this->FLAG_Z = $this->A == 0;
    }

    public function _adc(int $val)
    {
        if ($this->FLAG_C) {
            $carry = 1;
        } else {
            $carry = 0;
        }
        $this->FLAG_C = uint16($this->A) + uint16($val) + uint16($carry) > 0xFF;
        $this->FLAG_H = ($this->A & 0x0F) + ($val & 0x0F) + $carry > 0x0F;
        $this->FLAG_N = false;
        $this->A = ($this->A + $val + $carry) & 0xFF;
        $this->FLAG_Z = $this->A == 0;
    }

    public function _sub(int $val)
    {
        $this->FLAG_C = $this->A < $val;
        $this->FLAG_H = ($this->A & 0x0F) < ($val & 0x0F);
        $this->A = ($this->A - $val) & 0xFF;
        $this->FLAG_Z = $this->A == 0;
        $this->FLAG_N = true;
    }

    public function _sbc(int $val)
    {
        if ($this->FLAG_C) {
            $carry = 1;
        } else {
            $carry = 0;
        }
        $res = $this->A - $val - $carry;
        $this->FLAG_H = (($this->A ^ $val ^ (uint8($res) & 0xff)) & (1 << 4)) != 0;
        $this->FLAG_C = $res < 0;
        $this->A = ($this->A - $val - $carry) & 0xFF;
        $this->FLAG_Z = $this->A == 0;
        $this->FLAG_N = true;
    }

    public function push(int $val)
    {
        $this->ram->set($this->SP - 1, uint8((($val & 0xFF00) >> 8) & 0xFF));
        $this->ram->set($this->SP - 2, uint8($val & 0xFF));
        $this->SP -= 2;
    }

    public function pop(): int
    {
        $val = (uint16($this->ram->get($this->SP + 1)) << 8) | uint16($this->ram->get($this->SP));
        $this->SP += 2;
        return $val;
    }

    public function get_reg(int $n): int
    {
        switch ($n & 0x07) {
            case 0:
                return $this->B;
            case 1:
                return $this->C;
            case 2:
                return $this->D;
            case 3:
                return $this->E;
            case 4:
                return uint8($this->HL >> 8);
            case 5:
                return uint8($this->HL & 0xFF);
            case 6:
                return $this->ram->get($this->HL);
            case 7:
                return $this->A;
            default:
                printf("Invalid register %d\n", $n);
                return 0;
        }
    }

    public function set_reg(int $n, int $val)
    {
        switch ($n & 0x07) {
            case 0:
                $this->B = $val;
                break;
            case 1:
                $this->C = $val;
                break;
            case 2:
                $this->D = $val;
                break;
            case 3:
                $this->E = $val;
                break;
            case 4:
                [$_, $orig_l] = split16($this->HL);
                $this->HL = join16($val, $orig_l);
                break;
            case 5:
                [$orig_h, $_] = split16($this->HL);
                $this->HL = join16($orig_h, $val);
                break;
            case 6:
                $this->ram->set($this->HL, $val);
                break;
            case 7:
                $this->A = $val;
                break;
            default:
                printf("Invalid register %d\n", $n);
        }
    }
}
