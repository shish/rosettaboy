package main

import "flag"
import "runtime"
import "fmt"
import "os"

type Args struct {
	DebugCpu bool
	DebugApu bool
	DebugGpu bool
	DebugRam bool
	Headless bool
	Silent   bool
	Turbo    bool
	Frames   int
	Profile  int
	Rom      string
}

func NewArgs() *Args {
	var debug_cpu = flag.Bool("debug-cpu", false, "Debug CPU")
	var debug_gpu = flag.Bool("debug-gpu", false, "Debug GPU")
	var debug_apu = flag.Bool("debug-apu", false, "Debug APU")
	var debug_ram = flag.Bool("debug-ram", false, "Debug RAM")
	var headless = flag.Bool("headless", false, "No video")
	var silent = flag.Bool("silent", false, "No audio")
	var turbo = flag.Bool("turbo", false, "No sleep()")
	var frames = flag.Int("frames", 0, "Exit after N frames")
	var profile = flag.Int("profile", 0, "Exit after N seconds")
	var version = flag.Bool("version", false, "Show build info")
	flag.Parse()
	if *version {
		fmt.Println(runtime.Version())
		os.Exit(0)
	}
	var rom = flag.Arg(0)

	return &Args{
		DebugCpu: *debug_cpu,
		DebugGpu: *debug_gpu,
		DebugApu: *debug_apu,
		DebugRam: *debug_ram,
		Headless: *headless,
		Silent:   *silent,
		Turbo:    *turbo,
		Frames:   *frames,
		Profile:  *profile,
		Rom:      rom,
	}
}
