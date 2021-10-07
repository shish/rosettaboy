extern crate sdl2;
use crate::consts::*;
use crate::cpu;
use crate::ram;
use anyhow::Result;

use sdl2::pixels::Color;
use sdl2::rect::{Point, Rect};

//const WIDTH: u16 = 256;
//const HEIGHT: u8 = 240;
const SCALE: u32 = 2;
const RED: Color = Color {
    r: 0x64,
    g: 0x00,
    b: 0x00,
    a: 0xFF,
};
const _GREEN: Color = Color {
    r: 0x00,
    g: 0x64,
    b: 0x00,
    a: 0xFF,
};
const BLUE: Color = Color {
    r: 0x00,
    g: 0x00,
    b: 0x64,
    a: 0xFF,
};

bitflags! {
    pub struct SpriteFlags: u8 {
        const PALETTE = 1<<4;
        const FLIP_X = 1<<5;
        const FLIP_Y = 1<<6;
        const BEHIND = 1<<7;
    }
}

struct Sprite {
    y: u8,
    x: u8,
    tile_id: u8,
    flags: SpriteFlags,
}

impl Sprite {
    fn is_live(&self) -> bool {
        self.x > 0 && self.x < 168 && self.y > 0 && self.y < 160
    }
}

pub struct GPU {
    canvas: Option<sdl2::render::Canvas<sdl2::video::Window>>,
    cycle: u32,
    colors: [Color; 4],
    bgp: [Color; 4],
    obp0: [Color; 4],
    obp1: [Color; 4],
    debug: bool,
}

impl GPU {
    pub fn init(sdl: &sdl2::Sdl, title: &str, headless: bool, debug: bool) -> Result<GPU> {
        let (w, h) = if debug { (160 + 256, 144) } else { (160, 144) };
        let canvas = if !headless {
            let video_subsystem = sdl.video().map_err(anyhow::Error::msg)?;
            let window = video_subsystem
                .window(&format!("RosettaBoy - {}", title)[..], w * SCALE, h * SCALE)
                .position_centered()
                .build()
                .map_err(anyhow::Error::msg)?;
            let mut canvas = window
                .into_canvas()
                .software()
                .build()
                .map_err(anyhow::Error::msg)?;
            canvas
                .set_scale(SCALE as f32, SCALE as f32)
                .map_err(anyhow::Error::msg)?;
            Some(canvas)
        } else {
            None
        };

        let colors = [
            Color::RGBA(0x9B, 0xBC, 0x0F, 0xFF),
            Color::RGBA(0x8B, 0xAC, 0x0F, 0xFF),
            Color::RGBA(0x30, 0x62, 0x30, 0xFF),
            Color::RGBA(0x0F, 0x38, 0x0F, 0xFF),
        ];
        let bgp = [colors[0], colors[1], colors[2], colors[3]];
        let obp0 = [colors[0], colors[1], colors[2], colors[3]];
        let obp1 = [colors[0], colors[1], colors[2], colors[3]];
        Ok(GPU {
            canvas,
            cycle: 0,
            colors,
            bgp,
            obp0,
            obp1,
            debug,
        })
    }

