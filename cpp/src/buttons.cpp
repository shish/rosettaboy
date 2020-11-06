#include "buttons.h"

Buttons::Buttons(CPU *cpu) {
    SDL_InitSubSystem(SDL_INIT_EVENTS);
    this->cpu = cpu;
    this->cycle = 0;
}

bool Buttons::tick() {
    this->cycle++;
    this->update_buttons();
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
            // if(pressed[SDL_SCANCODE_D]) {this->cpu->stepping = true;}
        }
        if(event.type == SDL_KEYUP) {
            if(event.key.keysym.sym == SDLK_LSHIFT) this->turbo = false;
        }
    }

    // SDL_PumpEvents();  // SDL_PollEvent calls this already to the internal keymap
    pressed = SDL_GetKeyboardState(NULL);

    return true;
}

void Buttons::update_buttons() {
    if(pressed) {
        // handle SDL inputs every frame, but
        // handle button register every CPU
        // instruction
        u8 JOYP = this->cpu->ram->get(IO_JOYP);
        u8 prev_buttons = JOYP & (u8)0x0F;
        JOYP |= 0x0F; // clear all buttons (0=pressed, 1=released)
        if(!(JOYP & JOYP_SELECT_DPAD)) { // 0=select
            if(pressed[SDL_SCANCODE_UP]) JOYP &= ~JOYP_UP;
            if(pressed[SDL_SCANCODE_DOWN]) JOYP &= ~JOYP_DOWN;
            if(pressed[SDL_SCANCODE_LEFT]) JOYP &= ~JOYP_LEFT;
            if(pressed[SDL_SCANCODE_RIGHT]) JOYP &= ~JOYP_RIGHT;
        }
        if(!(JOYP & JOYP_SELECT_BUTTONS)) {  // 0=select
            if(pressed[SDL_SCANCODE_Z]) JOYP &= ~JOYP_B;
            if(pressed[SDL_SCANCODE_X]) JOYP &= ~JOYP_A;
            if(pressed[SDL_SCANCODE_RETURN]) JOYP &= ~JOYP_START;
            if(pressed[SDL_SCANCODE_SPACE]) JOYP &= ~JOYP_SELECT;
        }
        // if any button is pressed which wasn't pressed last time, interrupt
        if(~JOYP & 0x0F & ~prev_buttons) {
            this->cpu->stop = false;
            this->cpu->interrupt(INT_JOYPAD);
        }
        this->cpu->ram->set(IO_JOYP, JOYP);
    }
}
