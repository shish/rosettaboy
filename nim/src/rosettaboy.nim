import args
import gameboy
import system
import errors

when isMainModule:
    try:
        const args_obj = args.parse_args()
        var gameboy_obj = gameboy.create(args_obj)
        gameboy_obj.run()
    except errors.Timeout as e:
        echo e.msg
        system.quit(0)
