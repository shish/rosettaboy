package main

import "fmt"

// Controlled Exits
type Quit struct {
}

func (e *Quit) Error() string {
	return "Quit"
}

type Timeout struct {
	Frames   int
	Duration float32
}

func (e *Timeout) Error() string {
	return fmt.Sprintf("Emulated %d frames in %5.2fs (%.0ffps)", e.Frames,
		e.Duration,
		float32(e.Frames)/e.Duration,
	)
}

type UnitTestPassed struct {
}

func (e *UnitTestPassed) Error() string {
	return "Unit test passed"
}

type UnitTestFailed struct {
}

func (e *UnitTestFailed) Error() string {
	return "Unit test failed"
}

// Game Errors
type InvalidOpcode struct {
	OpCode uint8
}

func (e *InvalidOpcode) Error() string {
	return fmt.Sprintf("Invalid opcode: %02X", e.OpCode)
}

// User Errors
type UnsupportedCart struct {
	CartType int
}

func (e *UnsupportedCart) Error() string {
	return fmt.Sprintf("Unsupported cart type %d", e.CartType)
}

type LogoChecksumFailed struct {
	LogoChecksum int
}

func (e *LogoChecksumFailed) Error() string {
	return fmt.Sprintf("Logo checksum failed %d", e.LogoChecksum)
}

type HeaderChecksumFailed struct {
	HeaderChecksum int
}

func (e *HeaderChecksumFailed) Error() string {
	return fmt.Sprintf("Header checksum failed %d", e.HeaderChecksum)
}
