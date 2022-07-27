package main

import "fmt"

type EmuError struct {
	// TODO: can this not have a default value?
	ExitCode int
}

func (e *EmuError) Error() string {
	return "EmuError"
}

type Quit struct {
	EmuError // ExitCode = 0
}

func (e *Quit) Error() string {
	return "Quit"
}

type Timeout struct {
	EmuError
	Frames   int
	Duration float32
}

func (e *Timeout) Error() string {
	return fmt.Sprintf("Emulated %d frames in %.2fs (%.2ffps)", e.Frames,
		e.Duration,
		float32(e.Frames)/e.Duration,
	)
}

type CpuHalted struct {
	EmuError // ExitCode = 0
}

func (e *CpuHalted) Error() string {
	return "CPU Halted"
}

type UnsupportedCart struct {
	EmuError // ExitCode = 1
	CartType int
}

func (e *UnsupportedCart) Error() string {
	return fmt.Sprintf("Unsupported cart type %d", e.CartType)
}

type LogoChecksumFailed struct {
	EmuError     // ExitCode = 1
	LogoChecksum int
}

func (e *LogoChecksumFailed) Error() string {
	return fmt.Sprintf("Logo checksum failed %d", e.LogoChecksum)
}

type HeaderChecksumFailed struct {
	EmuError       // ExitCode = 1
	HeaderChecksum int
}

func (e *HeaderChecksumFailed) Error() string {
	return fmt.Sprintf("Header checksum failed %d", e.HeaderChecksum)
}

type UnitTestPassed struct {
	EmuError // ExitCode = 0
}

func (e *UnitTestPassed) Error() string {
	return "Unit test passed"
}

type UnitTestFailed struct {
	EmuError // ExitCode = 2
}

func (e *UnitTestFailed) Error() string {
	return "Unit test failed"
}

type InvalidOpcode struct {
	EmuError // ExitCode = 1
	OpCode   uint8
}

func (e *InvalidOpcode) Error() string {
	return fmt.Sprintf("Invalid opcode: %02X", e.OpCode)
}
