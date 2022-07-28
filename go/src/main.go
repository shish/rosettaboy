package main

import (
	"fmt"
	"log"
	"os"

	"github.com/veandco/go-sdl2/sdl"
)

func main() {
	defer sdl.Quit()

	args := NewArgs()

	cart, err := NewCart(args.Rom)
	if err != nil {
		log.Fatalln(err)
	}
	ram := NewRAM(cart, args.DebugRam)
	cpu := NewCPU(&ram, args.DebugCpu)
	_, err = NewAPU(&cpu, args.DebugApu, args.Silent)
	if err != nil {
		log.Fatalln(err)
	}
	gpu, err := NewGPU(&cpu, cart.name, args.DebugGpu, args.Headless)
	if err != nil {
		log.Fatalln(err)
	}
	defer gpu.Destroy()
	buttons, err := NewButtons(&cpu, args.Headless)
	if err != nil {
		log.Fatalln(err)
	}
	clock, err := NewClock(buttons, args.Profile, args.Turbo)
	if err != nil {
		log.Fatalln(err)
	}
	apu, err := NewAPU(&cpu, args.DebugApu, args.Silent)
	if err != nil {
		log.Fatalln(err)
	}

	for {
		err := cpu.tick()
		if err != nil {
			handle_error(err)
		}

		gpu.tick()

		err = buttons.tick()
		if err != nil {
			handle_error(err)
		}

		err = clock.tick()
		if err != nil {
			handle_error(err)
		}

		apu.tick()
	}
}

func handle_error(err error) {
	// ... really? Surely there must be a better way :|
	switch e := err.(type) {
    case *EmuError:
		fmt.Println(e)
		os.Exit(e.ExitCode)
    case *Timeout:
		fmt.Println(e)
		os.Exit(e.ExitCode)
    case *UnitTestPassed:
		fmt.Println(e)
		os.Exit(e.ExitCode)
    case *UnitTestFailed:
		fmt.Println(e)
		os.Exit(e.ExitCode)
    default:
        fmt.Println(e)
		os.Exit(1)
    }
}