    pub fn tick(&mut self, ram: &mut ram::RAM, cpu: &mut cpu::CPU) -> Result<()> {
        self.cycle += 1;

        // CPU STOP stops all LCD activity until a button is pressed
        if cpu.stop {
            return Ok(());
        }

        // Check if LCD enabled at all
        let lcdc = LCDC::from_bits(ram.get(IO::LCDC)).unwrap();
        if !lcdc.contains(LCDC::ENABLED) {
            // When LCD is re-enabled, LY is 0
            // Does it become 0 as soon as disabled??
            ram.set(IO::LY, 0);
            if !self.debug {
                return Ok(());
            }
        }

        let lx = self.cycle % 114;
        let ly = (self.cycle / 114) % 154;
        ram.set(IO::LY, ly as u8);

        let stat = Stat::from_bits(ram.get(IO::STAT)).unwrap();

        // LYC compare & interrupt
        if ram.get(IO::LY) == ram.get(IO::LYC) {
            if stat.contains(Stat::LCY_INTERRUPT) {
                cpu.interrupt(ram, Interrupt::STAT);
            }
            ram._or(IO::STAT, Stat::LCY_EQUAL.bits());
        } else {
            ram._and(IO::STAT, !Stat::LCY_EQUAL.bits());
        }

        // Set `ram[STAT].bit{0,1}` to `OAM / Drawing / HBlank / VBlank`
        if lx == 0 && ly < 144 {
            ram.set(IO::STAT, ((stat & !Stat::MODE_BITS) | Stat::OAM).bits());
            if stat.contains(Stat::OAM_INTERRUPT) {
                cpu.interrupt(ram, Interrupt::STAT);
            }
        } else if lx == 20 && ly < 144 {
            ram.set(IO::STAT, ((stat & !Stat::MODE_BITS) | Stat::DRAWING).bits());
            if ly == 0 {
                // TODO: how often should we update palettes?
                // Should every pixel reference them directly?
                self.update_palettes(ram);
                // TODO: do we need to clear if we write every pixel?
                if let Some(canvas) = &mut self.canvas {
                    canvas.set_draw_color(self.bgp[0]);
                    canvas.clear();
                }
            }
            self.draw_line(ram, ly as i32);
            if ly == 143 {
                if self.debug {
                    self.draw_debug(ram)?;
                }
                if let Some(canvas) = &mut self.canvas {
                    canvas.present();
                }
            }
        } else if lx == 63 && ly < 144 {
            ram.set(IO::STAT, ((stat & !Stat::MODE_BITS) | Stat::HBLANK).bits());
            if stat.contains(Stat::HBLANK_INTERRUPT) {
                cpu.interrupt(ram, Interrupt::STAT);
            }
        } else if lx == 0 && ly == 144 {
            ram.set(IO::STAT, ((stat & !Stat::MODE_BITS) | Stat::VBLANK).bits());
            if stat.contains(Stat::VBLANK_INTERRUPT) {
                cpu.interrupt(ram, Interrupt::STAT);
            }
            cpu.interrupt(ram, Interrupt::VBLANK);
        }

        Ok(())
    }

    fn update_palettes(&mut self, ram: &ram::RAM) {
        let raw_bgp = ram.get(IO::BGP);
        self.bgp[0] = self.colors[((raw_bgp >> 0) & 0x3) as usize];
        self.bgp[1] = self.colors[((raw_bgp >> 2) & 0x3) as usize];
        self.bgp[2] = self.colors[((raw_bgp >> 4) & 0x3) as usize];
        self.bgp[3] = self.colors[((raw_bgp >> 6) & 0x3) as usize];

        let raw_obp0 = ram.get(IO::OBP0);
        self.obp0[0] = self.colors[((raw_obp0 >> 0) & 0x3) as usize];
        self.obp0[1] = self.colors[((raw_obp0 >> 2) & 0x3) as usize];
        self.obp0[2] = self.colors[((raw_obp0 >> 4) & 0x3) as usize];
        self.obp0[3] = self.colors[((raw_obp0 >> 6) & 0x3) as usize];

        let raw_obp1 = ram.get(IO::OBP1);
        self.obp1[0] = self.colors[((raw_obp1 >> 0) & 0x3) as usize];
        self.obp1[1] = self.colors[((raw_obp1 >> 2) & 0x3) as usize];
        self.obp1[2] = self.colors[((raw_obp1 >> 4) & 0x3) as usize];
        self.obp1[3] = self.colors[((raw_obp1 >> 6) & 0x3) as usize];
    }

