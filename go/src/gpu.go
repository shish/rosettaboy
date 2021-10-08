package main

type GPU struct {
	debug    bool
	cpu      CPU
	headless bool
}

func NewGPU(cpu CPU, debug bool, headless bool) GPU {
	return GPU{debug, cpu, headless}
}

func (self GPU) tick() bool {
	return true
}
