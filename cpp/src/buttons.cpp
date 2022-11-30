#include "buttons.h"
#include "errors.h"

Buttons::Buttons(CPU *cpu, bool headless) {
    if(!headless) SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER);
    this->cpu = cpu;
    this->cycle = 0;
}

void Buttons::tick() {
    this->cycle++;
    this->update_buttons();
    if(this->cycle % 17556 == 20) {
        if(this->handle_inputs()) {
            this->cpu->stop = false;
            this->cpu->interrupt(Interrupt::JOYPAD);
        }
    }
}

void Buttons::update_buttons() {
    u8 JOYP = ~this->cpu->ram->get(Mem::JOYP);
    JOYP &= 0x30;
    if(JOYP & Joypad::MODE_DPAD) {
        if(this->up) JOYP |= Joypad::UP;
        if(this->down) JOYP |= Joypad::DOWN;
        if(this->left) JOYP |= Joypad::LEFT;
        if(this->right) JOYP |= Joypad::RIGHT;
    }
    if(JOYP & Joypad::MODE_BUTTONS) {
        if(this->b) JOYP |= Joypad::B;
        if(this->a) JOYP |= Joypad::A;
        if(this->start) JOYP |= Joypad::START;
        if(this->select) JOYP |= Joypad::SELECT;
    }
    this->cpu->ram->set(Mem::JOYP, ~JOYP & 0x3F);
}

bool Buttons::handle_inputs() {
    bool need_interrupt = false;

    SDL_Event event;

    while(SDL_PollEvent(&event)) {
        if(event.type == SDL_QUIT) {
            throw new Quit();
        }
        if(event.type == SDL_KEYDOWN) {
            need_interrupt = true;
            switch(event.key.keysym.sym) {
                case SDLK_ESCAPE: throw new Quit();
                case SDLK_LSHIFT:
                    this->turbo = true;
                    need_interrupt = false;
                    break;
                case SDLK_UP: this->up = true; break;
                case SDLK_DOWN: this->down = true; break;
                case SDLK_LEFT: this->left = true; break;
                case SDLK_RIGHT: this->right = true; break;
                case SDLK_z: this->b = true; break;
                case SDLK_x: this->a = true; break;
                case SDLK_RETURN: this->start = true; break;
                case SDLK_SPACE: this->select = true; break;
                default: need_interrupt = false; break;
            }
        }
        if(event.type == SDL_KEYUP) {
            switch(event.key.keysym.sym) {
                case SDLK_LSHIFT: this->turbo = false; break;
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

    return need_interrupt;
}
