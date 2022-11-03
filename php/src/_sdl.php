<?php

// Stubs until somebody makes a working SDL-PHP binding

const SDL_INIT_VIDEO = 1;
const SDL_WINDOWPOS_UNDEFINED = 2;
const SDL_WINDOW_ALLOW_HIGHDPI = 3;
const SDL_WINDOW_RESIZABLE = 4;
const SDL_HINT_RENDER_SCALE_QUALITY = "RENDER_SCALE_QUALITY";
const SDL_PIXELFORMAT_ABGR8888 = 5;
const SDL_TEXTUREACCESS_STREAMING = 6;
const SDL_INIT_GAMECONTROLLER = 7;

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
