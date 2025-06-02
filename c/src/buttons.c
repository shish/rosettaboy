#include "buttons.h"
#include "cpu.h"
#include "errors.h"
#include "ram.h"

static const u8 JOYPAD_MODE_BUTTONS = 1 << 5;
static const u8 JOYPAD_MODE_DPAD = 1 << 4;
static const u8 JOYPAD_DOWN = 1 << 3;
static const u8 JOYPAD_START = 1 << 3;
static const u8 JOYPAD_UP = 1 << 2;
static const u8 JOYPAD_SELECT = 1 << 2;
static const u8 JOYPAD_LEFT = 1 << 1;
static const u8 JOYPAD_B = 1 << 1;
static const u8 JOYPAD_RIGHT = 1 << 0;
static const u8 JOYPAD_A = 1 << 0;

static bool handle_inputs(struct Buttons *self);
static void update_buttons(struct Buttons *self);

void buttons_ctor(struct Buttons *self, struct CPU *cpu, struct RAM *ram, bool headless) {
    if (!headless) {
        SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER);
    }

    *self = (struct Buttons){
        .cpu = cpu,
        .ram = ram,
        .cycle = 0,
        .up = false,
        .down = false,
        .left = false,
        .right = false,
        .a = false,
        .b = false,
        .start = false,
        .select = false,
        .turbo = false,
    };
}

void buttons_tick(struct Buttons *self) {
    self->cycle++;
    update_buttons(self);
    if (self->cycle % 17556 == 20) {
        if (handle_inputs(self)) {
            cpu_stop(self->cpu, false);
            cpu_interrupt(self->cpu, INTERRUPT_JOYPAD);
        }
    }
}

static void update_buttons(struct Buttons *self) {
    u8 JOYP = ~ram_get(self->ram, MEM_JOYP);
    JOYP &= 0x30;
    if (JOYP & JOYPAD_MODE_DPAD) {
        if (self->up)
            JOYP |= JOYPAD_UP;
        if (self->down)
            JOYP |= JOYPAD_DOWN;
        if (self->left)
            JOYP |= JOYPAD_LEFT;
        if (self->right)
            JOYP |= JOYPAD_RIGHT;
    }
    if (JOYP & JOYPAD_MODE_BUTTONS) {
        if (self->b)
            JOYP |= JOYPAD_B;
        if (self->a)
            JOYP |= JOYPAD_A;
        if (self->start)
            JOYP |= JOYPAD_START;
        if (self->select)
            JOYP |= JOYPAD_SELECT;
    }
    ram_set(self->ram, MEM_JOYP, ~JOYP & 0x3F);
}

static bool handle_inputs(struct Buttons *self) {
    bool need_interrupt = false;

    SDL_Event event;

    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            quit_emulator();
        }
        if (event.type == SDL_KEYDOWN) {
            need_interrupt = true;
            switch (event.key.keysym.sym) {
                case SDLK_ESCAPE:
                    quit_emulator();
                case SDLK_LSHIFT:
                    self->turbo = true;
                    need_interrupt = false;
                    break;
                case SDLK_UP:
                    self->up = true;
                    break;
                case SDLK_DOWN:
                    self->down = true;
                    break;
                case SDLK_LEFT:
                    self->left = true;
                    break;
                case SDLK_RIGHT:
                    self->right = true;
                    break;
                case SDLK_z:
                    self->b = true;
                    break;
                case SDLK_x:
                    self->a = true;
                    break;
                case SDLK_RETURN:
                    self->start = true;
                    break;
                case SDLK_SPACE:
                    self->select = true;
                    break;
                default:
                    need_interrupt = false;
                    break;
            }
        }
        if (event.type == SDL_KEYUP) {
            switch (event.key.keysym.sym) {
                case SDLK_LSHIFT:
                    self->turbo = false;
                    break;
                case SDLK_UP:
                    self->up = false;
                    break;
                case SDLK_DOWN:
                    self->down = false;
                    break;
                case SDLK_LEFT:
                    self->left = false;
                    break;
                case SDLK_RIGHT:
                    self->right = false;
                    break;
                case SDLK_z:
                    self->b = false;
                    break;
                case SDLK_x:
                    self->a = false;
                    break;
                case SDLK_RETURN:
                    self->start = false;
                    break;
                case SDLK_SPACE:
                    self->select = false;
                    break;
            }
        }
    }

    return need_interrupt;
}
