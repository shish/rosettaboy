import pygame

VRAM_BASE = 0x8000
TILE_DATA_TABLE_0 = 0x8800
TILE_DATA_TABLE_1 = 0x8000
BACKGROUND_MAP_0 = 0x9800
BACKGROUND_MAP_1 = 0x9C00
WINDOW_MAP_0 = 0x9800
WINDOW_MAP_1 = 0x9C00
OAM_BASE = 0xFE00
SCALE = 2


class LCD:
    def __init__(self, cpu, debug=False):
        self.cpu = cpu
        self._game_only = not debug
        self.tiles = []
        self._last_tile_data = []

        pygame.init()
        if self._game_only:
            self.buffer = pygame.Surface((160, 144))
            self.screen = pygame.display.set_mode((160 * SCALE, 144 * SCALE))
        else:
            self.buffer = pygame.Surface((512, 256))
            self.screen = pygame.display.set_mode((512 * SCALE, 256 * SCALE))
        pygame.display.set_caption("SPYGB - " + (cpu.cart.name or "<corrupt>"))
        self.clock = pygame.time.Clock()

    def update(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                print("Quitting")
                return False

        neon = [
            pygame.Color(255, 63, 63),
            pygame.Color(63, 255, 63),
            pygame.Color(63, 63, 255),
            pygame.Color(0, 0, 0),
        ]
        default = [
            pygame.Color(255, 255, 255),
            pygame.Color(192, 192, 192),
            pygame.Color(128, 128, 128),
            pygame.Color(0, 0, 0),
        ]
        available_colors = default

        bgp = [
            available_colors[(self.cpu.ram[0xFF47] >> 0) & 0x3],
            available_colors[(self.cpu.ram[0xFF47] >> 2) & 0x3],
            available_colors[(self.cpu.ram[0xFF47] >> 4) & 0x3],
            available_colors[(self.cpu.ram[0xFF47] >> 6) & 0x3],
        ]
        obp0 = [
            available_colors[(self.cpu.ram[0xFF48] >> 0) & 0x3],
            available_colors[(self.cpu.ram[0xFF48] >> 2) & 0x3],
            available_colors[(self.cpu.ram[0xFF48] >> 4) & 0x3],
            available_colors[(self.cpu.ram[0xFF48] >> 6) & 0x3],
        ]
        obp1 = [
            available_colors[(self.cpu.ram[0xFF49] >> 0) & 0x3],
            available_colors[(self.cpu.ram[0xFF49] >> 2) & 0x3],
            available_colors[(self.cpu.ram[0xFF49] >> 4) & 0x3],
            available_colors[(self.cpu.ram[0xFF49] >> 6) & 0x3],
        ]

        SCROLL_Y = self.cpu.ram[0xFF42]
        SCROLL_X = self.cpu.ram[0xFF43]
        WND_Y = self.cpu.ram[0xFF4A]
        WND_X = self.cpu.ram[0xFF4B]
        LCDC = self.cpu.ram[0xFF40]

        LCDC_ENABLED        = 0b10000000
        LCDC_WINDOW_MAP     = 0b01000000
        LCDC_WINDOW_ENABLED = 0b00100000
        LCDC_DATA_SRC       = 0b00010000
        LCDC_BG_MAP         = 0b00001000
        LCDC_OBJ_SIZE       = 0b00000100
        LCDC_OBJ_ENABLED    = 0b00000010
        LCDC_BG_WIN_ENABLED = 0b00000001

        # print("SCROLL ", SCROLL_X, SCROLL_Y)

        # for some reason when using tile map 1, tiles are 0..255,
        # when using tile map 0, tiles are -128..127; also, they overlap
        # T1: [0...........255]
        # T2:        [-128..........127]
        tile_data = self.cpu.ram[TILE_DATA_TABLE_1:TILE_DATA_TABLE_1+384*16]
        if self._last_tile_data != tile_data:
            self.tiles = []
            for tile_id in range(0x180):  # 384 tiles
                self.tiles.append(self.get_tile(TILE_DATA_TABLE_1, tile_id, bgp))
            self._last_tile_data = tile_data

        if LCDC & LCDC_DATA_SRC:
            table = TILE_DATA_TABLE_1
            tile_offset = 0
        else:
            table = TILE_DATA_TABLE_0
            tile_offset = 0xFF

        self.buffer.fill(bgp[0])

        # Display only valid area
        if self._game_only:

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
                        self.buffer.blit(self.tiles[tile_offset + tile_id], (x * 8 + WND_X, y * 8 + WND_Y))

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
                    y, x, tile_id, flags = self.cpu.ram[OAM_BASE + (sprite_id*4):OAM_BASE + (sprite_id*4) + 4]
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
            pygame.draw.rect(self.buffer, pygame.Color(255, 0, 0), (SCROLL_X, SCROLL_Y, 160, 144), 1)

            # Tile data
            for y in range(len(self.tiles) // 32):
                for x in range(32):
                    self.buffer.blit(self.tiles[y * 32 + x], (256 + x * 8, y * 8))

        self.screen.blit(
            pygame.transform.scale(self.buffer, (self.screen.get_width(), self.screen.get_height())),
            (0, 0)
        )
        pygame.display.update()
        self.clock.tick(60)
        return True

    def get_tile(self, table, tile_id, pallette):
        tile = self.cpu.ram[table + tile_id * 16: table + (tile_id * 16) + 16]
        surf = pygame.Surface((8, 8))

        for y in range(8):
            for x in range(8):
                low_byte = tile[(y * 2)]
                high_byte = tile[(y * 2) + 1]
                low_bit = (low_byte >> (7-x)) & 0x1
                high_bit = (high_byte >> (7-x)) & 0x1
                px = (high_bit << 1) | low_bit
                surf.fill(pallette[px], ((x, y), (1, 1)))

        return surf

    def close(self):
        pygame.quit()
