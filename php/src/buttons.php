<?php

require_once "consts.php";

class Joypad
{
    public static int $MODE_BUTTONS = 1 << 5;
    public static int $MODE_DPAD = 1 << 4;
    public static int $DOWN = 1 << 3;
    public static int $START = 1 << 3;
    public static int $UP = 1 << 2;
    public static int $SELECT = 1 << 2;
    public static int $LEFT = 1 << 1;
    public static int $B = 1 << 1;
    public static int $RIGHT = 1 << 0;
    public static int $A = 1 << 0;
}

class Buttons
{
    public bool $turbo;
    private CPU $cpu;
    private int $cycle;
    private bool $up;
    private bool $down;
    private bool $left;
    private bool $right;
    private bool $a;
    private bool $b;
    private bool $start;
    private bool $select;

    public function __construct(CPU $cpu, bool $headless)
    {
        if (!$headless) {
            SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER);
        }
        $this->turbo = false;
        $this->cpu = $cpu;
        $this->cycle = 0;

        $this->up = false;
        $this->down = false;
        $this->left = false;
        $this->right = false;
        $this->a = false;
        $this->b = false;
        $this->start = false;
        $this->select = false;
    }

    public function tick(): void
    {
        $this->cycle++;
        $this->update_buttons();
        if ($this->cycle % 17556 == 20) {
            if ($this->handle_inputs()) {
                $this->cpu->stop = false;
                $this->cpu->interrupt(Interrupt::JOYPAD);
            }
        }
    }

    public function update_buttons(): void
    {
        $JOYP = ~$this->cpu->ram->get(Mem::$JOYP);
        $JOYP &= 0x30;
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
        $this->cpu->ram->set(Mem::$JOYP, ~$JOYP & 0x3F);
    }

    public function handle_inputs(): bool
    {
        $need_interrupt = false;

        $event = new SDL_Event();
        while (SDL_PollEvent($event)) {
            if ($event->type == SDL_QUIT) {
                throw new Quit();
            }
            if ($event->type == SDL_KEYDOWN) {
                if ($event->key->keysym->sym == SDLK_ESCAPE) {
                    throw new Quit();
                }
                if ($event->key->keysym->sym == SDLK_LSHIFT) {
                    $this->turbo = true;
                }

                $need_interrupt = true;
                switch($event->key->keysym->sym) {
                    case SDLK_UP:
                        $this->up = true;
                        break;
                    case SDLK_DOWN:
                        $this->down = true;
                        break;
                    case SDLK_LEFT:
                        $this->left = true;
                        break;
                    case SDLK_RIGHT:
                        $this->right = true;
                        break;
                    case SDLK_z:
                        $this->b = true;
                        break;
                    case SDLK_x:
                        $this->a = true;
                        break;
                    case SDLK_RETURN:
                        $this->start = true;
                        break;
                    case SDLK_SPACE:
                        $this->select = true;
                        break;
                    default:
                        $need_interrupt = false;
                        break;
                }
            }
            if ($event->type == SDL_KEYUP) {
                if ($event->key->keysym->sym == SDLK_LSHIFT) {
                    $this->turbo = false;
                }

                switch($event->key->keysym->sym) {
                    case SDLK_UP:
                        $this->up = false;
                        break;
                    case SDLK_DOWN:
                        $this->down = false;
                        break;
                    case SDLK_LEFT:
                        $this->left = false;
                        break;
                    case SDLK_RIGHT:
                        $this->right = false;
                        break;
                    case SDLK_z:
                        $this->b = false;
                        break;
                    case SDLK_x:
                        $this->a = false;
                        break;
                    case SDLK_RETURN:
                        $this->start = false;
                        break;
                    case SDLK_SPACE:
                        $this->select = false;
                        break;
                }
            }
        }

        return $need_interrupt;
    }
}
