cimport CySDL2 as sdl2

from .ram cimport RAM
from .consts cimport *

cdef public u8[256] OP_CYCLES
cdef public u8[256] OP_CB_CYCLES
cdef public u8[256] OP_TYPES

cdef public u8[4] OP_LENS

cdef class OpArg:
    cdef public u8 u8
    cdef public i8 i8
    cdef public u16 u16
    cpdef void _init(self, RAM ram, u16 addr, u8 arg_type)
    @staticmethod
    cdef OpArg create(RAM ram, u16 addr, u8 arg_type)

cdef class CPU:
    cdef public RAM ram
    cdef public bint interrupts
    cdef public bint halt
    cdef public bint stop
    cdef public long long cycle
    cdef public int _nopslide
    cdef public bint _debug
    cdef public str _debug_str
    cdef public long long _owed_cycles

    cdef public u8 A
    cdef public u8 B
    cdef public u8 C
    cdef public u8 D
    cdef public u8 E
    cdef public u8 H
    cdef public u8 L

    cdef public u16 SP
    cdef public u16 PC

    cdef public booli FLAG_Z
    cdef public booli FLAG_N
    cdef public booli FLAG_H
    cdef public booli FLAG_C

    cpdef u16 AF(self)
    cpdef void setAF(self, u16 val)
    cpdef u16 BC(self)
    cpdef void setBC(self, u16 val)
    cpdef u16 DE(self)
    cpdef void setDE(self, u16 val)
    cpdef u16 HL(self)
    cpdef void setHL(self, u16 val)
    cpdef u16 MEM_AT_HL(self)
    cpdef void setMEM_AT_HL(self, u16 val)

    # cpdef void dump_regs(self)

    cpdef void interrupt(self, u8 i)

    cpdef void tick(self)

    cpdef int tick_dma(self) except? -1
    cpdef int tick_clock(self) except? -1
    cpdef booli check_interrupt(self, u8 queue, u8 i, u16 handler) except? -1
    cpdef int tick_interrupts(self) except? -1
    cpdef int tick_instructions(self) except? -1
    cpdef int tick_main(self, u8 op) except? -1
    cpdef int tick_cb(self, u8 op) except? -1

    cpdef void _xor(self, u8 val)
    cpdef void _or(self, u8 val)
    cpdef void _and(self, u8 val)
    cpdef void _cp(self, u8 val)
    cpdef void _add(self, u8 val)
    cpdef void _adc(self, u8 val)
    cpdef void _sub(self, u8 val)
    cpdef void _sbc(self, u8 val)

    cpdef void push(self, u16 val)
    cpdef u16 pop(self)

    cpdef u8 get_reg(self, u8 n)
    cpdef void set_reg(self, u8 n, u8 val)
