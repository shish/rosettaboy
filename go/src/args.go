package main

import flag "github.com/spf13/pflag"
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
	var debug_cpu = flag.BoolP("debug-cpu", "c", false, "Debug CPU")
	var debug_gpu = flag.BoolP("debug-gpu", "g", false, "Debug GPU")
	var debug_apu = flag.BoolP("debug-apu", "a", false, "Debug APU")
	var debug_ram = flag.BoolP("debug-ram", "r", false, "Debug RAM")
	var headless = flag.BoolP("headless", "H", false, "No video")
	var silent = flag.BoolP("silent", "S", false, "No audio")
	var turbo = flag.BoolP("turbo", "t", false, "No sleep()")
	var frames = flag.IntP("frames", "f", 0, "Exit after N frames")
	var profile = flag.IntP("profile", "p", 0, "Exit after N seconds")
	var version = flag.BoolP("version", "v", false, "Show build info")
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
