import sdl2

type
    GPU* = object
        cart_name: string
        headless: bool
        debug: bool
        cycle: int
        #[
        hw_renderer: Option<sdl2::render::Canvas<sdl2::video::Window>>,
        hw_buffer: Option<sdl2::render::Texture>,
        renderer: sdl2::render::Canvas<sdl2::surface::Surface<'a>>,
        colors: [Color; 4],
        bgp: [Color; 4],
        obp0: [Color; 4],
        obp1: [Color; 4],
        ]#

proc create*(cart_name: string, headless: bool, debug: bool): GPU =
    if not headless:
        discard sdl2.init(INIT_EVERYTHING)
        var
            window: WindowPtr
            render: RendererPtr

        window = createWindow("SDL Skeleton", 100, 100, 640,480, SDL_WINDOW_SHOWN)
        render = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)

        var
            evt = sdl2.defaultEvent
            runGame = true

        while runGame:
            while pollEvent(evt):
                if evt.kind == QuitEvent:
                    runGame = false
                    break

            render.setDrawColor 0,0,0,255
            render.clear
            render.present

        destroy render
        destroy window

    return GPU(
      cart_name: cart_name,
      headless: headless,
      debug: debug,
    )

# FIXME: implement this
proc tick*(gpu: GPU) =
    return
