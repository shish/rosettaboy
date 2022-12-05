from .cpu cimport CPU
from .consts cimport Interrupt, Mem, u8, booli


cdef class _Joypad:
    cdef public int MODE_BUTTONS
    cdef public int MODE_DPAD
    cdef public int DOWN
    cdef public int START
    cdef public int UP
    cdef public int SELECT
    cdef public int LEFT
    cdef public int B
    cdef public int RIGHT
    cdef public int A

cdef public _Joypad Joypad

cdef class Buttons:
    cdef public CPU cpu
    cdef public long long cycle
    cdef public booli turbo
    cdef public booli up
    cdef public booli down
    cdef public booli left
    cdef public booli right
    cdef public booli a
    cdef public booli b
    cdef public booli start
    cdef public booli select

    cpdef int tick(self) except? -1

    cpdef int update_buttons(self) except? -1

    cpdef booli handle_inputs(self) except? -1
