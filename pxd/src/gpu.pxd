from .consts cimport *
from .cpu cimport CPU

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
    cdef public object hw_window
    cdef public object hw_renderer
    cdef public object hw_buffer
    cdef public object buffer
    cdef public object renderer
    cdef public list colors

    cdef public list bgp
    cdef public list obp0
    cdef public list obp1

    cpdef void tick(self)

    cpdef void update_palettes(self)
    cpdef void draw_debug(self)
    cpdef void draw_line(self, int ly)
    cpdef void paint_tile(self, int tile_id, object offset, object palette, bint flip_x, bint flip_y)
    cpdef void paint_tile_line(self, int tile_id, object offset, object palette, bint flip_x, bint flip_y, int y)


cpdef object gen_hue(int n)
