package main

import "fmt"

var OP_CYCLES = [256]uint8{
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
}

var OP_CB_CYCLES = [256]uint8{
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
}

var OP_ARG_TYPES = [256]uint8{
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
}

var OP_ARG_BYTES = [4]uint8{0, 1, 2, 1}

var OP_NAMES = [256]string{
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
}

var CB_OP_NAMES = [256]string{
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
}

type CPU struct {
	debug       bool
	ram         *RAM
	stop        bool
	halt        bool
	owed_cycles uint8
	interrupts  bool
	cycle       int

	// FIXME: these should be unioned
	// A, B, C, D, E, H, L, F         uint8
	// AF, BC, DE, HL, SP, PC         uint16
	A, B, C, D, E, F               uint8
	HL, SP, PC                     uint16
	FLAG_Z, FLAG_N, FLAG_H, FLAG_C bool
}

type oparg struct {
	// FIXME should be a union
	as_u8  uint8  // B
	as_i8  int8   // b
	as_u16 uint16 // H
}

func NewCPU(ram *RAM, debug bool) CPU {
	return CPU{
		debug, ram, false, false, 0, false, 0,
		0, 0, 0, 0, 0, 0,
		0, 0, 0,
		false, false, false, false,
	}
}

func (self *CPU) tick() bool {
	self.tick_dma()
	if !self.tick_clock() {
		return false
	}
	if !self.tick_interrupts() {
		return false
	}
	if self.halt {
		return true
	}
	if self.stop {
		return false
	}
	if !self.tick_instructions() {
		return false
	}
	return true
}

func (self *CPU) interrupt(i byte) {
	// Set a given interrupt bit - on the next tick, if the interrupt
	// handler for self interrupt is enabled (and interrupts in general
	// are enabled), then the interrupt handler will be called.
	self.ram.data[IO_IF] |= i
	self.halt = false // interrupts interrupt HALT state
}

func _tert(val, a, b uint8) uint8 {
	if val > 0 {
		return a
	} else {
		return b
	}
}
func split16(val uint16) (uint8, uint8) {
	return uint8(val >> 8), uint8(val & 0xFF)
}
func join16(a, b uint8) uint16 {
	return (uint16(a) << 8) | uint16(b)
}

func (self *CPU) dump_regs() {
	var IE = self.ram.get(IO_IE)
	var IF = self.ram.get(IO_IF)
	var z = 'z' ^ ((self.F>>7)&1)<<5
	var n = 'n' ^ ((self.F>>6)&1)<<5
	var h = 'h' ^ ((self.F>>5)&1)<<5
	var c = 'c' ^ ((self.F>>4)&1)<<5
	var v = _tert((IE>>0)&1, 'v'^((IF>>0)&1)<<5, '_')
	var l = _tert((IE>>1)&1, 'l'^((IF>>1)&1)<<5, '_')
	var t = _tert((IE>>2)&1, 't'^((IF>>2)&1)<<5, '_')
	var s = _tert((IE>>3)&1, 's'^((IF>>3)&1)<<5, '_')
	var j = _tert((IE>>4)&1, 'j'^((IF>>4)&1)<<5, '_')
	var op = self.ram.get(self.PC)
	var op_str = ""
	if op == 0xCB {
		op = self.ram.get(self.PC + 1)
		op_str = CB_OP_NAMES[op]
	} else {
		switch OP_ARG_TYPES[op] {
		case 0:
			op_str = OP_NAMES[op]
		case 1:
			op_str = fmt.Sprintf(OP_NAMES[op], self.ram.get(self.PC+1))
		case 2:
			op_str = fmt.Sprintf(OP_NAMES[op], uint16(self.ram.get(self.PC+2))<<8|uint16(self.ram.get(self.PC+1)))
		case 3:
			op_str = fmt.Sprintf(OP_NAMES[op], int8(self.ram.get(self.PC+1)))
		}
	}
	// if(cycle % 10 == 0)
	// printf("A F  B C  D E  H L  : SP   = [SP] : F    : IE/IF : PC   = OP : INSTR\n");
	fmt.Printf("%02X%02X %02X%02X %02X%02X %04X : %04X = %02X%02X : %c%c%c%c : %c%c%c%c%c : %04X = %02X : %s\n",
		self.A, self.F, self.B, self.C, self.D, self.E, self.HL,
		self.SP, self.ram.get(self.SP+1), self.ram.get(self.SP),
		z, n, h, c,
		v, l, t, s, j,
		self.PC, op, op_str,
	)
}

