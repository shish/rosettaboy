CPU
===

init()
------
- Set RAM and registers to 0

tick()
------
- tick_dma()
- tick_clock()
- tick_interrupts()
- tick_instructions()

tick_dma()
----------
- if DMA register is set, copy RAM from source to OAM

tick_clock()
------------
- Update timer registers (TIMA, TAC, TMA)

tick_interrupts()
-----------------
- fire off interrupts that are queued and enabled

tick_instructions()
-------------------
- if the previous instruction was long (taking several cycles),
  burn off the extra cycles
- look at `ram[cpu.PC]`
- execute the instruction
