from .consts cimport u8

cdef class Cart:
    cdef public bytes data_bytes
    cdef int* data
    cdef public bytes rsts
    cdef public tuple init
    cdef public tuple logo
    cdef public str name
    cdef public bint is_gbc
    cdef public int licensee
    cdef public bint is_sgb
    cdef public object cart_type
    cdef public int rom_size
    cdef public int ram_size
    cdef public int destination
    cdef public int old_licensee
    cdef public int rom_version
    cdef public int complement_check
    cdef public int checksum

    cdef int* ram
