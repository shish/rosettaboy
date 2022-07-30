import args
import gameboy

when isMainModule:
    const args_obj = args.parse_args()
    var gameboy_obj = gameboy.create(args_obj)
    gameboy_obj.run()
