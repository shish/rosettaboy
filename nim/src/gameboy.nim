import args
import cart
import ram
import cpu
import gpu
import apu
import buttons
import clock

type
    GameBoy* = object
        ram: ram.RAM
        cpu: cpu.CPU
        gpu: gpu.GPU
        apu: apu.APU
        buttons: buttons.Buttons
        clock: clock.Clock

proc create*(args: args.Args): GameBoy =
    let cart = cart.create(args.rom)
    let ram = ram.create(cart)
    let cpu = cpu.create(ram, args.debugCpu);
    let gpu = gpu.create(cpu, ram, cart.name, args.headless, args.debugGpu)
    let apu = apu.create(args.silent, args.debugApu)
    let buttons = buttons.create(cpu, ram, args.headless)
    let clock = clock.create(buttons, args.frames, args.profile, args.turbo)
    return GameBoy(
        ram: ram,
        cpu: cpu,
        gpu: gpu,
        apu: apu,
        buttons: buttons,
        clock: clock,
    )

proc tick*(gb: var GameBoy) =
    gb.cpu.tick()
    gb.gpu.tick()
    gb.buttons.tick()
    gb.clock.tick()
    gb.apu.tick()

proc run*(gb: var GameBoy) =
    while true:
        gb.tick()
