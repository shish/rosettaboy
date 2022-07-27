package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/veandco/go-sdl2/sdl"
)

func main() {
	defer sdl.Quit()

	var debug_cpu = flag.Bool("debug-cpu", false, "Debug CPU")
	var debug_gpu = flag.Bool("debug-gpu", false, "Debug GPU")
	var debug_apu = flag.Bool("debug-apu", false, "Debug APU")
	var debug_ram = flag.Bool("debug-ram", false, "Debug RAM")
	var headless = flag.Bool("headless", false, "No video")
	var silent = flag.Bool("silent", false, "No audio")
	var turbo = flag.Bool("turbo", false, "No sleep()")
	var profile = flag.Int("profile", 0, "Exit after N frames")
	flag.Parse()
	var rom = flag.Arg(0)

	cart, err := NewCart(rom)
	if err != nil {
		log.Fatalln(err)
	}
	ram := NewRAM(cart, *debug_ram)
	cpu := NewCPU(&ram, *debug_cpu)
	_, err = NewAPU(&cpu, *debug_apu, *silent)
	if err != nil {
		log.Fatalln(err)
	}
	gpu, err := NewGPU(&cpu, cart.name, *debug_gpu, *headless)
	if err != nil {
		log.Fatalln(err)
	}
	defer gpu.Destroy()
	buttons, err := NewButtons(&cpu, *headless)
	if err != nil {
		log.Fatalln(err)
	}
	clock, err := NewClock(buttons, *profile, *turbo)
	if err != nil {
		log.Fatalln(err)
	}
	apu, err := NewAPU(&cpu, *debug_apu, *silent)
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