func (self *CPU) tick_dma() {
	// TODO: DMA should take 26 cycles, during which main RAM is inaccessible
	if self.ram.get(IO_DMA) > 0 {
		var dma_src = uint16(self.ram.get(IO_DMA)) << 8
		for i := 0; i < 0x60; i++ {
			self.ram.set(uint16(OAM_BASE+i), self.ram.get(dma_src+uint16(i)))
		}
		self.ram.set(IO_DMA, 0x00)
	}

}
func (self *CPU) tick_clock() bool {
	self.cycle++

	// TODO: writing any value to IO_DIV should reset it to 0x00
	// increment at 16384Hz (each 64 cycles?)
	if self.cycle%64 == 0 {
		self.ram._inc(IO_DIV)
	}

	if self.ram.get(IO_TAC)&(1<<2) > 0 { // timer enable
		var speeds = []uint16{256, 4, 16, 64} // increment per X cycles
		var speed = speeds[self.ram.get(IO_TAC)&0x03]
		if self.cycle%int(speed) == 0 {
			if self.ram.get(IO_TIMA) == 0xFF {
				self.ram.set(IO_TIMA, self.ram.get(IO_TMA)) // if timer overflows, load base
				self.interrupt(INT_TIMER)
			}
			self.ram._inc(IO_TIMA)
		}
	}
	return true
}
func (self *CPU) tick_interrupts() bool {
	var queued_interrupts = self.ram.get(IO_IE) & self.ram.get(IO_IF)
	if self.interrupts && (queued_interrupts != 0x00) {
		if self.debug {
			fmt.Printf("Handling interrupts: %02X & %02X\n", self.ram.get(IO_IE), self.ram.get(IO_IF))
		}
		self.interrupts = false // no nested interrupts, RETI will re-enable
		// TODO: wait two cycles
		// TODO: push16(PC) should also take two cycles
		// TODO: one more cycle to store new PC
		if queued_interrupts&INT_VBLANK > 0 {
			self.push(self.PC)
			self.PC = VBLANK_HANDLER
			self.ram._and(IO_IF, ^INT_VBLANK)
		} else if queued_interrupts&INT_STAT > 0 {
			self.push(self.PC)
			self.PC = LCD_HANDLER
			self.ram._and(IO_IF, ^INT_STAT)
		} else if queued_interrupts&INT_TIMER > 0 {
			self.push(self.PC)
			self.PC = TIMER_HANDLER
			self.ram._and(IO_IF, ^INT_TIMER)
		} else if queued_interrupts&INT_SERIAL > 0 {
			self.push(self.PC)
			self.PC = SERIAL_HANDLER
			self.ram._and(IO_IF, ^INT_SERIAL)
		} else if queued_interrupts&INT_JOYPAD > 0 {
			self.push(self.PC)
			self.PC = JOYPAD_HANDLER
			self.ram._and(IO_IF, ^INT_JOYPAD)
		}
	}
	return true
}
func (self *CPU) tick_instructions() bool {
	// if the previous instruction was large, let's not run any
	// more instructions until other subsystems have caught up
	if self.owed_cycles > 0 {
		self.owed_cycles--
		return true
	}

	if self.debug {
		self.dump_regs()
	}

	var op = self.ram.get(self.PC)
	self.PC++
	if op == 0xCB {
		op = self.ram.get(self.PC)
		self.PC++
		self.tick_cb(op)
		self.owed_cycles = OP_CB_CYCLES[op] - 1
	} else {
		self.tick_main(op)
		self.owed_cycles = OP_CYCLES[op] - 1
	}

	// Flags should be union'ed with the F register, but go doesn't
	// support that, so let's manually sync from flags to register
	// after every instruction...
	self.F = 0
	if self.FLAG_Z {
		self.F |= 1 << 7
	}
	if self.FLAG_N {
		self.F |= 1 << 6
	}
	if self.FLAG_H {
		self.F |= 1 << 5
	}
	if self.FLAG_C {
		self.F |= 1 << 4
	}

	// HALT has cycles=0
	if self.owed_cycles < 0 {
		self.owed_cycles = 0
	}
	return true
}

