Main
====

`main(args)`
------------
- Parse arguments
  - rom: string - path to a `.gb` ROM file
  - headless: bool - run without displaying the graphics
  - silent: bool - run without sound
  - debug_cpu: bool - print out the CPU state after every instruction
  - debug_gpu: bool - show the full sprite map and video RAM
  - debug_apu: bool - ?
  - debug_ram: bool - log mmap I/O events, eg writing to `0x2000` to switch ROM bank
  - profile: int - run for this many frames then exit
  - turbo: bool - no `sleep()`, run as fast as possible
- Initialise subsystems
  - [Cart](cart.md)
  - [Audio processing](apu.md) (background thread)
  - [CPU](cpu.md)
  - [GPU](gpu.md)
  - [Buttons](buttons.md)
  - [Clock](clock.md)
- Run main loop
  - CPU.tick()
  - GPU.tick()
  - Buttons.tick()
  - Clock.tick()