    fn draw_debug(&mut self, ram: &mut ram::RAM) -> Result<()> {
        let lcdc = LCDC::from_bits(ram.get(IO::LCDC)).unwrap();

        // Tile data
        let tile_display_width = 32;
        for tile_id in 0..384 {
            let xy = Point::new(
                160 + (tile_id % tile_display_width) * 8,
                (tile_id / tile_display_width) * 8,
            );
            self.paint_tile(ram, tile_id as i16, &xy, self.bgp, false, false);
        }

        // Background scroll border
        if lcdc.contains(LCDC::BG_WIN_ENABLED) {
            let rect = Rect::new(0, 0, 160, 144);
            if let Some(canvas) = &mut self.canvas {
                canvas.set_draw_color(RED);
                canvas.draw_rect(rect).map_err(anyhow::Error::msg)?;
            }
        }

        // Window tiles
        if lcdc.contains(LCDC::WINDOW_ENABLED) {
            let wnd_y = ram.get(IO::WY);
            let wnd_x = ram.get(IO::WX);
            let rect = Rect::new(wnd_x as i32 - 7, wnd_y as i32, 160, 144);
            if let Some(canvas) = &mut self.canvas {
                canvas.set_draw_color(BLUE);
                canvas.draw_rect(rect).map_err(anyhow::Error::msg)?;
            }
        }

        Ok(())
    }

    fn draw_line(&mut self, ram: &mut ram::RAM, ly: i32) {
        let lcdc = LCDC::from_bits(ram.get(IO::LCDC)).unwrap();

        // Background tiles
        if lcdc.contains(LCDC::BG_WIN_ENABLED) {
            let scroll_y = ram.get(IO::SCY) as i32;
            let scroll_x = ram.get(IO::SCX) as i32;
            let tile_offset = !lcdc.contains(LCDC::DATA_SRC);
            let background_map = if lcdc.contains(LCDC::BG_MAP) {
                Mem::Map1
            } else {
                Mem::Map0
            } as u16;

            if self.debug {
                if let Some(canvas) = &mut self.canvas {
                    canvas.set_draw_color(RED);
                    canvas
                        .draw_point(Point::new(256 - scroll_x, ly))
                        .expect("draw point");
                }
            }

            let y_in_bgmap = (ly - scroll_y) & 0xFF; // % 256
            let tile_y = y_in_bgmap / 8;
            let tile_sub_y = y_in_bgmap % 8;

            for tile_x in scroll_x / 8..scroll_x / 8 + 21 {
                let mut tile_id = ram
                    .get(background_map + (tile_y % 32) as u16 * 32 + (tile_x % 32) as u16)
                    as i16;
                if tile_offset && tile_id < 0x80 {
                    tile_id += 0x100
                };
                let xy = Point::new(
                    ((tile_x * 8 - scroll_x) + 8) % 256 - 8,
                    ((tile_y * 8 - scroll_y) + 8) % 256 - 8,
                );
                self.paint_tile_line(ram, tile_id, &xy, self.bgp, false, false, tile_sub_y);
            }
        }

        // Window tiles
        if lcdc.contains(LCDC::WINDOW_ENABLED) {
            let wnd_y = ram.get(IO::WY);
            let wnd_x = ram.get(IO::WX);
            let tile_offset = !lcdc.contains(LCDC::DATA_SRC);
            let window_map = if lcdc.contains(LCDC::WINDOW_MAP) {
                Mem::Map1
            } else {
                Mem::Map0
            } as u16;

            // blank out the background
            if ly as u8 > wnd_y {
                let rect = Rect::new(wnd_x as i32 - 7, ly, 160, 1);
                if let Some(canvas) = &mut self.canvas {
                    canvas.set_draw_color(self.bgp[0]);
                    canvas.fill_rect(rect).expect("fill rect");
                }
            }

            let y_in_bgmap = (ly - wnd_y as i32) & 0xFF;
            let tile_y = y_in_bgmap / 8;
            let tile_sub_y = y_in_bgmap % 8;

            for tile_x in 0..20 {
                let mut tile_id = ram.get(window_map + (tile_y as u16 * 32) + tile_x) as i16;
                if tile_offset && tile_id < 0x80 {
                    tile_id += 0x100
                };
                let xy = Point::new(
                    tile_x as i32 * 8 + wnd_x as i32 - 7,
                    tile_y as i32 * 8 + wnd_y as i32,
                );
                self.paint_tile_line(ram, tile_id, &xy, self.bgp, false, false, tile_sub_y);
            }
        }

        // Sprites
        if lcdc.contains(LCDC::OBJ_ENABLED) {
            let dbl = lcdc.contains(LCDC::OBJ_SIZE);

            // TODO: sorted by x
            // let sprites: [Sprite; 40] = [];
            // memcpy(sprites, &ram.data[OAM_BASE], 40 * sizeof(Sprite));
            // for sprite in sprites.iter() {
            for n in 0..40 {
                let sprite = Sprite {
                    y: ram.get(Mem::OamBase as u16 + 4 * n + 0),
                    x: ram.get(Mem::OamBase as u16 + 4 * n + 1),
                    tile_id: ram.get(Mem::OamBase as u16 + 4 * n + 2),
                    flags: SpriteFlags::from_bits_truncate(
                        ram.get(Mem::OamBase as u16 + 4 * n + 3),
                    ),
                };
                if sprite.is_live() {
                    let palette = if sprite.flags.contains(SpriteFlags::PALETTE) {
                        self.obp1
                    } else {
                        self.obp0
                    };
                    //printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y);
                    let mut xy = Point::new(sprite.x as i32 - 8, sprite.y as i32 - 16);
                    self.paint_tile(
                        ram,
                        sprite.tile_id as i16,
                        &xy,
                        palette,
                        sprite.flags.contains(SpriteFlags::FLIP_X),
                        sprite.flags.contains(SpriteFlags::FLIP_Y),
                    );

                    if dbl {
                        xy.y = sprite.y as i32 - 8;
                        self.paint_tile(
                            ram,
                            sprite.tile_id as i16 + 1,
                            &xy,
                            palette,
                            sprite.flags.contains(SpriteFlags::FLIP_X),
                            sprite.flags.contains(SpriteFlags::FLIP_Y),
                        );
                    }
                }
            }
        }
    }

