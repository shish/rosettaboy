cimport CySDL2 as sdl2

from .consts cimport *
from .cpu cimport CPU


cdef sdl2.SDL_Rect* make_SDL_Rect(int x, int y, int w, int h)
cdef sdl2.SDL_Point make_SDL_Point(int x, int y)

cdef class _LCDC:
    cdef public u8 ENABLED
    cdef public u8 WINDOW_MAP
    cdef public u8 WINDOW_ENABLED
    cdef public u8 DATA_SRC
    cdef public u8 BG_MAP
    cdef public u8 OBJ_SIZE
    cdef public u8 OBJ_ENABLED
    cdef public u8 BG_WIN_ENABLED

cdef public _LCDC LCDC


cdef class _Stat:
    cdef public u8 LYC_INTERRUPT
    cdef public u8 OAM_INTERRUPT
    cdef public u8 VBLANK_INTERRUPT
    cdef public u8 HBLANK_INTERRUPT
    cdef public u8 LYC_EQUAL
    cdef public u8 MODE_BITS

    cdef public u8 HBLANK
    cdef public u8 VBLANK
    cdef public u8 OAM
    cdef public u8 DRAWING

cdef public _Stat Stat


cdef class Sprite:
    cdef public int x
    cdef public int y
    cdef public int tile_id
    cdef public int flags
    @staticmethod
    cdef Sprite create(int x, int y, int tile_id, int flags)

    cpdef booli is_live(self)

    cpdef booli palette(self)
    cpdef booli x_flip(self)
    cpdef booli y_flip(self)
    cpdef booli behind(self)


cdef class GPU:
    cdef public CPU cpu
    cdef public bint headless
    cdef public bint debug
    cdef public long long cycle
    cdef public str title
    cdef sdl2.SDL_Window* hw_window
    cdef sdl2.SDL_Renderer* hw_renderer
    cdef sdl2.SDL_Texture* hw_buffer
    cdef sdl2.SDL_Surface* buffer
    cdef sdl2.SDL_Renderer* renderer
    cdef public sdl2.SDL_Color[4] colors

    cdef public sdl2.SDL_Color[4] bgp
    cdef public sdl2.SDL_Color[4] obp0
    cdef public sdl2.SDL_Color[4] obp1

    cpdef int tick(self) except? -1

    cpdef void update_palettes(self)
    cpdef void draw_debug(self)
    cpdef void draw_line(self, int ly)
    cdef void paint_tile(self, int tile_id, sdl2.SDL_Point offset, sdl2.SDL_Color[4] palette, bint flip_x, bint flip_y)
    cdef void paint_tile_line(self, int tile_id, sdl2.SDL_Point offset, sdl2.SDL_Color[4] palette, bint flip_x, bint flip_y, int y)


cpdef sdl2.SDL_Color gen_hue(int n)
