for offset, op in enumerate(["RLC", "RRC", "RL", "RR", "SLA", "SRA", "SWAP", "SRL"]):
	for code, arg in enumerate(["B", "C", "D", "E", "H", "L", "(HL)", "A"]):
		opcode = (offset * 8) + code
		time = 16 if arg == "MEM_AT_HL" else 8
		print("opCB%02X = opcode(\"%s %s\", %d)(lambda self: self._%s(Reg.%s))" % (opcode, op, arg, time, op.lower(), arg.replace("(HL)", "MEM_AT_HL")))

for offset, op in enumerate(["BIT", "RES", "SET"]):
	for b in range(8):
		for code, arg in enumerate(["B", "C", "D", "E", "H", "L", "(HL)", "A"]):
			opcode = 0x40 + (offset * 0x40) + b * 0x08 + code
			time = 16 if arg == "MEM_AT_HL" else 8
			print("opCB%02X = opcode(\"%s %d %s\", %d)(lambda self: self._%s(Reg.%s, %d))" % (opcode, op, b, arg, time, op.lower(), arg.replace("(HL)", "MEM_AT_HL"), b))
