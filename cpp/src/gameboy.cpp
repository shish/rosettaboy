#include "gameboy.h"

GameBoy::GameBoy(Args *args) {
    cart = new Cart(args->rom);
    ram = new RAM(cart);
    cpu = new CPU(ram, args->debug_cpu);
    gpu = new GPU(cpu, cart->name, args->headless, args->debug_gpu);
    buttons = new Buttons(cpu, args->headless);
    if(!args->silent) new APU(cpu, args->debug_apu);
    clock = new Clock(buttons, args->profile, args->turbo);
}

/**
 * GB CPU runs at 4MHz, but each action takes a multiple of 4 hardware
 * cycles. So to avoid overhead, we run the main loop at 1MHz, and each
 * "cycle" that each subsystem counts represents 4 hardware cycles.
 */
void GameBoy::run() {
    while(true) {
        this->tick();
    }
}

void GameBoy::tick() {
    this->cpu->tick();
    this->gpu->tick();
    this->buttons->tick();
    this->clock->tick();
}