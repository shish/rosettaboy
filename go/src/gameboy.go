package main

type GameBoy struct {
	cart    *Cart
	ram     *RAM
	cpu     *CPU
	gpu     *GPU
	buttons *Buttons
	apu     *APU
	clock   *Clock
}

func NewGameBoy(args *Args) (*GameBoy, error) {
	cart, err := NewCart(args.Rom)
	if err != nil {
		return nil, err
	}
	ram := NewRAM(cart, args.DebugRam)
	cpu := NewCPU(&ram, args.DebugCpu)
	_, err = NewAPU(&cpu, args.DebugApu, args.Silent)
	if err != nil {
		return nil, err
	}
	gpu, err := NewGPU(&cpu, cart.name, args.DebugGpu, args.Headless)
	if err != nil {
		return nil, err
	}
	buttons, err := NewButtons(&cpu, args.Headless)
	if err != nil {
		return nil, err
	}
	clock, err := NewClock(buttons, args.Frames, args.Profile, args.Turbo)
	if err != nil {
		return nil, err
	}
	apu, err := NewAPU(&cpu, args.DebugApu, args.Silent)
	if err != nil {
		return nil, err
	}

	return &GameBoy{
		cart:    cart,
		ram:     &ram,
		cpu:     &cpu,
		gpu:     gpu,
		buttons: buttons,
		apu:     apu,
		clock:   clock,
	}, nil
}

func (gameboy *GameBoy) run() error {
	for {
		err := gameboy.tick()
		if err != nil {
			return err
		}
	}
}

func (gameboy *GameBoy) tick() error {
	err := gameboy.cpu.tick()
	if err != nil {
		return err
	}

	gameboy.gpu.tick()

	err = gameboy.buttons.tick()
	if err != nil {
		return err
	}

	err = gameboy.clock.tick()
	if err != nil {
		return err
	}

	gameboy.apu.tick()

	return nil
}
