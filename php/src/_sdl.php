<?php

// Stubs until somebody makes a working SDL-PHP binding

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

class SDL_Point
{
    public int $x;
    public int $y;

    public function __construct(int $x, int $y)
    {
        $this->x = $x;
        $this->y = $y;
    }
}

class SDL_Rect
{
    public int $x;
    public int $y;
    public int $w;
    public int $h;

    public function __construct(int $x, int $y, int $w, int $h)
    {
        $this->x = $x;
        $this->y = $y;
        $this->w = $w;
        $this->h = $h;
    }
}

class SDL_Color
{
    public int $a;
    public int $b;
    public int $g;
    public int $r;

    public function __construct(int $r, int $g, int $b, int $a)
    {
        $this->r = $r;
        $this->g = $g;
        $this->b = $b;
        $this->a = $a;
    }
}
