extern crate sdl2;
use crate::consts;
use crate::cpu;
use crate::ram;

use sdl2::pixels::Color;
use sdl2::rect::{Point, Rect};

//const WIDTH: u16 = 256;
//const HEIGHT: u8 = 240;
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

struct Sprite {
    y: u8,
    x: u8,
    tile_id: u8,
    flags: u8,
}

impl Sprite {
    fn is_live(&self) -> bool {
        self.x > 0 && self.x < 168 && self.y > 0 && self.y < 160
    }
    fn palette(&self) -> bool {
        self.flags & consts::Bits::Bit4 as u8 != 0
    }
    fn flip_x(&self) -> bool {
        self.flags & consts::Bits::Bit5 as u8 != 0
    }
    fn flip_y(&self) -> bool {
        self.flags & consts::Bits::Bit6 as u8 != 0
    }
    fn _behind(&self) -> bool {
        self.flags & consts::Bits::Bit7 as u8 != 0
    }
}

pub struct GPU {
    canvas: sdl2::render::Canvas<sdl2::video::Window>,
    cycle: u32,
    colors: [Color; 4],
    bgp: [Color; 4],
    obp0: [Color; 4],
    obp1: [Color; 4],
    debug: bool,
}

impl GPU {
    pub fn init(sdl_context: &sdl2::Sdl, title: &str, _headless: bool, debug: bool) -> Result<GPU, String> {
        let video_subsystem = sdl_context.video()?;
        let (w, h) = if debug { (520, 144) } else { (160, 144) };
        let window = video_subsystem
            .window(&format!("Spindle: {}", title)[..], w, h)
            .position_centered()
            .build()
            .map_err(|e| e.to_string())?;
        let canvas = window
            .into_canvas()
            .software()
            .build()
            .map_err(|e| e.to_string())?;

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

    pub fn tick(&mut self, ram: &mut ram::RAM, cpu: &mut cpu::CPU) {
        // CPU STOP stops all LCD activity until a button is pressed
        if cpu.stop {
            return;
        }

        self.cycle += 1;

        let lcdc = ram.get(consts::IO::LCDC);

        // LCD enabled at all
        if (lcdc & consts::LCDC::Enabled as u8) == 0 {
            // When LCD is re-enabled, LY is 0
            // Does it become 0 as soon as disabled??
            ram.set(consts::IO::LY, 0);
            if !self.debug {
                return;
            }
        }

        let lx = self.cycle % 114;
        let ly = (self.cycle / 114) % 154;
        ram.set(consts::IO::LY, ly as u8);

        // LYC compare & interrupt
        if ram.get(consts::IO::LY) == ram.get(consts::IO::LYC) {
            if ram.get(consts::IO::STAT) & consts::StatFlag::LCYInterrupt as u8 != 0 {
                cpu.interrupt(ram, consts::Interrupt::STAT);
            }
            ram._or(consts::IO::STAT, consts::StatFlag::LCYEqual as u8);
        } else {
            ram._and(consts::IO::STAT, !(consts::StatFlag::LCYEqual as u8));
        }

        // Set `ram[STAT].bit{0,1}` to `OAM / Drawing / HBlank / VBlank`
        if lx == 0 && ly < 144 {
            ram.set(
                consts::IO::STAT,
                (ram.get(consts::IO::STAT) & !(consts::StatFlag::Mode as u8))
                    | consts::StatMode::OAM as u8,
            );
            if ram.get(consts::IO::STAT) & consts::StatFlag::OAMInterrupt as u8 != 0 {
                cpu.interrupt(ram, consts::Interrupt::STAT);
            }
        } else if lx == 20 && ly < 144 {
            ram.set(
                consts::IO::STAT,
                (ram.get(consts::IO::STAT) & !(consts::StatFlag::Mode as u8))
                    | consts::StatMode::Drawing as u8,
            );
            if ly == 0 {
                // TODO: how often should we update palettes?
                // Should every pixel reference them directly?
                self.update_palettes(ram);
                // TODO: do we need to clear if we write every pixel?
                self.canvas.set_draw_color(self.bgp[0]);
                self.canvas.clear();
            }
            self.draw_line(ram, ly as i32);
            if ly == 143 {
                if self.debug {
                    self.draw_debug(ram);
                }
                self.canvas.present();
            }
        } else if lx == 63 && ly < 144 {
            ram.set(
                consts::IO::STAT,
                (ram.get(consts::IO::STAT) & !(consts::StatFlag::Mode as u8))
                    | consts::StatMode::HBlank as u8,
            );
            if ram.get(consts::IO::STAT) & consts::StatFlag::HBlankInterrupt as u8 != 0 {
                cpu.interrupt(ram, consts::Interrupt::STAT);
            }
        } else if lx == 0 && ly == 144 {
            ram.set(
                consts::IO::STAT,
                (ram.get(consts::IO::STAT) & !(consts::StatFlag::Mode as u8))
                    | consts::StatMode::VBlank as u8,
            );
            if ram.get(consts::IO::STAT) & consts::StatFlag::VBlankInterrupt as u8 != 0 {
                cpu.interrupt(ram, consts::Interrupt::STAT);
            }
            cpu.interrupt(ram, consts::Interrupt::VBLANK);
        }
    }

    fn update_palettes(&mut self, ram: &ram::RAM) {
        let raw_bgp = ram.get(consts::IO::BGP);
        self.bgp[0] = self.colors[((raw_bgp >> 0) & 0x3) as usize];
        self.bgp[1] = self.colors[((raw_bgp >> 2) & 0x3) as usize];
        self.bgp[2] = self.colors[((raw_bgp >> 4) & 0x3) as usize];
        self.bgp[3] = self.colors[((raw_bgp >> 6) & 0x3) as usize];

        let raw_obp0 = ram.get(consts::IO::OBP0);
        self.obp0[0] = self.colors[((raw_obp0 >> 0) & 0x3) as usize];
        self.obp0[1] = self.colors[((raw_obp0 >> 2) & 0x3) as usize];
        self.obp0[2] = self.colors[((raw_obp0 >> 4) & 0x3) as usize];
        self.obp0[3] = self.colors[((raw_obp0 >> 6) & 0x3) as usize];

        let raw_obp1 = ram.get(consts::IO::OBP1);
        self.obp1[0] = self.colors[((raw_obp1 >> 0) & 0x3) as usize];
        self.obp1[1] = self.colors[((raw_obp1 >> 2) & 0x3) as usize];
        self.obp1[2] = self.colors[((raw_obp1 >> 4) & 0x3) as usize];
        self.obp1[3] = self.colors[((raw_obp1 >> 6) & 0x3) as usize];
    }

    fn draw_debug(&mut self, ram: &mut ram::RAM) {
        let lcdc = ram.get(consts::IO::LCDC);

        // Tile data
        let tile_display_width = 32;
        for tile_id in 0..384 {
            let xy = Point::new(
                256 + (tile_id % tile_display_width) * 8,
                (tile_id / tile_display_width) * 8,
            );
            self.paint_tile(ram, tile_id as i16, &xy, self.bgp, false, false);
        }

        // Background scroll border
        if lcdc & consts::LCDC::BgWinEnabled as u8 != 0 {
            let rect = Rect::new(0, 0, 160, 144);
            self.canvas.set_draw_color(RED);
            self.canvas.draw_rect(rect).expect("draw rect");
        }

        // Window tiles
        if lcdc & consts::LCDC::WindowEnabled as u8 != 0 {
            let wnd_y = ram.get(consts::IO::WY);
            let wnd_x = ram.get(consts::IO::WX);
            let rect = Rect::new(wnd_x as i32 - 7, wnd_y as i32, 160, 144);
            self.canvas.set_draw_color(BLUE);
            self.canvas.draw_rect(rect).expect("draw rect");
        }
    }

    fn draw_line(&mut self, ram: &mut ram::RAM, ly: i32) {
        let lcdc = ram.get(consts::IO::LCDC);

        // Background tiles
        if lcdc & consts::LCDC::BgWinEnabled as u8 != 0 {
            let scroll_y = ram.get(consts::IO::SCY) as i32;
            let scroll_x = ram.get(consts::IO::SCX) as i32;
            let tile_offset = lcdc & consts::LCDC::DataSrc as u8 == 0;
            let background_map = if lcdc & consts::LCDC::BgMap as u8 != 0 {
                consts::Mem::Map1
            } else {
                consts::Mem::Map0
            } as u16;

            if self.debug {
                self.canvas.set_draw_color(RED);
                self.canvas
                    .draw_point(Point::new(256 - scroll_x, ly))
                    .expect("draw point");
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
        if lcdc & consts::LCDC::WindowEnabled as u8 != 0 {
            let wnd_y = ram.get(consts::IO::WY);
            let wnd_x = ram.get(consts::IO::WX);
            let tile_offset = lcdc & consts::LCDC::DataSrc as u8 == 0;
            let window_map = if lcdc & consts::LCDC::WindowMap as u8 != 0 {
                consts::Mem::Map1
            } else {
                consts::Mem::Map0
            } as u16;

            // blank out the background
            let rect = Rect::new(wnd_x as i32 - 7, wnd_y as i32, 160, 144);
            self.canvas.set_draw_color(self.bgp[0]);
            self.canvas.fill_rect(rect).expect("fill rect");

            let y_in_bgmap = ly - wnd_y as i32;
            let tile_y = y_in_bgmap / 8;
            let tile_sub_y = y_in_bgmap % 8;

            for tile_x in 0..20 {
                let mut tile_id = ram.get(window_map + tile_y as u16 * 32 + tile_x) as i16;
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
        if lcdc & consts::LCDC::ObjEnabled as u8 != 0 {
            let dbl = (lcdc & consts::LCDC::ObjSize as u8) != 0;

            // TODO: sorted by x
            // let sprites: [Sprite; 40] = [];
            // memcpy(sprites, &ram.data[OAM_BASE], 40 * sizeof(Sprite));
            // for sprite in sprites.iter() {
            for n in 0..40 {
                let sprite = Sprite {
                    y: ram.get(consts::Mem::OamBase as u16 + 4 * n + 0),
                    x: ram.get(consts::Mem::OamBase as u16 + 4 * n + 1),
                    tile_id: ram.get(consts::Mem::OamBase as u16 + 4 * n + 2),
                    flags: ram.get(consts::Mem::OamBase as u16 + 4 * n + 3),
                };
                if sprite.is_live() {
                    let palette = if sprite.palette() {
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
                        sprite.flip_x(),
                        sprite.flip_y(),
                    );

                    if dbl {
                        xy.y = sprite.y as i32 - 8;
                        self.paint_tile(
                            ram,
                            sprite.tile_id as i16 + 1,
                            &xy,
                            palette,
                            sprite.flip_x(),
                            sprite.flip_y(),
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
            self.canvas.set_draw_color(gen_hue(tile_id as u8));
            self.canvas
                .draw_rect(Rect::new(offset.x, offset.y, 8, 8))
                .expect("draw rect");
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
        let addr = (consts::Mem::TileData as i32 + tile_id as i32 * 16 + y * 2) as u16;
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
                self.canvas.set_draw_color(palette[px as usize]);
                self.canvas.draw_point(xy).expect("draw point");
            }
        }
    }
}

#[allow(exceeding_bitshifts)]
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
