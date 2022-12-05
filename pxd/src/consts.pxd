import cython

ctypedef cython.uchar u8
ctypedef cython.ushort u16
ctypedef cython.char i8
ctypedef int booli # `int` compiles better sometimes (E.G. CPU.AF) than `bint`.

cpdef u8 as_u8(int val)
cpdef bint as_bool(int val)

cdef class _Mem:
    cdef public u16 VBLANK_HANDLER
    cdef public u16 LCD_HANDLER
    cdef public u16 TIMER_HANDLER
    cdef public u16 SERIAL_HANDLER
    cdef public u16 JOYPAD_HANDLER

    cdef public u16 TILE_DATA
    cdef public u16 MAP_0
    cdef public u16 MAP_1
    cdef public u16 OAM_BASE

    cdef public u16 JOYP

    cdef public u16 SB
    cdef public u16 SC

    cdef public u16 DIV
    cdef public u16 TIMA
    cdef public u16 TMA
    cdef public u16 TAC

    cdef public u16 IF_

    cdef public u16 NR10
    cdef public u16 NR11
    cdef public u16 NR12
    cdef public u16 NR13
    cdef public u16 NR14

    cdef public u16 NR20
    cdef public u16 NR21
    cdef public u16 NR22
    cdef public u16 NR23
    cdef public u16 NR24

    cdef public u16 NR30
    cdef public u16 NR31
    cdef public u16 NR32
    cdef public u16 NR33
    cdef public u16 NR34

    cdef public u16 NR40
    cdef public u16 NR41
    cdef public u16 NR42
    cdef public u16 NR43
    cdef public u16 NR44

    cdef public u16 NR50
    cdef public u16 NR51
    cdef public u16 NR52

    cdef public u16 LCDC
    cdef public u16 STAT
    cdef public u16 SCY
    cdef public u16 SCX
    cdef public u16 LY
    cdef public u16 LYC
    cdef public u16 DMA
    cdef public u16 BGP
    cdef public u16 OBP0
    cdef public u16 OBP1
    cdef public u16 WY
    cdef public u16 WX

    cdef public u16 BOOT

    cdef public u16 IE

cdef public _Mem Mem

cdef class _Interrupt:
    cdef public u8 VBLANK
    cdef public u8 STAT
    cdef public u8 TIMER
    cdef public u8 SERIAL
    cdef public u8 JOYPAD

cdef public _Interrupt Interrupt
