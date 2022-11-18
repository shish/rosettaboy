#include "gameboy.h"

GameBoy::GameBoy(Args *args) {
    this->cart = new Cart(args->rom);
    this->ram = new RAM(this->cart, args->debug_ram);
    this->cpu = new CPU(this->ram, args->debug_cpu);
    this->gpu = new GPU(this->cpu, cart->name, args->headless, args->debug_gpu);
    this->buttons = new Buttons(this->cpu, args->headless);
    if(!args->silent) new APU(this->cpu, args->debug_apu);
    this->clock = new Clock(this->buttons, args->frames, args->profile, args->turbo);
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