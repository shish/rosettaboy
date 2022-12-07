from .cart cimport Cart
from .consts cimport Mem, u16, u8, booli

cdef public u16 ROM_BANK_SIZE
cdef public u16 RAM_BANK_SIZE

cdef class RAM:
    cdef public Cart cart
    cdef public u8[256] boot
    cdef public u8[65536] data
    cdef public booli debug
    cdef public booli ram_enable
    cdef public booli ram_bank_mode
    cdef public u8 rom_bank_low
    cdef public u8 rom_bank_high
    cdef public u8 rom_bank
    cdef public u8 ram_bank

    cpdef u8 get(self, u16 addr)
    cpdef void set(self, u16 addr, u8 val)
