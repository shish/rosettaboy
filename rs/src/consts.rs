use num_enum::TryFromPrimitive;

pub trait Address {
    fn to_u16(self) -> u16;
}
impl Address for u16 {
    fn to_u16(self) -> u16 {
        return self;
    }
}

pub enum Mem {
    TileData = 0x8000,
    Map0 = 0x9800,
    Map1 = 0x9C00,
    OamBase = 0xFE00,
}
impl Address for Mem {
    fn to_u16(self) -> u16 {
        return self as u16;
    }
}

bitflags! {
    pub struct Flag: u8 {
        const Z = 1<<7;
        const N = 1<<6;
        const H = 1<<5;
        const C = 1<<4;
    }
}

#[repr(u8)]
#[derive(Debug, Eq, PartialEq, TryFromPrimitive)]
pub enum CartType {
    RomOnly = 0x00,
    RomMbc1 = 0x01,
    RomMbc1Ram = 0x02,
    RomMbc1RamBatt = 0x03,
    RomMbc2 = 0x05,
    RomMbc2Batt = 0x06,
    RomRam = 0x08,
    RomRamBatt = 0x09,
    RomMmm01 = 0x0B,
    RomMmm01Sram = 0x0C,
    RomMmm01SramBatt = 0x0D,
    RomMbc3TimerBatt = 0x0F,
    RomMbc3TimerRamBatt = 0x10,
    RomMbc3 = 0x11,
    RomMbc3Ram = 0x12,
    RomMbc3RamBatt = 0x13,
    RomMbc5 = 0x19,
    RomMbc5Ram = 0x1A,
    RomMbc5RamBatt = 0x1B,
    RomMbc5Rumble = 0x1C,
    RomMbc5RumbleRam = 0x1D,
    RomMbc5RumbleRamBatt = 0x1E,
    PocketCamera = 0x1F,
    BandaiTama5 = 0xFD,
    HudsonHuc3 = 0xFE,
    HudsonHuc1 = 0xFF,
}

#[repr(u8)]
#[derive(Debug, Eq, PartialEq, TryFromPrimitive)]
pub enum Destination {
    Japan = 0,
    Other = 1,
}

#[repr(u8)]
#[derive(Debug, Eq, PartialEq, TryFromPrimitive)]
pub enum OldLicensee {
    MaybeNobody = 0x00,
    MaybeNintendo = 0x01,
    CheckNew = 0x33,
    Accolade = 0x79,
    Konami = 0xA4,
}

pub const OP_CYCLES: [u32; 0x100] = [
    // 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    1, 3, 2, 2, 1, 1, 2, 1, 5, 2, 2, 2, 1, 1, 2, 1, // 0
    0, 3, 2, 2, 1, 1, 2, 1, 3, 2, 2, 2, 1, 1, 2, 1, // 1
    2, 3, 2, 2, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 2, 1, // 2
    2, 3, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 1, 1, 2, 1, // 3
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 4
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 5
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 6
    2, 2, 2, 2, 2, 2, 0, 2, 1, 1, 1, 1, 1, 1, 2, 1, // 7
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 8
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // 9
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // A
    1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, // B
    2, 3, 3, 4, 3, 4, 2, 4, 2, 4, 3, 0, 3, 6, 2, 4, // C
    2, 3, 3, 0, 3, 4, 2, 4, 2, 4, 3, 0, 3, 0, 2, 4, // D
    3, 3, 2, 0, 0, 4, 2, 4, 4, 1, 4, 0, 0, 0, 2, 4, // E
    3, 3, 2, 1, 0, 4, 2, 4, 3, 2, 4, 1, 0, 0, 2, 4, // F
];

pub const OP_CB_CYCLES: [u32; 0x100] = [
    // 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 0
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 1
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 2
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 3
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 4
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 5
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 6
    2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, // 7
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 8
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // 9
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // A
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // B
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // C
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // D
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // E
    2, 2, 2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, 4, 2, // F
];