    #[inline(always)]
    fn paint_tile(
        &mut self,
        ram: &ram::RAM,
        tile_id: i16,
        offset: &Point,
        palette: [Color; 4],
        flip_x: bool,
        flip_y: bool,
    ) {
        for y in 0..8 {
            self.paint_tile_line(ram, tile_id, offset, palette, flip_x, flip_y, y);
        }

        if self.debug {
            if let Some(canvas) = &mut self.canvas {
                canvas.set_draw_color(gen_hue(tile_id as u8));
                canvas
                    .draw_rect(Rect::new(offset.x, offset.y, 8, 8))
                    .expect("draw rect");
            }
        }
    }

    #[inline(always)]
    fn paint_tile_line(
        &mut self,
        ram: &ram::RAM,
        tile_id: i16,
        offset: &Point,
        palette: [Color; 4],
        flip_x: bool,
        flip_y: bool,
        y: i32,
    ) {
        let addr = (Mem::TileData as i32 + tile_id as i32 * 16 + y * 2) as u16;
        let low_byte = ram.get(addr);
        let high_byte = ram.get(addr + 1);
        for x in 0..8 {
            let low_bit = (low_byte >> (7 - x)) & 0x01;
            let high_bit = (high_byte >> (7 - x)) & 0x01;
            let px = (high_bit << 1) | low_bit;
            // pallette #0 = transparent, so don't draw anything
            if px > 0 {
                let xy = Point::new(
                    offset.x + if flip_x { 7 - x } else { x },
                    offset.y + if flip_y { 7 - y } else { y },
                );
                if offset.x <= 160 && xy.x >= 160 {
                    return;
                }
                if let Some(canvas) = &mut self.canvas {
                    canvas.set_draw_color(palette[px as usize]);
                    canvas.draw_point(xy).expect("draw point");
                }
            }
        }
    }
}

#[allow(arithmetic_overflow)]
fn gen_hue(n: u8) -> Color {
    let region = n / 43;
    let remainder = (n - (region * 43)) * 6;

    let q = 255 - remainder;
    let t = remainder;

    match region {
        0 => Color::RGB(255, t, 0),
        1 => Color::RGB(q, 255, 0),
        2 => Color::RGB(0, 255, t),
        3 => Color::RGB(0, q, 255),
        4 => Color::RGB(t, 0, 255),
        _ => Color::RGB(255, 0, q),
    }
}
