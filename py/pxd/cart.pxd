from .consts cimport u8, u16

cdef class Cart:
    cdef public bytes data_bytes
    cdef u8* data
    cdef public bytes rsts
    cdef public tuple init
    cdef public tuple logo
    cdef public str name
    cdef public bint is_gbc
    cdef public u16 licensee
    cdef public bint is_sgb
    cdef public object cart_type
    cdef public int rom_size
    cdef public int ram_size
    cdef public u8 destination
    cdef public u8 old_licensee
    cdef public u8 rom_version
    cdef public u8 complement_check
    cdef public u16 checksum

    cdef u8* ram
