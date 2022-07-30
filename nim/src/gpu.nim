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
    return GPU(
      cart_name: cart_name,
      headless: headless,
      debug: debug,
    )

# FIXME: implement this
proc tick*(gpu: GPU) =
    return
