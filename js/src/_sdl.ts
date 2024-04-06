var ref = require("ref-napi");
var ffi = require("ffi-napi");

export type SDL_Window = { on: CallableFunction };
export type SDL_Renderer = { };
export type SDL_Texture = { };
export type SDL_Surface = { };
export type SDL_Point = { x: number; y: number };
export type SDL_Rect = { x: number; y: number; w: number; h: number };
export type SDL_Color = { r: u8; g: u8; b: u8; a: u8 };

export type KeyUp = { key: string };
export type KeyDown = { key: string };
export type Window = {};

// c-types / c-pointers
export const ctSDL_Window = ref.types.void;
export const cpSDL_Window = ref.refType(ctSDL_Window);
export const ctSDL_Renderer = ref.types.void;
export const cpSDL_Renderer = ref.refType(ctSDL_Renderer);
export const ctSDL_Surface = ref.types.void;
export const cpSDL_Surface = ref.refType(ctSDL_Surface);
export const ctSDL_Texture = ref.types.void;
export const cpSDL_Texture = ref.refType(ctSDL_Texture);

const int = "int";
export const f = ffi.Library("libSDL2", {
    // SDL.h
    SDL_Init: [int, [int]],
    // SDL_video.h
    SDL_CreateWindow: [cpSDL_Window, ["string", int, int, int, int, int]],
    // SDL_hints.h
    SDL_SetHint: ["bool", ["string", "string"]],
    // SDL_render.h
    SDL_CreateRenderer: [cpSDL_Renderer, [cpSDL_Window, int, int]],
    SDL_RenderSetLogicalSize: [int, [cpSDL_Renderer, int, int]],
    SDL_CreateTexture: [cpSDL_Texture, [cpSDL_Renderer, int, int, int, int]],
    // SDL_surface.h
    SDL_CreateRGBSurface: [cpSDL_Surface, [int, int, int, int, int, int, int, int]],

    // SDL_error.h
    SDL_GetError: ["string", []],
});
f.SDL_WINDOWPOS_UNDEFINED = 0x1FFF0000;

// SDL.h
f.SDL_INIT_TIMER = 0x00000001;
f.SDL_INIT_AUDIO = 0x00000010;
f.SDL_INIT_VIDEO = 0x00000020; /**< SDL_INIT_VIDEO implies SDL_INIT_EVENTS */
f.SDL_INIT_JOYSTICK = 0x00000200; /**< SDL_INIT_JOYSTICK implies SDL_INIT_EVENTS */
f.SDL_INIT_HAPTIC = 0x00001000;
f.SDL_INIT_GAMECONTROLLER = 0x00002000; /**< SDL_INIT_GAMECONTROLLER implies SDL_INIT_JOYSTICK */
f.SDL_INIT_EVENTS = 0x00004000;
f.SDL_INIT_SENSOR = 0x00008000;
f.SDL_INIT_NOPARACHUTE = 0x00100000; /**< compatibility; this flag is ignored. */
f.SDL_INIT_EVERYTHING =
    f.SDL_INIT_TIMER |
    f.SDL_INIT_AUDIO |
    f.SDL_INIT_VIDEO |
    f.SDL_INIT_EVENTS |
    f.SDL_INIT_JOYSTICK |
    f.SDL_INIT_HAPTIC |
    f.SDL_INIT_GAMECONTROLLER |
    f.SDL_INIT_SENSOR;

// SDL_video.h
export enum SDL_WindowFlags {
    SDL_WINDOW_FULLSCREEN = 0x00000001,         /**< fullscreen window */
    SDL_WINDOW_OPENGL = 0x00000002,             /**< window usable with OpenGL context */
    SDL_WINDOW_SHOWN = 0x00000004,              /**< window is visible */
    SDL_WINDOW_HIDDEN = 0x00000008,             /**< window is not visible */
    SDL_WINDOW_BORDERLESS = 0x00000010,         /**< no window decoration */
    SDL_WINDOW_RESIZABLE = 0x00000020,          /**< window can be resized */
    SDL_WINDOW_MINIMIZED = 0x00000040,          /**< window is minimized */
    SDL_WINDOW_MAXIMIZED = 0x00000080,          /**< window is maximized */
    SDL_WINDOW_MOUSE_GRABBED = 0x00000100,      /**< window has grabbed mouse input */
    SDL_WINDOW_INPUT_FOCUS = 0x00000200,        /**< window has input focus */
    SDL_WINDOW_MOUSE_FOCUS = 0x00000400,        /**< window has mouse focus */
    SDL_WINDOW_FULLSCREEN_DESKTOP = ( SDL_WINDOW_FULLSCREEN | 0x00001000 ),
    SDL_WINDOW_FOREIGN = 0x00000800,            /**< window not created by SDL */
    SDL_WINDOW_ALLOW_HIGHDPI = 0x00002000,      /**< window should be created in high-DPI mode if supported.
                                                     On macOS NSHighResolutionCapable must be set true in the
                                                     application's Info.plist for this to have any effect. */
    SDL_WINDOW_MOUSE_CAPTURE    = 0x00004000,   /**< window has mouse captured (unrelated to MOUSE_GRABBED) */
    SDL_WINDOW_ALWAYS_ON_TOP    = 0x00008000,   /**< window should always be above others */
    SDL_WINDOW_SKIP_TASKBAR     = 0x00010000,   /**< window should not be added to the taskbar */
    SDL_WINDOW_UTILITY          = 0x00020000,   /**< window should be treated as a utility window */
    SDL_WINDOW_TOOLTIP          = 0x00040000,   /**< window should be treated as a tooltip */
    SDL_WINDOW_POPUP_MENU       = 0x00080000,   /**< window should be treated as a popup menu */
    SDL_WINDOW_KEYBOARD_GRABBED = 0x00100000,   /**< window has grabbed keyboard input */
    SDL_WINDOW_VULKAN           = 0x10000000,   /**< window usable for Vulkan surface */
    SDL_WINDOW_METAL            = 0x20000000,   /**< window usable for Metal view */

    SDL_WINDOW_INPUT_GRABBED = SDL_WINDOW_MOUSE_GRABBED /**< equivalent to SDL_WINDOW_MOUSE_GRABBED for compatibility */
};

// SDL_hints.h
f.SDL_HINT_RENDER_SCALE_QUALITY = "SDL_RENDER_SCALE_QUALITY";


/*
<?php

// Stubs until somebody makes a working SDL-PHP binding

const SDL_PIXELFORMAT_ABGR8888 = 5;
const SDL_TEXTUREACCESS_STREAMING = 6;

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
*/
