#include <iostream>

#include "args.h"

#include "apu.h"
#include "buttons.h"
#include "cart.h"
#include "clock.h"
#include "cpu.h"
#include "errors.h"
#include "gpu.h"

using namespace std;

int main(int argc, char *argv[]) {
    Args *args = new Args(argc, argv);
    if(args->exit_code >= 0) {
        return args->exit_code;
    }

    Cart *cart = nullptr;
    RAM *ram = nullptr;
    CPU *cpu = nullptr;
    GPU *gpu = nullptr;
    Buttons *buttons = nullptr;
    Clock *clock = nullptr;

    cart = new Cart(args->rom);
    ram = new RAM(cart);
    cpu = new CPU(ram, args->debug_cpu);
    gpu = new GPU(cpu, cart->name, args->headless, args->debug_gpu);
    buttons = new Buttons(cpu, args->headless);
    if(!args->silent) new APU(cpu, args->debug_apu);
    clock = new Clock(buttons, args->profile, args->turbo);

    /**
     * GB CPU runs at 4MHz, but each action takes a multiple of 4 hardware
     * cycles. So to avoid overhead, we run the main loop at 1MHz, and each
     * "cycle" that each subsystem counts represents 4 hardware cycles.
     */
    try {
        while(true) {
            cpu->tick();
            gpu->tick();
            buttons->tick();
            clock->tick();
        }
    } catch(EmuException *e) {
        std::cout << e->what() << std::endl;
        return e->exit_code;
    }

    printf("\n");
    return 0;
}
