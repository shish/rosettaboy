package main

import (
	"fmt"
	"os"

	"github.com/veandco/go-sdl2/sdl"
)

func main() {
	defer sdl.Quit()

	args := NewArgs()
	gameboy, err := NewGameBoy(args)
	if err == nil {
		err = gameboy.run()
	}
	if err != nil {
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
}
