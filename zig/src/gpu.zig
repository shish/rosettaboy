const std = @import("std");

const CPU = @import("cpu.zig").CPU;
const consts = @import("consts.zig");

const SDL = @import("sdl2");

const SCALE = 2;
const rmask = 0x000000ff;
const gmask = 0x0000ff00;
const bmask = 0x00ff0000;
const amask = 0xff000000;

const LCDC = struct {
    const ENABLED: u8 = 1 << 7;
    const WINDOW_MAP: u8 = 1 << 6;
    const WINDOW_ENABLED: u8 = 1 << 5;
    const DATA_SRC: u8 = 1 << 4;
    const BG_MAP: u8 = 1 << 3;
    const OBJ_SIZE: u8 = 1 << 2;
    const OBJ_ENABLED: u8 = 1 << 1;
    const BG_WIN_ENABLED: u8 = 1 << 0;
};

const Stat = struct {
    const LYC_INTERRUPT: u8 = 1 << 6;
    const OAM_INTERRUPT: u8 = 1 << 5;
    const VBLANK_INTERRUPT: u8 = 1 << 4;
    const HBLANK_INTERRUPT: u8 = 1 << 3;
    const LYC_EQUAL: u8 = 1 << 2;
    const MODE_BITS: u8 = 1 << 1 | 1 << 0;

    const HBLANK: u8 = 0x00;
    const VBLANK: u8 = 0x01;
    const OAM: u8 = 0x02;
    const DRAWING: u8 = 0x03;
};

