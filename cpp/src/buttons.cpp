#include "buttons.h"

Buttons::Buttons(CPU *cpu) {
    SDL_InitSubSystem(SDL_INIT_EVENTS);
    this->cpu = cpu;
    this->cycle = 0;
}

bool Buttons::tick() {
    this->cycle++;
    this->update_buttons();
    if (this->need_interrupt) {
        this->cpu->stop = false;
        this->cpu->interrupt(INT_JOYPAD);
        this->need_interrupt = false;
    }
    if (this->cycle % 17556 == 20) {
        return this->handle_inputs();
    } else {
        return true;
    }
}

bool Buttons::handle_inputs() {
    SDL_Event event;

    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            printf("Quitting\n");
            return false;
        }
        if(event.type == SDL_KEYDOWN) {
            if(event.key.keysym.sym == SDLK_ESCAPE) return false;
            if(event.key.keysym.sym == SDLK_LSHIFT) this->turbo = true;

            this->need_interrupt = true;
            switch (event.key.keysym.sym) {
                case SDLK_UP: this->up = true; break;
                case SDLK_DOWN: this->down = true; break;
                case SDLK_LEFT: this->left = true; break;
                case SDLK_RIGHT: this->right = true; break;
                case SDLK_z: this->b = true; break;
                case SDLK_x: this->a = true; break;
                case SDLK_RETURN: this->start = true; break;
                case SDLK_SPACE: this->select = true; break;
                default: this->need_interrupt = false; break;
            }
        }
        if(event.type == SDL_KEYUP) {
            if(event.key.keysym.sym == SDLK_LSHIFT) this->turbo = false;

            switch (event.key.keysym.sym) {
                case SDLK_UP: this->up = false; break;
                case SDLK_DOWN: this->down = false; break;
                case SDLK_LEFT: this->left = false; break;
                case SDLK_RIGHT: this->right = false; break;
                case SDLK_z: this->b = false; break;
                case SDLK_x: this->a = false; break;
                case SDLK_RETURN: this->start = false; break;
                case SDLK_SPACE: this->select = false; break;
            }
        }
    }

    return true;
}

void Buttons::update_buttons() {
    // Since the hardware uses 0 for pressed and 1 for
    // released, let's invert on read and write to keep
    // our logic sensible....
    u8 JOYP = this->cpu->ram->get(IO_JOYP);
    JOYP |= 0x0F;  // clear all buttons (0=pressed, 1=released)
    if(!(JOYP & JOYP_SELECT_DPAD)) {  // 0=select
        if(this->up) JOYP &= ~JOYP_UP;
        if(this->down) JOYP &= ~JOYP_DOWN;
        if(this->left) JOYP &= ~JOYP_LEFT;
        if(this->right) JOYP &= ~JOYP_RIGHT;
    }
    if(!(JOYP & JOYP_SELECT_BUTTONS)) {  // 0=select
        if(this->b) JOYP &= ~JOYP_B;
        if(this->a) JOYP &= ~JOYP_A;
        if(this->start) JOYP &= ~JOYP_START;
        if(this->select) JOYP &= ~JOYP_SELECT;
    }
    this->cpu->ram->set(IO_JOYP, JOYP);
}
