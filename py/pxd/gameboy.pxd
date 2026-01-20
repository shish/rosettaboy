from .cart cimport Cart
from .cpu cimport CPU
from .gpu cimport GPU
from .clock cimport Clock
from .buttons cimport Buttons
from .ram cimport RAM

cdef class GameBoy:
    cdef public Cart cart
    cdef public RAM ram
    cdef public CPU cpu
    cdef public GPU gpu
    cdef public Buttons buttons
    cdef public Clock clock

    cpdef run(self)

    cpdef tick(self)