func (self *CPU) tick_main(op uint8) {
	// Load args
	var arg oparg
	arg.as_u16 = 0
	var nargs = OP_ARG_BYTES[OP_ARG_TYPES[op]]
	if nargs == 1 {
		arg.as_u8 = self.ram.get(self.PC)
		arg.as_i8 = int8(arg.as_u8)
		self.PC++
	}
	if nargs == 2 {
		var low = self.ram.get(self.PC)
		self.PC++
		var high = self.ram.get(self.PC)
		self.PC++
		arg.as_u16 = uint16(high)<<8 | uint16(low)
	}

	// Execute
	var val uint8 = 0
	var carry uint8 = 0
	var val16 uint16 = 0
	switch op {
	case 0x00: /* NOP */
		break
	case 0x01:
		self.B, self.C = split16(arg.as_u16)
	case 0x02:
		self.ram.set(join16(self.B, self.C), self.A)
	case 0x03:
		self.B, self.C = split16(join16(self.B, self.C) + 1)
	case 0x08:
		self.ram.set(arg.as_u16+1, uint8((self.SP>>8)&0xFF))
		self.ram.set(arg.as_u16, uint8(self.SP&0xFF))
	case 0x0A:
		self.A = self.ram.get(join16(self.B, self.C))
	case 0x0B:
		self.B, self.C = split16(join16(self.B, self.C) - 1)

	case 0x10:
		self.stop = true
	case 0x11:
		self.D, self.E = split16(arg.as_u16)
	case 0x12:
		self.ram.set(join16(self.D, self.E), self.A)
	case 0x13:
		self.D, self.E = split16(join16(self.D, self.E) + 1)
	case 0x18:
		self.PC += uint16(arg.as_i8)
	case 0x1A:
		self.A = self.ram.get(join16(self.D, self.E))
	case 0x1B:
		self.D, self.E = split16(join16(self.D, self.E) - 1)

	case 0x20:
		if !self.FLAG_Z {
			self.PC += uint16(arg.as_i8)
		}
	case 0x21:
		self.HL = arg.as_u16
	case 0x22:
		self.ram.set(self.HL, self.A)
		self.HL++
	case 0x23:
		self.HL++
	case 0x27:
		val16 = uint16(self.A)
		if !self.FLAG_N {
			if self.FLAG_H || (val16&0x0F) > 9 {
				val16 += 6
			}
			if self.FLAG_C || val16 > 0x9F {
				val16 += 0x60
			}
		} else {
			if self.FLAG_H {
				val16 -= 6
				if !self.FLAG_C {
					val16 &= 0xFF
				}
			}
			if self.FLAG_C {
				val16 -= 0x60
			}
		}
		self.FLAG_H = false
		if val16&0x100 > 0 {
			self.FLAG_C = true
		}
		self.A = uint8(val16 & 0xFF)
		self.FLAG_Z = self.A == 0
	case 0x28:
		if self.FLAG_Z {
			self.PC += uint16(arg.as_i8)
		}
	case 0x2A:
		self.A = self.ram.get(self.HL)
		self.HL++
	case 0x2B:
		self.HL--
	case 0x2F:
		self.A ^= 0xFF
		self.FLAG_N = true
		self.FLAG_H = true

	case 0x30:
		if !self.FLAG_C {
			self.PC += uint16(arg.as_i8)
		}
	case 0x31:
		self.SP = arg.as_u16
	case 0x32:
		self.ram.set(self.HL, self.A)
		self.HL--
	case 0x33:
		self.SP++
	case 0x37:
		self.FLAG_N = false
		self.FLAG_H = false
		self.FLAG_C = true
	case 0x38:
		if self.FLAG_C {
			self.PC += uint16(arg.as_i8)
		}
	case 0x3A:
		self.A = self.ram.get(self.HL)
		self.HL--
	case 0x3B:
		self.SP--
	case 0x3F:
		self.FLAG_C = !self.FLAG_C
		self.FLAG_N = false
		self.FLAG_H = false

	// INC r
	case 0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C:
		val = self.get_reg((op - 0x04) / 8)
		self.FLAG_H = (val & 0x0F) == 0x0F
		val++
		self.FLAG_Z = val == 0
		self.FLAG_N = false
		self.set_reg((op-0x04)/8, val)

	// DEC r
	case 0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D:
		val = self.get_reg((op - 0x05) / 8)
		val--
		self.FLAG_H = (val & 0x0F) == 0x0F
		self.FLAG_Z = val == 0
		self.FLAG_N = true
		self.set_reg((op-0x05)/8, val)

	// LD r,n
	case 0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E:
		self.set_reg((op-0x06)/8, arg.as_u8)

	// RCLA, RLA, RRCA, RRA
	case 0x07, 0x17, 0x0F, 0x1F:
		if self.FLAG_C {
			carry = 1
		} else {
			carry = 0
		}
		if op == 0x07 { // RCLA
			self.FLAG_C = (self.A & (1 << 7)) != 0
			self.A = (self.A << 1) | (self.A >> 7)
		}
		if op == 0x17 { // RLA
			self.FLAG_C = (self.A & (1 << 7)) != 0
			self.A = (self.A << 1) | carry
		}
		if op == 0x0F { // RRCA
			self.FLAG_C = (self.A & (1 << 0)) != 0
			self.A = (self.A >> 1) | (self.A << 7)
		}
		if op == 0x1F { // RRA
			self.FLAG_C = (self.A & (1 << 0)) != 0
			self.A = (self.A >> 1) | (carry << 7)
		}
		self.FLAG_N = false
		self.FLAG_H = false
		self.FLAG_Z = false

	// ADD HL,rr
	case 0x09, 0x19, 0x29, 0x39:
		if op == 0x09 {
			val16 = join16(self.B, self.C)
		}
		if op == 0x19 {
			val16 = join16(self.D, self.E)
		}
		if op == 0x29 {
			val16 = self.HL
		}
		if op == 0x39 {
			val16 = self.SP
		}
		self.FLAG_H = ((self.HL&0x0FFF)+(val16&0x0FFF) > 0x0FFF)
		self.FLAG_C = (int(self.HL)+int(val16) > 0xFFFF)
		self.HL += val16
		self.FLAG_N = false

	// LD r,r
	case 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
		0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F,
		0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
		0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F,
		0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
		0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F,
		0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
		0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7E, 0x7F:
		if op == 0x76 {
			// FIXME: weird timing side effects
			self.halt = true
			break
		}
		self.set_reg((op-0x40)>>3, self.get_reg(op-0x40))

	case 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87:
		self._add(self.get_reg(op))
	case 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F:
		self._adc(self.get_reg(op))
	case 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97:
		self._sub(self.get_reg(op))
	case 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F:
		self._sbc(self.get_reg(op))
	case 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7:
		self._and(self.get_reg(op))
	case 0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF:
		self._xor(self.get_reg(op))
	case 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7:
		self._or(self.get_reg(op))
	case 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF:
		self._cp(self.get_reg(op))

	case 0xC0:
		if !self.FLAG_Z {
			self.PC = self.pop()
		}
	case 0xC1:
		self.B, self.C = split16(self.pop())
	case 0xC2:
		if !self.FLAG_Z {
			self.PC = arg.as_u16
		}
	case 0xC3:
		self.PC = arg.as_u16
	case 0xC4:
		if !self.FLAG_Z {
			self.push(self.PC)
			self.PC = arg.as_u16
		}
	case 0xC5:
		self.push(join16(self.B, self.C))
	case 0xC6:
		self._add(arg.as_u8)
	case 0xC7:
		self.push(self.PC)
		self.PC = 0x00
	case 0xC8:
		if self.FLAG_Z {
			self.PC = self.pop()
		}
	case 0xC9:
		self.PC = self.pop()
	case 0xCA:
		if self.FLAG_Z {
			self.PC = arg.as_u16
		}
	// case 0xCB: break;
	case 0xCC:
		if self.FLAG_Z {
			self.push(self.PC)
			self.PC = arg.as_u16
		}
	case 0xCD:
		self.push(self.PC)
		self.PC = arg.as_u16
	case 0xCE:
		self._adc(arg.as_u8)
	case 0xCF:
		self.push(self.PC)
		self.PC = 0x08

	case 0xD0:
		if !self.FLAG_C {
			self.PC = self.pop()
		}
	case 0xD1:
		self.D, self.E = split16(self.pop())
	case 0xD2:
		if !self.FLAG_C {
			self.PC = arg.as_u16
		}
	// case 0xD3: break;
	case 0xD4:
		if !self.FLAG_C {
			self.push(self.PC)
			self.PC = arg.as_u16
		}
	case 0xD5:
		self.push(join16(self.D, self.E))
	case 0xD6:
		self._sub(arg.as_u8)
	case 0xD7:
		self.push(self.PC)
		self.PC = 0x10
	case 0xD8:
		if self.FLAG_C {
			self.PC = self.pop()
		}
	case 0xD9:
		self.PC = self.pop()
		self.interrupts = true
	case 0xDA:
		if self.FLAG_C {
			self.PC = arg.as_u16
		}
	// case 0xDB: break;
	case 0xDC:
		if self.FLAG_C {
			self.push(self.PC)
			self.PC = arg.as_u16
		}
	// case 0xDD: break;
	case 0xDE:
		self._sbc(arg.as_u8)
	case 0xDF:
		self.push(self.PC)
		self.PC = 0x18

	case 0xE0:
		self.ram.set(0xFF00+uint16(arg.as_u8), self.A)
		if arg.as_u8 == 0x01 {
			fmt.Printf("%c", self.A)
		}
	case 0xE1:
		self.HL = self.pop()
	case 0xE2:
		self.ram.set(0xFF00+uint16(self.C), self.A)
		if self.C == 0x01 {
			fmt.Printf("%c", self.A)
		}
	// case 0xE3: break;
	// case 0xE4: break;
	case 0xE5:
		self.push(self.HL)
	case 0xE6:
		self._and(arg.as_u8)
	case 0xE7:
		self.push(self.PC)
		self.PC = 0x20
	case 0xE8:
		val16 = self.SP + uint16(arg.as_i8)
		//self.FLAG_H = ((self.SP & 0x0FFF) + (arg.as_i8 & 0x0FFF) > 0x0FFF);
		//self.FLAG_C = (self.SP + arg.as_i8 > 0xFFFF);
		self.FLAG_H = (self.SP^uint16(arg.as_i8)^val16)&0x10 > 0
		self.FLAG_C = (self.SP^uint16(arg.as_i8)^val16)&0x100 > 0
		self.SP += uint16(arg.as_i8)
		self.FLAG_Z = false
		self.FLAG_N = false
	case 0xE9:
		self.PC = self.HL
	case 0xEA:
		self.ram.set(arg.as_u16, self.A)
	// case 0xEB: break;
	// case 0xEC: break;
	// case 0xED: break;
	case 0xEE:
		self._xor(arg.as_u8)
	case 0xEF:
		self.push(self.PC)
		self.PC = 0x28

	case 0xF0:
		self.A = self.ram.get(0xFF00 + uint16(arg.as_u8))
	case 0xF1:
		self.A, self.F = split16(self.pop() & 0xFFF0)
		self.FLAG_Z = self.F&(1<<7) > 0
		self.FLAG_N = self.F&(1<<6) > 0
		self.FLAG_H = self.F&(1<<5) > 0
		self.FLAG_C = self.F&(1<<4) > 0
	case 0xF2:
		self.A = self.ram.get(0xFF00 + uint16(self.C))
	case 0xF3:
		self.interrupts = false
	// case 0xF4: break;
	case 0xF5:
		self.push(join16(self.A, self.F))
	case 0xF6:
		self._or(arg.as_u8)
	case 0xF7:
		self.push(self.PC)
		self.PC = 0x30
	case 0xF8:
		if arg.as_i8 >= 0 {
			self.FLAG_C = (int(self.SP&0xFF) + (int(arg.as_i8) & 0xFF)) > 0xFF
			self.FLAG_H = (int(self.SP&0x0F) + (int(arg.as_i8) & 0x0F)) > 0x0F
		} else {
			self.FLAG_C = uint8((int(self.SP)+int(arg.as_i8))&0xFF) <= uint8(self.SP&0xFF)
			self.FLAG_H = uint8((int(self.SP)+int(arg.as_i8))&0x0F) <= uint8(self.SP&0x0F)
		}
		// self.FLAG_H = ((((self.SP & 0x0f) + (arg.as_u8 & 0x0f)) & 0x10) != 0);
		// self.FLAG_C = ((((self.SP & 0xff) + (arg.as_u8 & 0xff)) & 0x100) != 0);
		self.HL = self.SP + uint16(arg.as_i8)
		self.FLAG_Z = false
		self.FLAG_N = false
	case 0xF9:
		self.SP = self.HL
	case 0xFA:
		self.A = self.ram.get(arg.as_u16)
	case 0xFB:
		self.interrupts = true
	// case 0xFC: break;
	// case 0xFD: break;
	case 0xFE:
		self._cp(arg.as_u8)
	case 0xFF:
		self.push(self.PC)
		self.PC = 0x38

	// missing ops
	default:
		fmt.Printf("Op %02X not implemented\n", op)
		panic("Op not implemented")
	}
}
func (self *CPU) tick_cb(op uint8) {
	var val, bit uint8
	var orig_c bool

	val = self.get_reg(op)
	switch {
	// RLC
	case op <= 0x07:
		self.FLAG_C = (val & (1 << 7)) != 0
		val <<= 1
		if self.FLAG_C {
			val |= (1 << 0)
		}
		self.FLAG_N = false
		self.FLAG_H = false
		self.FLAG_Z = val == 0

	// RRC
	case op <= 0x0F:
		self.FLAG_C = (val & (1 << 0)) != 0
		val >>= 1
		if self.FLAG_C {
			val |= (1 << 7)
		}
		self.FLAG_N = false
		self.FLAG_H = false
		self.FLAG_Z = val == 0

	// RL
	case op <= 0x17:
		orig_c = self.FLAG_C
		self.FLAG_C = (val & (1 << 7)) != 0
		val <<= 1
		if orig_c {
			val |= (1 << 0)
		}
		self.FLAG_N = false
		self.FLAG_H = false
		self.FLAG_Z = val == 0

	// RR
	case op <= 0x1F:
		orig_c = self.FLAG_C
		self.FLAG_C = (val & (1 << 0)) != 0
		val >>= 1
		if orig_c {
			val |= (1 << 7)
		}
		self.FLAG_N = false
		self.FLAG_H = false
		self.FLAG_Z = val == 0

	// SLA
	case op <= 0x27:
		self.FLAG_C = (val & (1 << 7)) != 0
		val <<= 1
		val &= 0xFF
		self.FLAG_N = false
		self.FLAG_H = false
		self.FLAG_Z = val == 0

	// SRA
	case op <= 0x2F:
		self.FLAG_C = (val & (1 << 0)) != 0
		val >>= 1
		if val&(1<<6) > 0 {
			val |= (1 << 7)
		}
		self.FLAG_N = false
		self.FLAG_H = false
		self.FLAG_Z = val == 0

	// SWAP
	case op <= 0x37:
		val = ((val & 0xF0) >> 4) | ((val & 0x0F) << 4)
		self.FLAG_C = false
		self.FLAG_N = false
		self.FLAG_H = false
		self.FLAG_Z = val == 0

	// SRL
	case op <= 0x3F:
		self.FLAG_C = (val & (1 << 0)) != 0
		val >>= 1
		self.FLAG_N = false
		self.FLAG_H = false
		self.FLAG_Z = val == 0

	// BIT
	case op <= 0x7F:
		bit = (op & 0b00111000) >> 3
		self.FLAG_Z = (val & (1 << bit)) == 0
		self.FLAG_N = false
		self.FLAG_H = true

	// RES
	case op <= 0xBF:
		bit = (op & 0b00111000) >> 3
		val &= ((1 << bit) ^ 0xFF)

	// SET
	case op <= 0xFF:
		bit = (op & 0b00111000) >> 3
		val |= (1 << bit)

	// Should never get here
	default:
		println("Op CB %02X not implemented\n", op)
		panic("Op not implemented")
	}
	self.set_reg(op, val)
}