pub const GPU = struct {
    cpu: *CPU,
    name: []const u8,
    headless: bool,
    debug: bool,
    cycle: u32,

    hw_window: ?*const SDL.Window,
    hw_buffer: ?*const SDL.Texture,
    hw_renderer: ?*const SDL.Renderer,
    buffer: *SDL.Surface,
    renderer: *const SDL.Renderer,
    colors: [4]SDL.Color,
    bgp: [4]SDL.Color,
    obp0: [4]SDL.Color,
    obp1: [4]SDL.Color,

    pub fn new(cpu: *CPU, name: []const u8, headless: bool, debug: bool) !GPU {
        // Window
        var w: i32 = 160;
        var h: i32 = 144;
        if (debug) {
            w = 160 + 256;
            h = 144;
        }

        var hw_window: ?*const SDL.Window = null;
        var hw_renderer: ?*const SDL.Renderer = null;
        var hw_buffer: ?*const SDL.Texture = null;
        if (!headless) {
            var _hw_window = try SDL.createWindow(
                "RosettaBoy - ??",
                .{ .centered = {} },
                .{ .centered = {} },
                @intCast(usize, w * SCALE),
                @intCast(usize, h * SCALE),
                .{ .vis = .shown }, // FIXME: SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE
            );
            var _hw_renderer = try SDL.createRenderer(_hw_window, null, .{ .accelerated = true });
            // FIXME
            // SDL.setHint(SDL.HINT_RENDER_SCALE_QUALITY, "nearest"); // vs "linear"
            try _hw_renderer.setLogicalSize(w, h);
            var _hw_buffer = try SDL.createTexture(_hw_renderer, SDL.PixelFormatEnum.abgr8888, SDL.Texture.Access.streaming, @intCast(usize, w), @intCast(usize, h));

            hw_window = &_hw_window;
            hw_renderer = &_hw_renderer;
            hw_buffer = &_hw_buffer;
        }
        var buffer = try SDL.createRgbSurfaceWithFormat(@intCast(u31, w), @intCast(u31, h), SDL.PixelFormatEnum.abgr8888);
        std.debug.print("buf {any}\n", .{buffer});
        var renderer = try SDL.createSoftwareRenderer(buffer);
        std.debug.print("ren {any}\n", .{renderer});

        // Colors
        var colors: [4]SDL.Color = .{
            SDL.Color{ .r = 0x9B, .g = 0xBC, .b = 0x0F, .a = 0xFF },
            SDL.Color{ .r = 0x8B, .g = 0xAC, .b = 0x0F, .a = 0xFF },
            SDL.Color{ .r = 0x30, .g = 0x62, .b = 0x30, .a = 0xFF },
            SDL.Color{ .r = 0x0F, .g = 0x38, .b = 0x0F, .a = 0xFF },
        };

        return GPU{
            // FIXME
            .cpu = cpu,
            .name = name,
            .headless = headless,
            .debug = debug,
            .cycle = 0,
            .hw_window = hw_window,
            .hw_buffer = hw_buffer,
            .hw_renderer = hw_renderer,
            .buffer = &buffer,
            .renderer = &renderer,
            .colors = colors,
            .bgp = colors,
            .obp0 = colors,
            .obp1 = colors,
        };
    }

    pub fn tick(self: *GPU) !void {
        self.cycle += 1;

        // CPU STOP stops all LCD activity until a button is pressed
        if (self.cpu.stop) {
            return;
        }

        // Check if LCD enabled at all
        var lcdc = self.cpu.ram.get(consts.Mem.LCDC);
        if ((lcdc & LCDC.ENABLED) == 0) {
            // When LCD is re-enabled, LY is 0
            // Does it become 0 as soon as disabled??
            self.cpu.ram.set(consts.Mem.LY, 0);
            if (!self.debug) {
                return;
            }
        }

        var lx: u8 = @intCast(u8, self.cycle % 114);
        var ly: u8 = @intCast(u8, (self.cycle / 114) % 154);
        self.cpu.ram.set(consts.Mem.LY, ly);

        // LYC compare & interrupt
        if (self.cpu.ram.get(consts.Mem.LY) == self.cpu.ram.get(consts.Mem.LYC)) {
            if (self.cpu.ram.get(consts.Mem.STAT) & Stat.LYC_INTERRUPT != 0) {
                self.cpu.interrupt(consts.Interrupt.STAT);
            }
            self.cpu.ram._or(consts.Mem.STAT, Stat.LYC_EQUAL);
        } else {
            self.cpu.ram._and(consts.Mem.STAT, ~Stat.LYC_EQUAL);
        }

        // Set mode
        if (lx == 0 and ly < 144) {
            self.cpu.ram.set(consts.Mem.STAT, (self.cpu.ram.get(consts.Mem.STAT) & ~Stat.MODE_BITS) | Stat.OAM);
            if (self.cpu.ram.get(consts.Mem.STAT) & Stat.OAM_INTERRUPT != 0) {
                self.cpu.interrupt(consts.Interrupt.STAT);
            }
        } else if (lx == 20 and ly < 144) {
            self.cpu.ram.set(consts.Mem.STAT, (self.cpu.ram.get(consts.Mem.STAT) & ~Stat.MODE_BITS) | Stat.DRAWING);
            if (ly == 0) {
                // TODO: how often should we update palettes?
                // Should every pixel reference them directly?
        //std.debug.print("ren2 {any}\n", .{self.renderer});
                self.update_palettes();
                try self.renderer.setColor(self.bgp[0]);
                try self.renderer.clear();
            }
            try self.draw_line(ly);
            if (ly == 143) {
                if (self.debug) {
                    try self.draw_debug();
                }
                if (self.hw_renderer) |hw_renderer| {
                    if (self.hw_buffer) |hw_buffer| {
                        var tex = try SDL.createTextureFromSurface(self.renderer.*, self.buffer.*);
                        var pixelData = try tex.lock(null);
                        try hw_buffer.update(pixelData.pixels[0..10], pixelData.stride, null);
                        try hw_renderer.clear();
                        try hw_renderer.copy(hw_buffer.*, null, null);
                        hw_renderer.present();
                    }
                }
            }
        } else if (lx == 63 and ly < 144) {
            self.cpu.ram.set(consts.Mem.STAT, (self.cpu.ram.get(consts.Mem.STAT) & ~Stat.MODE_BITS) | Stat.HBLANK);
            if (self.cpu.ram.get(consts.Mem.STAT) & Stat.HBLANK_INTERRUPT != 0) {
                self.cpu.interrupt(consts.Interrupt.STAT);
            }
        } else if (lx == 0 and ly == 144) {
            self.cpu.ram.set(consts.Mem.STAT, (self.cpu.ram.get(consts.Mem.STAT) & ~Stat.MODE_BITS) | Stat.VBLANK);
            if (self.cpu.ram.get(consts.Mem.STAT) & Stat.VBLANK_INTERRUPT != 0) {
                self.cpu.interrupt(consts.Interrupt.STAT);
            }
            self.cpu.interrupt(consts.Interrupt.VBLANK);
        }
    }

    fn update_palettes(self: *GPU) void {
        var raw_bgp = self.cpu.ram.get(consts.Mem.BGP);
        self.bgp[0] = self.colors[(raw_bgp >> 0) & 0x3];
        self.bgp[1] = self.colors[(raw_bgp >> 2) & 0x3];
        self.bgp[2] = self.colors[(raw_bgp >> 4) & 0x3];
        self.bgp[3] = self.colors[(raw_bgp >> 6) & 0x3];

        var raw_obp0 = self.cpu.ram.get(consts.Mem.OBP0);
        self.obp0[0] = self.colors[(raw_obp0 >> 0) & 0x3];
        self.obp0[1] = self.colors[(raw_obp0 >> 2) & 0x3];
        self.obp0[2] = self.colors[(raw_obp0 >> 4) & 0x3];
        self.obp0[3] = self.colors[(raw_obp0 >> 6) & 0x3];

        var raw_obp1 = self.cpu.ram.get(consts.Mem.OBP1);
        self.obp1[0] = self.colors[(raw_obp1 >> 0) & 0x3];
        self.obp1[1] = self.colors[(raw_obp1 >> 2) & 0x3];
        self.obp1[2] = self.colors[(raw_obp1 >> 4) & 0x3];
        self.obp1[3] = self.colors[(raw_obp1 >> 6) & 0x3];
    }

    fn draw_debug(self: *GPU) !void {
        var lcdc = self.cpu.ram.get(consts.Mem.LCDC);

        // Tile data - FIXME
        // var tile_display_width: u8 = 32;
        // for(int tile_id = 0; tile_id < 384; tile_id++) {
        //     SDL_Point xy = {
        //         .x = 160 + (tile_id % tile_display_width) * 8,
        //         .y = (tile_id / tile_display_width) * 8,
        //     };
        //     self.paint_tile(tile_id, &xy, self.bgp, false, false);
        // }

        // Background scroll border
        if (lcdc & LCDC.BG_WIN_ENABLED != 0) {
            var rect = SDL.Rectangle{ .x = 0, .y = 0, .width = 160, .height = 144 };
            try self.renderer.setColorRGB(255, 0, 0);
            try self.renderer.drawRect(rect);
        }

        // Window tiles
        if (lcdc & LCDC.WINDOW_ENABLED != 0) {
            var wnd_y = self.cpu.ram.get(consts.Mem.WY);
            var wnd_x = self.cpu.ram.get(consts.Mem.WX);
            var rect = SDL.Rectangle{ .x = wnd_x - 7, .y = wnd_y, .width = 160, .height = 144 };
            try self.renderer.setColorRGB(0, 0, 255);
            try self.renderer.drawRect(rect);
        }
    }

    fn draw_line(self: *GPU, ly: u16) !void {
        var lcdc = self.cpu.ram.get(consts.Mem.LCDC);

        // Background tiles
        if (lcdc & LCDC.BG_WIN_ENABLED != 0) {
            var scroll_y = self.cpu.ram.get(consts.Mem.SCY);
            var scroll_x = self.cpu.ram.get(consts.Mem.SCX);
            var tile_offset = !(lcdc & LCDC.DATA_SRC != 0);
            var tile_map = if (lcdc & LCDC.BG_MAP != 0) consts.Mem.Map1 else consts.Mem.Map0;

            if (self.debug) {
                var xy = SDL.Point{ .x = 256 - @intCast(i16, scroll_x), .y = @intCast(c_int, ly) };
                try self.renderer.setColorRGB(255, 0, 0);
                try self.renderer.drawPoint(xy.x, xy.y);
            }

            var y_in_bgmap = (ly + scroll_y) % 256;
            var tile_y = y_in_bgmap / 8;
            var tile_sub_y: u3 = @intCast(u3, y_in_bgmap % 8);

            var lx: u16 = 0;
            while (lx <= 160) {
                var x_in_bgmap = (lx + scroll_x) % 256;
                var tile_x = x_in_bgmap / 8;
                var tile_sub_x = x_in_bgmap % 8;

                var tile_id: i16 = self.cpu.ram.get(tile_map + tile_y * 32 + tile_x);
                if (tile_offset and tile_id < 0x80) {
                    tile_id += 0x100;
                }
                var xy = SDL.Point{
                    .x = lx - tile_sub_x,
                    .y = ly - tile_sub_y,
                };
                try self.paint_tile_line(tile_id, &xy, self.bgp, false, false, tile_sub_y);

                lx += 8;
            }
        }

        // Window tiles
        if (lcdc & LCDC.WINDOW_ENABLED != 0) {
            var wnd_y = self.cpu.ram.get(consts.Mem.WY);
            var wnd_x = self.cpu.ram.get(consts.Mem.WX);
            var tile_offset = !(lcdc & LCDC.DATA_SRC != 0);
            var tile_map = if (lcdc & LCDC.WINDOW_MAP != 0) consts.Mem.Map1 else consts.Mem.Map0;

            // blank out the background
            var rect = SDL.Rectangle{
                .x = wnd_x - 7,
                .y = wnd_y,
                .width = 160,
                .height = 144,
            };
            try self.renderer.setColor(self.bgp[0]);
            try self.renderer.fillRect(rect);

            var y_in_bgmap = ly - wnd_y;
            var tile_y = y_in_bgmap / 8;
            var tile_sub_y: u3 = @intCast(u3, y_in_bgmap % 8);

            var tile_x: u8 = 0;
            while (tile_x < 20) {
                var tile_id: i16 = self.cpu.ram.get(tile_map + tile_y * 32 + tile_x);
                if (tile_offset and tile_id < 0x80) {
                    tile_id += 0x100;
                }
                var xy = SDL.Point{
                    .x = tile_x * 8 + wnd_x - 7,
                    .y = tile_y * 8 + wnd_y,
                };
                try self.paint_tile_line(tile_id, &xy, self.bgp, false, false, tile_sub_y);
                tile_x += 1;
            }
        }

        // Sprites
        if (lcdc & LCDC.OBJ_ENABLED != 0) {
            var dbl = lcdc & LCDC.OBJ_SIZE != 0;

            // TODO: sorted by x
            // var sprites: [Sprite; 40] = [];
            // memcpy(sprites, &ram.data[OamBase], 40 * sizeof(Sprite));
            // for sprite in sprites.iter() {
            var n: u8 = 0;
            while (n < 40) {
                var sprite = Sprite{
                    .y = self.cpu.ram.get(consts.Mem.OamBase + 4 * n + 0),
                    .x = self.cpu.ram.get(consts.Mem.OamBase + 4 * n + 1),
                    .tile_id = self.cpu.ram.get(consts.Mem.OamBase + 4 * n + 2),
                    .flags = .{ .byte = self.cpu.ram.get(consts.Mem.OamBase + 4 * n + 3) },
                };

                if (sprite.is_live()) {
                    var palette = if (sprite.flags.bits.palette) self.obp1 else self.obp0;
                    // printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OamBase + (sprite_id * 4) + 0, x, y);
                    var xy = SDL.Point{
                        .x = sprite.x - 8,
                        .y = sprite.y - 16,
                    };
                    try self.paint_tile(sprite.tile_id, &xy, palette, sprite.flags.bits.x_flip, sprite.flags.bits.y_flip);

                    if (dbl) {
                        xy.y = sprite.y - 8;
                        try self.paint_tile(sprite.tile_id + 1, &xy, palette, sprite.flags.bits.x_flip, sprite.flags.bits.y_flip);
                    }
                }

                n += 1;
            }
        }
    }

    fn paint_tile(self: *GPU, tile_id: i16, offset: *SDL.Point, palette: [4]SDL.Color, flip_x: bool, flip_y: bool) !void {
        var y: u3 = 0;
        while (y < 8) {
            try self.paint_tile_line(tile_id, offset, palette, flip_x, flip_y, y);
            y += 1;
        }

        if (self.debug) {
            var rect = SDL.Rectangle{
                .x = offset.x,
                .y = offset.y,
                .width = 8,
                .height = 8,
            };
            try self.renderer.setColor(gen_hue(@intCast(u8, tile_id & 0xFF)));
            try self.renderer.drawRect(rect);
        }
    }

    fn paint_tile_line(
        self: *GPU,
        tile_id: i16,
        offset: *SDL.Point,
        palette: [4]SDL.Color,
        flip_x: bool,
        flip_y: bool,
        y: u3,
    ) !void {
        var addr: u16 = @intCast(u16, @intCast(i32, consts.Mem.TileData) + tile_id * 16 + @intCast(u8, y) * 2);
        var low_byte = self.cpu.ram.get(addr);
        var high_byte = self.cpu.ram.get(addr + 1);
        var x: u3 = 0;
        while (true) {
            var low_bit = (low_byte >> (7 - x)) & 0x01;
            var high_bit = (high_byte >> (7 - x)) & 0x01;
            var px = (high_bit << 1) | low_bit;
            // pallette #0 = transparent, so don't draw anything
            if (px > 0) {
                var xy = SDL.Point{
                    .x = offset.x + (if (flip_x) 7 - x else x),
                    .y = offset.y + (if (flip_y) 7 - y else y),
                };
                try self.renderer.setColor(palette[px]);
                try self.renderer.drawPoint(xy.x, xy.y);
            }
            x += 1;
            if (x == 7) break;
        }
    }
};

