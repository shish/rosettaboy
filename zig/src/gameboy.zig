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
    cart: Cart,

    pub fn init(gb: *GameBoy, args: Args) !void {
        gb.cart = try Cart.new(args.rom);
        gb.ram = try RAM.new(&gb.cart);
        gb.cpu = try CPU.new(&gb.ram, args.debug_cpu);
        gb.gpu = try GPU.new(&gb.cpu, gb.cart.name, args.headless, args.debug_gpu);
        gb.apu = try APU.new(args.silent, args.debug_apu);
        gb.buttons = try Buttons.new(&gb.cpu, &gb.ram, args.headless);
        gb.clock = try Clock.new(&gb.buttons, args.profile, args.turbo);
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
