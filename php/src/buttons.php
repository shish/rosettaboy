<?php

require_once "consts.php";

class Joypad
{
    public static $MODE_BUTTONS = 1 << 5;
    public static $MODE_DPAD = 1 << 4;
    public static $DOWN = 1 << 3;
    public static $START = 1 << 3;
    public static $UP = 1 << 2;
    public static $SELECT = 1 << 2;
    public static $LEFT = 1 << 1;
    public static $B = 1 << 1;
    public static $RIGHT = 1 << 0;
    public static $A = 1 << 0;
}

class Buttons
{
    public function __construct(CPU $cpu, bool $headless)
    {
        // FIXME: SDL_InitSubSystem(SDL_INIT_EVENTS);
        $this->turbo = false;
        $this->cpu = $cpu;
        $this->cycle = 0;
        $this->headless = $headless;
        $this->need_interrupt = false;

        $this->up = false;
        $this->down = false;
        $this->left = false;
        $this->right = false;
        $this->a = false;
        $this->b = false;
        $this->start = false;
        $this->select = false;
    }

    public function tick(): bool
    {
        $this->cycle++;
        $this->update_buttons();
        if ($this->need_interrupt) {
            $this->cpu->stop = false;
            $this->cpu->interrupt(Interrupt::$JOYPAD);
            $this->need_interrupt = false;
        }
        if ($this->cycle % 17556 == 20) {
            return $this->handle_inputs();
        } else {
            return true;
        }
    }

    public function update_buttons(): void
    {
        $JOYP = ~$this->cpu->ram->get(Mem::$JOYP);
        $JOYP &= 0xF0;
        if ($JOYP & Joypad::$MODE_DPAD) {
            if ($this->up) {
                $JOYP |= Joypad::$UP;
            }
            if ($this->down) {
                $JOYP |= Joypad::$DOWN;
            }
            if ($this->left) {
                $JOYP |= Joypad::$LEFT;
            }
            if ($this->right) {
                $JOYP |= Joypad::$RIGHT;
            }
        }
        if ($JOYP & Joypad::$MODE_BUTTONS) {
            if ($this->b) {
                $JOYP |= Joypad::$B;
            }
            if ($this->a) {
                $JOYP |= Joypad::$A;
            }
            if ($this->start) {
                $JOYP |= Joypad::$START;
            }
            if ($this->select) {
                $JOYP |= Joypad::$SELECT;
            }
        }
        $this->cpu->ram->set(Mem::$JOYP, ~$JOYP);
    }

    public function handle_inputs(): bool
    {
        if ($this->headless) {
            return true;
        }

        /*
        // FIXME
        SDL_Event event;
        while(SDL_PollEvent(&event)) {
            if(event.type == SDL_QUIT) {
                return false;
            }
            if(event.type == SDL_KEYDOWN) {
                if(event.key.keysym.sym == SDLK_ESCAPE) return false;
                if(event.key.keysym.sym == SDLK_LSHIFT) this->turbo = true;

                this->need_interrupt = true;
                switch(event.key.keysym.sym) {
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

                switch(event.key.keysym.sym) {
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
        */
        return true;
    }
}
