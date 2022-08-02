import system
import os

import args
import gameboy
import errors

when isMainModule:
    try:
        let args_obj = args.parse_args(commandLineParams())
        var gameboy_obj = gameboy.create(args_obj)
        gameboy_obj.run()
    except errors.UnitTestFailed as e:
        echo e.msg
        system.quit(2)
    except errors.ControlledExit as e:
        echo e.msg
        system.quit(0)
    except errors.GameException as e:
        echo e.msg
        system.quit(3)
    except errors.UserException as e:
        echo e.msg
        system.quit(4)