func (self *CPU) _xor(val uint8) {
	self.A ^= val

	self.FLAG_Z = self.A == 0
	self.FLAG_N = false
	self.FLAG_H = false
	self.FLAG_C = false

}
func (self *CPU) _or(val uint8) {
	self.A |= val

	self.FLAG_Z = self.A == 0
	self.FLAG_N = false
	self.FLAG_H = false
	self.FLAG_C = false
}
func (self *CPU) _and(val uint8) {
	self.A &= val

	self.FLAG_Z = self.A == 0
	self.FLAG_N = false
	self.FLAG_H = true
	self.FLAG_C = false
}
func (self *CPU) _cp(val uint8) {
	self.FLAG_Z = self.A == val
	self.FLAG_N = true
	self.FLAG_H = (self.A & 0x0F) < (val & 0x0F)
	self.FLAG_C = self.A < val
}
func (self *CPU) _add(val uint8) {
	self.FLAG_C = uint16(self.A)+uint16(val) > 0xFF
	self.FLAG_H = (self.A&0x0F)+(val&0x0F) > 0x0F
	self.FLAG_N = false
	self.A += val
	self.FLAG_Z = self.A == 0
}
func (self *CPU) _adc(val uint8) {
	var carry uint8
	if self.FLAG_C {
		carry = 1
	} else {
		carry = 0
	}
	self.FLAG_C = uint16(self.A)+uint16(val)+uint16(carry) > 0xFF
	self.FLAG_H = (self.A&0x0F)+(val&0x0F)+carry > 0x0F
	self.FLAG_N = false
	self.A += val + carry
	self.FLAG_Z = self.A == 0
}
func (self *CPU) _sub(val uint8) {
	self.FLAG_C = self.A < val
	self.FLAG_H = (self.A & 0x0F) < (val & 0x0F)
	self.A -= val
	self.FLAG_Z = self.A == 0
	self.FLAG_N = true
}
func (self *CPU) _sbc(val uint8) {
	var carry uint8
	if self.FLAG_C {
		carry = 1
	} else {
		carry = 0
	}
	var res int = int(self.A) - int(val) - int(carry)
	self.FLAG_H = ((self.A ^ val ^ (uint8(res) & 0xff)) & (1 << 4)) != 0
	self.FLAG_C = res < 0
	self.A -= val + carry
	self.FLAG_Z = self.A == 0
	self.FLAG_N = true
}