pub const OP_TYPES: [u8; 0x100] = [
    // 1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
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

// no arg, u8, u16, i8
pub const OP_LENS: [u16; 4] = [0, 1, 2, 1];

pub const OP_NAMES: [&str; 0x100] = [
    "NOP",
    "LD BC,nn",
    "LD [BC],A",
    "INC BC",
    "INC B",
    "DEC B",
    "LD B,n",
    "RCLA",
    "LD [nn],SP",
    "ADD HL,BC",
    "LD A,[BC]",
    "DEC BC",
    "INC C",
    "DEC C",
    "LD C,n",
    "RRCA",
    "STOP",
    "LD DE,nn",
    "LD [DE],A",
    "INC DE",
    "INC D",
    "DEC D",
    "LD D,n",
    "RLA",
    "JR n",
    "ADD HL,DE",
    "LD A,[DE]",
    "DEC DE",
    "INC E",
    "DEC E",
    "LD E,n",
    "RRA",
    "JR NZ,n",
    "LD HL,nn",
    "LD [HL+],A",
    "INC HL",
    "INC H",
    "DEC H",
    "LD H,n",
    "DAA",
    "JR Z,n",
    "ADD HL,HL",
    "LD A,[HL+]",
    "DEC HL",
    "INC L",
    "DEC L",
    "LD L,n",
    "CPL",
    "JR NC,n",
    "LD SP,nn",
    "LD [HL-],A",
    "INC SP",
    "INC [HL]",
    "DEC [HL]",
    "LD [HL],n",
    "SCF",
    "JR C,n",
    "ADD HL,SP",
    "LD A,[HL-]",
    "DEC SP",
    "INC A",
    "DEC A",
    "LD A,n",
    "CCF",
    "LD B,B",
    "LD B,C",
    "LD B,D",
    "LD B,E",
    "LD B,H",
    "LD B,L",
    "LD B,[HL]",
    "LD B,A",
    "LD C,B",
    "LD C,C",
    "LD C,D",
    "LD C,E",
    "LD C,H",
    "LD C,L",
    "LD C,[HL]",
    "LD C,A",
    "LD D,B",
    "LD D,C",
    "LD D,D",
    "LD D,E",
    "LD D,H",
    "LD D,L",
    "LD D,[HL]",
    "LD D,A",
    "LD E,B",
    "LD E,C",
    "LD E,D",
    "LD E,E",
    "LD E,H",
    "LD E,L",
    "LD E,[HL]",
    "LD E,A",
    "LD H,B",
    "LD H,C",
    "LD H,D",
    "LD H,E",
    "LD H,H",
    "LD H,L",
    "LD H,[HL]",
    "LD H,A",
    "LD L,B",
    "LD L,C",
    "LD L,D",
    "LD L,E",
    "LD L,H",
    "LD L,L",
    "LD L,[HL]",
    "LD L,A",
    "LD [HL],B",
    "LD [HL],C",
    "LD [HL],D",
    "LD [HL],E",
    "LD [HL],H",
    "LD [HL],L",
    "HALT",
    "LD [HL],A",
    "LD A,B",
    "LD A,C",
    "LD A,D",
    "LD A,E",
    "LD A,H",
    "LD A,L",
    "LD A,[HL]",
    "LD A,A",
    "ADD A,B",
    "ADD A,C",
    "ADD A,D",
    "ADD A,E",
    "ADD A,H",
    "ADD A,L",
    "ADD A,[HL]",
    "ADD A,A",
    "ADC A,B",
    "ADC A,C",
    "ADC A,D",
    "ADC A,E",
    "ADC A,H",
    "ADC A,L",
    "ADC A,[HL]",
    "ADC A,A",
    "SUB A,B",
    "SUB A,C",
    "SUB A,D",
    "SUB A,E",
    "SUB A,H",
    "SUB A,L",
    "SUB A,[HL]",
    "SUB A,A",
    "SBC A,B",
    "SBC A,C",
    "SBC A,D",
    "SBC A,E",
    "SBC A,H",
    "SBC A,L",
    "SBC A,[HL]",
    "SBC A,A",
    "AND B",
    "AND C",
    "AND D",
    "AND E",
    "AND H",
    "AND L",
    "AND [HL]",
    "AND A",
    "XOR B",
    "XOR C",
    "XOR D",
    "XOR E",
    "XOR H",
    "XOR L",
    "XOR [HL]",
    "XOR A",
    "OR B",
    "OR C",
    "OR D",
    "OR E",
    "OR H",
    "OR L",
    "OR [HL]",
    "OR A",
    "CP B",
    "CP C",
    "CP D",
    "CP E",
    "CP H",
    "CP L",
    "CP [HL]",
    "CP A",
    "RET NZ",
    "POP BC",
    "JP NZ,n",
    "JP nn",
    "CALL NZ,nn",
    "PUSH BC",
    "ADD A,n",
    "RST 00",
    "RET Z",
    "RET",
    "JP Z,n",
    "ERR CB",
    "CALL Z,nn",
    "CALL nn",
    "ADC A,n",
    "RST 08",
    "RET NC",
    "POP DE",
    "JP NC,n",
    "ERR D3",
    "CALL NC,nn",
    "PUSH DE",
    "SUB A,n",
    "RST 10",
    "RET C",
    "RETI",
    "JP C,n",
    "ERR DB",
    "CALL C,nn",
    "ERR DD",
    "SBC A,n",
    "RST 18",
    "LDH [n],A",
    "POP HL",
    "LDH [C],A",
    "DBG",
    "ERR E4",
    "PUSH HL",
    "AND n",
    "RST 20",
    "ADD SP n",
    "JP HL",
    "LD [nn],A",
    "ERR EB",
    "ERR EC",
    "ERR ED",
    "XOR n",
    "RST 28",
    "LDH A,[n]",
    "POP AF",
    "LDH A,[C]",
    "DI",
    "ERR F4",
    "PUSH AF",
    "OR n",
    "RST 30",
    "LD HL,SP+n",
    "LD SP,HL",
    "LD A,[nn]",
    "EI",
    "ERR FC",
    "ERR FD",
    "CP n",
    "RST 38",
];

pub const OP_CB_NAMES: [&str; 0x100] = [
    "RLC B",
    "RLC C",
    "RLC D",
    "RLC E",
    "RLC H",
    "RLC L",
    "RLC [HL]",
    "RLC A",
    "RRC B",
    "RRC C",
    "RRC D",
    "RRC E",
    "RRC H",
    "RRC L",
    "RRC [HL]",
    "RRC A",
    "RL B",
    "RL C",
    "RL D",
    "RL E",
    "RL H",
    "RL L",
    "RL [HL]",
    "RL A",
    "RR B",
    "RR C",
    "RR D",
    "RR E",
    "RR H",
    "RR L",
    "RR [HL]",
    "RR A",
    "SLA B",
    "SLA C",
    "SLA D",
    "SLA E",
    "SLA H",
    "SLA L",
    "SLA [HL]",
    "SLA A",
    "SRA B",
    "SRA C",
    "SRA D",
    "SRA E",
    "SRA H",
    "SRA L",
    "SRA [HL]",
    "SRA A",
    "SWAP B",
    "SWAP C",
    "SWAP D",
    "SWAP E",
    "SWAP H",
    "SWAP L",
    "SWAP [HL]",
    "SWAP A",
    "SRL B",
    "SRL C",
    "SRL D",
    "SRL E",
    "SRL H",
    "SRL L",
    "SRL [HL]",
    "SRL A",
    "BIT 0,B",
    "BIT 0,C",
    "BIT 0,D",
    "BIT 0,E",
    "BIT 0,H",
    "BIT 0,L",
    "BIT 0,[HL]",
    "BIT 0,A",
    "BIT 1,B",
    "BIT 1,C",
    "BIT 1,D",
    "BIT 1,E",
    "BIT 1,H",
    "BIT 1,L",
    "BIT 1,[HL]",
    "BIT 1,A",
    "BIT 2,B",
    "BIT 2,C",
    "BIT 2,D",
    "BIT 2,E",
    "BIT 2,H",
    "BIT 2,L",
    "BIT 2,[HL]",
    "BIT 2,A",
    "BIT 3,B",
    "BIT 3,C",
    "BIT 3,D",
    "BIT 3,E",
    "BIT 3,H",
    "BIT 3,L",
    "BIT 3,[HL]",
    "BIT 3,A",
    "BIT 4,B",
    "BIT 4,C",
    "BIT 4,D",
    "BIT 4,E",
    "BIT 4,H",
    "BIT 4,L",
    "BIT 4,[HL]",
    "BIT 4,A",
    "BIT 5,B",
    "BIT 5,C",
    "BIT 5,D",
    "BIT 5,E",
    "BIT 5,H",
    "BIT 5,L",
    "BIT 5,[HL]",
    "BIT 5,A",
    "BIT 6,B",
    "BIT 6,C",
    "BIT 6,D",
    "BIT 6,E",
    "BIT 6,H",
    "BIT 6,L",
    "BIT 6,[HL]",
    "BIT 6,A",
    "BIT 7,B",
    "BIT 7,C",
    "BIT 7,D",
    "BIT 7,E",
    "BIT 7,H",
    "BIT 7,L",
    "BIT 7,[HL]",
    "BIT 7,A",
    "RES 0,B",
    "RES 0,C",
    "RES 0,D",
    "RES 0,E",
    "RES 0,H",
    "RES 0,L",
    "RES 0,[HL]",
    "RES 0,A",
    "RES 1,B",
    "RES 1,C",
    "RES 1,D",
    "RES 1,E",
    "RES 1,H",
    "RES 1,L",
    "RES 1,[HL]",
    "RES 1,A",
    "RES 2,B",
    "RES 2,C",
    "RES 2,D",
    "RES 2,E",
    "RES 2,H",
    "RES 2,L",
    "RES 2,[HL]",
    "RES 2,A",
    "RES 3,B",
    "RES 3,C",
    "RES 3,D",
    "RES 3,E",
    "RES 3,H",
    "RES 3,L",
    "RES 3,[HL]",
    "RES 3,A",
    "RES 4,B",
    "RES 4,C",
    "RES 4,D",
    "RES 4,E",
    "RES 4,H",
    "RES 4,L",
    "RES 4,[HL]",
    "RES 4,A",
    "RES 5,B",
    "RES 5,C",
    "RES 5,D",
    "RES 5,E",
    "RES 5,H",
    "RES 5,L",
    "RES 5,[HL]",
    "RES 5,A",
    "RES 6,B",
    "RES 6,C",
    "RES 6,D",
    "RES 6,E",
    "RES 6,H",
    "RES 6,L",
    "RES 6,[HL]",
    "RES 6,A",
    "RES 7,B",
    "RES 7,C",
    "RES 7,D",
    "RES 7,E",
    "RES 7,H",
    "RES 7,L",
    "RES 7,[HL]",
    "RES 7,A",
    "SET 0,B",
    "SET 0,C",
    "SET 0,D",
    "SET 0,E",
    "SET 0,H",
    "SET 0,L",
    "SET 0,[HL]",
    "SET 0,A",
    "SET 1,B",
    "SET 1,C",
    "SET 1,D",
    "SET 1,E",
    "SET 1,H",
    "SET 1,L",
    "SET 1,[HL]",
    "SET 1,A",
    "SET 2,B",
    "SET 2,C",
    "SET 2,D",
    "SET 2,E",
    "SET 2,H",
    "SET 2,L",
    "SET 2,[HL]",
    "SET 2,A",
    "SET 3,B",
    "SET 3,C",
    "SET 3,D",
    "SET 3,E",
    "SET 3,H",
    "SET 3,L",
    "SET 3,[HL]",
    "SET 3,A",
    "SET 4,B",
    "SET 4,C",
    "SET 4,D",
    "SET 4,E",
    "SET 4,H",
    "SET 4,L",
    "SET 4,[HL]",
    "SET 4,A",
    "SET 5,B",
    "SET 5,C",
    "SET 5,D",
    "SET 5,E",
    "SET 5,H",
    "SET 5,L",
    "SET 5,[HL]",
    "SET 5,A",
    "SET 6,B",
    "SET 6,C",
    "SET 6,D",
    "SET 6,E",
    "SET 6,H",
    "SET 6,L",
    "SET 6,[HL]",
    "SET 6,A",
    "SET 7,B",
    "SET 7,C",
    "SET 7,D",
    "SET 7,E",
    "SET 7,H",
    "SET 7,L",
    "SET 7,[HL]",
    "SET 7,A",
];

pub enum IO {
    JOYP = 0xFF00,

    _SB = 0xFF01, // Serial Data
    _SC = 0xFF02, // Serial Control

    DIV = 0xFF04,
    TIMA = 0xFF05,
    TMA = 0xFF06,
    TAC = 0xFF07,

    IF = 0xFF0F,

    /*
    NR10 = 0xFF10,
    NR11 = 0xFF11,
    NR12 = 0xFF12,
    NR13 = 0xFF13,
    NR14 = 0xFF14,

    NR20 = 0xFF15,
    NR21 = 0xFF16,
    NR22 = 0xFF17,
    NR23 = 0xFF18,
    NR24 = 0xFF19,

    NR30 = 0xFF1A,
    NR31 = 0xFF1B,
    NR32 = 0xFF1C,
    NR33 = 0xFF1D,
    NR34 = 0xFF1E,

    NR40 = 0xFF1F,
    NR41 = 0xFF20,
    NR42 = 0xFF21,
    NR43 = 0xFF22,
    NR44 = 0xFF23,

    NR50 = 0xFF24,
    NR51 = 0xFF25,
    NR52 = 0xFF26,
    */
    LCDC = 0xFF40,
    STAT = 0xFF41,
    SCY = 0xFF42, // SCROLL_Y
    SCX = 0xFF43, // SCROLL_X
    LY = 0xFF44,  // LY aka currently drawn line, 0-153, >144 = vblank
    LYC = 0xFF45,
    DMA = 0xFF46,
    BGP = 0xFF47,
    OBP0 = 0xFF48,
    OBP1 = 0xFF49,
    WY = 0xFF4A,
    WX = 0xFF4B,
    BOOT = 0xFF50,

    IE = 0xFFFF,
}
impl Address for IO {
    fn to_u16(self) -> u16 {
        return self as u16;
    }
}

bitflags! {
    pub struct LCDC: u8 {
        const ENABLED = 1<<7;
        const WINDOW_MAP = 1<<6;
        const WINDOW_ENABLED = 1<<5;
        const DATA_SRC = 1<<4;
        const BG_MAP = 1<<3;
        const OBJ_SIZE = 1<<2;
        const OBJ_ENABLED = 1<<1;
        const BG_WIN_ENABLED = 1<<0;
    }
}

bitflags! {
    pub struct Stat: u8 {
        const LCY_INTERRUPT = 1<<6;
        const OAM_INTERRUPT = 1<<5;
        const VBLANK_INTERRUPT = 1<<4;
        const HBLANK_INTERRUPT = 1<<3;
        const LCY_EQUAL = 1<<2;
        const MODE_BITS = 0b00000011;
        const HBLANK = 0x00;
        const VBLANK = 0x01;
        const OAM = 0x02;
        const DRAWING = 0x03;
    }
}

bitflags! {
    pub struct Interrupt: u8 {
        const VBLANK = 1<<0;
        const STAT = 1<<1;
        const TIMER = 1<<2;
        const SERIAL = 1<<3;
        const JOYPAD = 1<<4;
    }
}

bitflags! {
    pub struct Joypad: u8 {
        const MODE_BUTTONS = 1<<5;
        const MODE_DPAD = 1<<4;

        const START = 1<<3;
        const SELECT = 1<<2;
        const B = 1<<1;
        const A = 1<<0;

        const DOWN = 1<<3;
        const UP = 1<<2;
        const LEFT = 1<<1;
        const RIGHT = 1<<0;

        const BUTTON_BITS = 0b00001111;
    }
}

pub enum InterruptHandler {
    VblankHandler = 0x40,
    LcdHandler = 0x48,
    TimerHandler = 0x50,
    SerialHandler = 0x58,
    JoypadHandler = 0x60,
}
impl Address for InterruptHandler {
    fn to_u16(self) -> u16 {
        return self as u16;
    }
}
