from .consts cimport booli
from .buttons cimport Buttons

cdef class Clock:
    cdef public Buttons buttons
    cdef public long long cycle
    cdef public long long frame
    cdef public long long start
    cdef public long long frames
    cdef public long long profile
    cdef public booli turbo
    cdef public long long last_frame_start

    cpdef int tick(self) except? -1