func (self *CPU) push(val uint16) {
	self.ram.set(self.SP-1, uint8(((val&0xFF00)>>8)&0xFF))
	self.ram.set(self.SP-2, uint8(val&0xFF))
	self.SP -= 2
}
func (self *CPU) pop() uint16 {
	var val uint16 = (uint16(self.ram.get(self.SP+1)) << 8) | uint16(self.ram.get(self.SP))
	self.SP += 2
	return val
}

func (self *CPU) get_reg(n uint8) uint8 {
	switch n & 0x07 {
	case 0:
		return self.B
	case 1:
		return self.C
	case 2:
		return self.D
	case 3:
		return self.E
	case 4:
		return uint8(self.HL >> 8)
	case 5:
		return uint8(self.HL & 0xFF)
	case 6:
		return self.ram.get(self.HL)
	case 7:
		return self.A
	default:
		println("Invalid register %d", n)
		return 0
	}
}
func (self *CPU) set_reg(n uint8, val uint8) {
	switch n & 0x07 {
	case 0:
		self.B = val
		break
	case 1:
		self.C = val
		break
	case 2:
		self.D = val
		break
	case 3:
		self.E = val
		break
	case 4:
		_, orig_l := split16(self.HL)
		self.HL = join16(val, orig_l)
		break
	case 5:
		orig_h, _ := split16(self.HL)
		self.HL = join16(orig_h, val)
		break
	case 6:
		self.ram.set(self.HL, val)
		break
	case 7:
		self.A = val
		break
	default:
		println("Invalid register %d", n)
	}
}
