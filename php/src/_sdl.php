<?php

declare(strict_types=1);

// Stubs until somebody makes a working SDL-PHP binding

const SDL_INIT_VIDEO = 1;
const SDL_WINDOWPOS_UNDEFINED = 2;
const SDL_WINDOW_ALLOW_HIGHDPI = 3;
const SDL_WINDOW_RESIZABLE = 4;
const SDL_HINT_RENDER_SCALE_QUALITY = "RENDER_SCALE_QUALITY";
const SDL_PIXELFORMAT_ABGR8888 = 5;
const SDL_TEXTUREACCESS_STREAMING = 6;
const SDL_INIT_GAMECONTROLLER = 7;

const SDL_QUIT = 100;
const SDL_KEYUP = 101;
const SDL_KEYDOWN = 102;

const SDLK_ESCAPE = 202;
const SDLK_LSHIFT = 203;
const SDLK_UP = 204;
const SDLK_DOWN = 205;
const SDLK_LEFT = 206;
const SDLK_RIGHT = 207;
const SDLK_z = 208;
const SDLK_x = 209;
const SDLK_RETURN = 210;
const SDLK_SPACE = 211;

function SDL_CreateRGBSurface(...$x): SDL_Surface
{
    return new SDL_Surface();
}

function SDL_SetRenderDrawColor(...$x)
{
}

function SDL_RenderClear(...$x)
{
}

function SDL_UpdateTexture(...$x)
{
}

function SDL_RenderCopy(...$x)
{
}

function SDL_RenderPresent(...$x)
{
}

function SDL_RenderDrawRect(...$x)
{
}

function SDL_RenderDrawPoint(...$x)
{
}

function SDL_RenderFillRect(...$x)
{
}

function SDL_InitSubSystem(...$x)
{
}

function SDL_CreateWindow(...$x)
{
}

function SDL_CreateRenderer(...$x)
{
}

function SDL_CreateSoftwareRenderer(...$x)
{
}

function SDL_CreateTexture(...$x)
{
}

function SDL_SetHint(...$x)
{
}

function SDL_RenderSetLogicalSize(...$x)
{
}

function SDL_PollEvent(...$x)
{
}

class SDL_Event
{
    public int $type;

    public function __construct()
    {
    }
}

class SDL_Surface
{
    public int $pixels;
    public int $pitch;

    public function __construct()
    {
    }
}

class SDL_Point
{
    public function __construct(
        public int $x,
        public int $y,
    ) {
    }
}

class SDL_Rect
{
    public function __construct(
        public int $x,
        public int $y,
        public int $w,
        public int $h,
    ) {
    }
}

class SDL_Color
{
    public function __construct(
        public int $r,
        public int $g,
        public int $b,
        public int $a,
    ) {
    }
}
