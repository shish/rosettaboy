const APU = @import("apu.zig").APU;
const Args = @import("args.zig").Args;
const Buttons = @import("buttons.zig").Buttons;
const Cart = @import("cart.zig").Cart;
const Clock = @import("clock.zig").Clock;
const CPU = @import("cpu.zig").CPU;
const GPU = @import("gpu.zig").GPU;
const RAM = @import("ram.zig").RAM;

pub const GameBoy = struct {
    ram: RAM,
    cpu: CPU,
    gpu: GPU,
    apu: APU,
    buttons: Buttons,
    clock: Clock,

    pub fn new(args: Args) !GameBoy {
        // let sdl = sdl2.init().map_err(anyhow.Error.msg)?;

        var cart = try Cart.new(args.rom);
        var ram = try RAM.new(&cart);
        var cpu = try CPU.new(args.debug_cpu);
        var gpu = try GPU.new(cart.name, args.headless, args.debug_gpu);
        var apu = try APU.new(args.silent, args.debug_apu);
        var buttons = try Buttons.new(&cpu, &ram, args.headless);
        var clock = try Clock.new(&buttons, args.profile, args.turbo);

        return GameBoy{
            .ram = ram,
            .cpu = cpu,
            .gpu = gpu,
            .apu = apu,
            .buttons = buttons,
            .clock = clock,
        };
    }

    pub fn run(self: *GameBoy) !void {
        while (true) {
            try self.tick();
        }
    }

    pub fn tick(self: *GameBoy) !void {
        try self.cpu.tick();
        try self.gpu.tick();
        try self.buttons.tick();
        try self.clock.tick();
        try self.apu.tick();
    }
};
