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
		case *Quit:
			fmt.Println(e)
			os.Exit(0)
		case *Timeout:
			fmt.Println(e)
			os.Exit(0)
		case *UnitTestPassed:
			fmt.Println(e)
			os.Exit(0)
		case *UnitTestFailed:
			fmt.Println(e)
			os.Exit(2)
		default:
			fmt.Println(e)
			os.Exit(1)
		}
	}
}
