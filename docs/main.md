Main
====

`main(args)`
------------
- Parse arguments
  - [Args](args.md)
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
