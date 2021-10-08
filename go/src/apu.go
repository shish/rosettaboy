package main

type APU struct {
	debug  bool
	cpu    CPU
	silent bool
}

func NewAPU(cpu CPU, debug bool, silent bool) APU {
	return APU{debug, cpu, silent}
}
