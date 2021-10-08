import pygame
from typing import List
from .consts import *
from .cpu import CPU

SCALE = 2


class GPU:
    def __init__(self, cpu: CPU, debug: bool = False, headless: bool = False) -> None:
        self.cpu = cpu
        self.headless = headless
        self.debug = debug
        self.tiles: List[pygame.Surface] = []
        self._last_tile_data: List[int] = []
        self.title = "RosettaBoy - " + (cpu.ram.cart.name or "<corrupt>")

        if not self.debug:
            size = (160, 144)
        else:
            size = (512, 256)

        if not headless:
            pygame.display.init()
            self.window = pygame.display.set_mode((size[0] * SCALE, size[1] * SCALE))
            pygame.display.set_caption(self.title)
            pygame.display.update()

        self.buffer = pygame.Surface(size)

        self.colors = [
            pygame.Color(0x9B, 0xBC, 0x0F),
            pygame.Color(0x8B, 0xAC, 0x0F),
            pygame.Color(0x30, 0x62, 0x30),
            pygame.Color(0x0F, 0x38, 0x0F),
        ]
        self.bgp = self.colors
        self.obp0 = self.colors
        self.obp1 = self.colors

        self.cycle = 0

    def tick(self) -> bool:
        self.cycle += 1

        # CPU STOP stops all LCD activity until a button is pressed
        if self.cpu.stop:
            return True

        # Check if LCD enabled at all
        if not (self.cpu.ram[IO_LCDC] & (1 << 7)):  # IO_LCDC & ENABLED
            # When LCD is re-enabled, LY is 0
            # Does it become 0 as soon as disabled??
            self.cpu.ram[IO_LY] = 0
            if not self.debug:
                return True

        lx = self.cycle % 114
        ly = (self.cycle // 114) % 154
        self.cpu.ram[IO_LY] = ly

        # LYC compare & interrupt
        if self.cpu.ram[IO_LY] == self.cpu.ram[IO_LCY]:
            if self.cpu.ram[IO_STAT] & STATFlag.LYC_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)
            self.cpu.ram[IO_STAT] |= STATFlag.LCY_EQUAL
        else:
            self.cpu.ram[IO_STAT] &= ~STATFlag.LCY_EQUAL

        # Set mode
        if lx == 0 and ly < 144:
            self.cpu.ram[IO_STAT] = (
                self.cpu.ram[IO_STAT] & ~STATFlag.MODE
            ) | STATMode.OAM
            if self.cpu.ram[IO_STAT] & STATFlag.OAM_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)
        elif lx == 20 and ly < 144:
            self.cpu.ram[IO_STAT] = (
                self.cpu.ram[IO_STAT] & ~STATFlag.MODE
            ) | STATMode.DRAWING
            # TODO: really we should draw one line of pixels for each LY,
            # rather than the whole screen at LY == 0
            if ly == 0:
                if not self.draw_lcd():
                    return False
        elif lx == 63 and ly < 144:
            self.cpu.ram[IO_STAT] = (
                self.cpu.ram[IO_STAT] & ~STATFlag.MODE
            ) | STATMode.HBLANK
            if self.cpu.ram[IO_STAT] & STATFlag.HBLANK_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)
        elif lx == 0 and ly == 144:
            self.cpu.ram[IO_STAT] = (
                self.cpu.ram[IO_STAT] & ~STATFlag.MODE
            ) | STATMode.VBLANK
            if self.cpu.ram[IO_STAT] & STATFlag.VBLANK_INTERRUPT:
                self.cpu.interrupt(Interrupt.STAT)
            self.cpu.interrupt(Interrupt.VBLANK)

        return True

    def update_palettes(self) -> None:
        self.bgp = [
            self.colors[(self.cpu.ram[0xFF47] >> 0) & 0x3],
            self.colors[(self.cpu.ram[0xFF47] >> 2) & 0x3],
            self.colors[(self.cpu.ram[0xFF47] >> 4) & 0x3],
            self.colors[(self.cpu.ram[0xFF47] >> 6) & 0x3],
        ]
        self.obp0 = [
            self.colors[(self.cpu.ram[0xFF48] >> 0) & 0x3],
            self.colors[(self.cpu.ram[0xFF48] >> 2) & 0x3],
            self.colors[(self.cpu.ram[0xFF48] >> 4) & 0x3],
            self.colors[(self.cpu.ram[0xFF48] >> 6) & 0x3],
        ]
        self.obp1 = [
            self.colors[(self.cpu.ram[0xFF49] >> 0) & 0x3],
            self.colors[(self.cpu.ram[0xFF49] >> 2) & 0x3],
            self.colors[(self.cpu.ram[0xFF49] >> 4) & 0x3],
            self.colors[(self.cpu.ram[0xFF49] >> 6) & 0x3],
        ]

    def draw_lcd(self) -> bool:
        self.update_palettes()

        LCDC = self.cpu.ram[IO_LCDC]

        self.buffer.fill(self.bgp[0])

        # for some reason when using tile map 1, tiles are 0..255,
        # when using tile map 0, tiles are -128..127; also, they overlap
        # T1: [0...........255]
        # T2:        [-128..........127]
        tile_data = self.cpu.ram.data[TILE_DATA_TABLE_1 : TILE_DATA_TABLE_1 + 384 * 16]
        if self._last_tile_data != tile_data:
            self.tiles = []
            for tile_id in range(0x180):  # 384 tiles
                self.tiles.append(self.get_tile(TILE_DATA_TABLE_1, tile_id, self.bgp))
            self._last_tile_data = tile_data

        if LCDC & LCDC_DATA_SRC:
            table = TILE_DATA_TABLE_1
            tile_offset = 0
        else:
            table = TILE_DATA_TABLE_0
            tile_offset = 0xFF

        SCROLL_Y = self.cpu.ram[IO_SCY]
        SCROLL_X = self.cpu.ram[IO_SCX]
        WND_Y = self.cpu.ram[IO_WY]
        WND_X = self.cpu.ram[IO_WX]

        # Display only valid area
        if not self.debug:

            # LCD enabled at all
            if not LCDC & LCDC_ENABLED:
                return True

            # Background tiles
            if LCDC & LCDC_BG_WIN_ENABLED:
                if LCDC & LCDC_BG_MAP:
                    background_map = BACKGROUND_MAP_1
                else:
                    background_map = BACKGROUND_MAP_0
                for tile_y in range(18):
                    for tile_x in range(20):
                        tile_id = self.cpu.ram[background_map + tile_y * 32 + tile_x]
                        x = tile_x * 8 - SCROLL_X
                        y = tile_y * 8 - SCROLL_Y
                        if x < -8:
                            x += 256
                        if y < -8:
                            y += 256
                        if tile_offset and tile_id > 0x7F:
                            tile_id -= 0xFF
                        self.buffer.blit(self.tiles[tile_offset + tile_id], (x, y))

            # Window tiles
            if LCDC & LCDC_WINDOW_ENABLED:
                if LCDC & LCDC_WINDOW_MAP:
                    window_map = WINDOW_MAP_1
                else:
                    window_map = WINDOW_MAP_0

                for y in range(144 // 8):
                    for x in range(160 // 8):
                        tile_id = self.cpu.ram[window_map + y * 32 + x]
                        if tile_offset and tile_id > 0x7F:
                            tile_id -= 0xFF
                        self.buffer.blit(
                            self.tiles[tile_offset + tile_id],
                            (x * 8 + WND_X, y * 8 + WND_Y),
                        )

            # Sprites
            if LCDC & LCDC_OBJ_ENABLED:
                if LCDC & LCDC_OBJ_SIZE:
                    size = (8, 16)
                else:
                    size = (8, 8)
                # TODO: sorted by x
                for sprite_id in range(40):
                    # FIXME: use obp instead of bgp
                    # + flags support
                    y, x, tile_id, flags = self.cpu.ram.data[
                        OAM_BASE + (sprite_id * 4) : OAM_BASE + (sprite_id * 4) + 4
                    ]
                    if tile_offset and tile_id > 0x7F:
                        tile_id -= 0xFF
                    # Bit7   OBJ-to-BG Priority (0=OBJ Above BG, 1=OBJ Behind BG color 1-3)
                    #        (Used for both BG and Window. BG color 0 is always behind OBJ)
                    # Bit6   Y flip          (0=Normal, 1=Vertically mirrored)
                    # Bit5   X flip          (0=Normal, 1=Horizontally mirrored)
                    # Bit4   Palette number  **Non CGB Mode Only** (0=OBP0, 1=OBP1)
                    self.buffer.blit(self.tiles[tile_offset + tile_id], (x, y))

        # Display all of VRAM
        else:
            # Background memory
            if LCDC & LCDC_BG_MAP:
                background_map = BACKGROUND_MAP_1
            else:
                background_map = BACKGROUND_MAP_0
            for y in range(32):
                for x in range(32):
                    tile_id = self.cpu.ram[background_map + y * 32 + x]
                    if tile_offset and tile_id > 0x7F:
                        tile_id -= 0xFF
                    self.buffer.blit(self.tiles[tile_offset + tile_id], (x * 8, y * 8))

            # Background scroll border
            pygame.draw.rect(
                self.buffer, pygame.Color(255, 0, 0), (SCROLL_X, SCROLL_Y, 160, 144), 1
            )

            # Tile data
            for y in range(len(self.tiles) // 32):
                for x in range(32):
                    self.buffer.blit(self.tiles[y * 32 + x], (256 + x * 8, y * 8))

        if not self.headless:
            self.window.blit(
                pygame.transform.scale(
                    self.buffer, (self.window.get_width(), self.window.get_height())
                ),
                (0, 0),
            )
            pygame.display.update()
        return True

    def get_tile(
        self, table: int, tile_id: int, pallette: List[pygame.Color]
    ) -> pygame.Surface:
        tile = self.cpu.ram.data[table + tile_id * 16 : table + (tile_id * 16) + 16]
        surf = pygame.Surface((8, 8))

        for y in range(8):
            for x in range(8):
                low_byte = tile[(y * 2)]
                high_byte = tile[(y * 2) + 1]
                low_bit = (low_byte >> (7 - x)) & 0x1
                high_bit = (high_byte >> (7 - x)) & 0x1
                px = (high_bit << 1) | low_bit
                surf.fill(pallette[px], ((x, y), (1, 1)))

        return surf