pub const Sprite = packed struct {
    y: u8,
    x: u8,
    tile_id: u8,
    flags: packed union {
        byte: u8,
        bits: packed struct {
            _empty: u4,
            palette: bool,
            x_flip: bool,
            y_flip: bool,
            behind: bool,
        },
    },

    fn is_live(self: *Sprite) bool {
        return self.x > 0 and self.x < 168 and self.y > 0 and self.y < 160;
    }
};

pub fn gen_hue(n: u8) SDL.Color {
    var region: u8 = n / 43;
    var remainder: u8 = (n - (region * 43)) * 6;

    var q: u8 = 255 - remainder;
    var t: u8 = remainder;

    return switch (region) {
        0 => SDL.Color{ .r = 255, .g = t, .b = 0, .a = 0xFF },
        1 => SDL.Color{ .r = q, .g = 255, .b = 0, .a = 0xFF },
        2 => SDL.Color{ .r = 0, .g = 255, .b = t, .a = 0xFF },
        3 => SDL.Color{ .r = 0, .g = q, .b = 255, .a = 0xFF },
        4 => SDL.Color{ .r = t, .g = 0, .b = 255, .a = 0xFF },
        else => SDL.Color{ .r = 255, .g = 0, .b = q, .a = 0xFF },
    };
}
