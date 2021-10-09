package main

import "flag"
import "github.com/veandco/go-sdl2/sdl"

func main() {
	var debug_cpu = flag.Bool("debug-cpu", false, "Debug CPU")
	var debug_gpu = flag.Bool("debug-gpu", false, "Debug GPU")
	var debug_apu = flag.Bool("debug-apu", false, "Debug APU")
	var debug_ram = flag.Bool("debug-ram", false, "Debug RAM")
	var headless = flag.Bool("headless", false, "No video")
	var silent = flag.Bool("silent", false, "No audio")
	var turbo = flag.Bool("turbo", false, "No sleep()")
	var fps = flag.Bool("fps", false, "Show FPS on stdout")
	var profile = flag.Int("profile", 0, "Exit after N frames")
	flag.Parse()
	var rom = flag.Arg(0)

	var cart = NewCart(rom)
	var ram = NewRAM(&cart, *debug_ram)
	var cpu = NewCPU(&ram, *debug_cpu)
	/*var apu = */ NewAPU(&cpu, *debug_apu, *silent)
	var gpu = NewGPU(&cpu, *debug_gpu, *headless)
	defer gpu.Destroy()
	var buttons = NewButtons(&cpu, *headless)
	var clock = NewClock(*profile, *turbo, *fps)

	for true {
		if !cpu.tick() {
			break
		}
		if !gpu.tick() {
			break
		}
		if !buttons.tick() {
			break
		}
		if !clock.tick() {
			break
		}
	}

	sdl.Quit()
}
