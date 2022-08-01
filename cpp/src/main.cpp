#include "args.h"
#include "errors.h"
#include "gameboy.h"
#include <iostream>

int main(int argc, char *argv[]) {
    Args *args = new Args(argc, argv);
    if(args->exit_code >= 0) {
        return args->exit_code;
    }

    try {
        GameBoy *gameboy = new GameBoy(args);
        gameboy->run();
    } catch(UnitTestFailed *e) {
        std::cout << e->what() << std::endl;
        return 2;
    } catch(ControlledExit *e) {
        std::cout << e->what() << std::endl;
        return 0;
    } catch(GameException *e) {
        std::cout << e->what() << std::endl;
        return 3;
    } catch(UserException *e) {
        std::cout << e->what() << std::endl;
        return 4;
    }

    printf("\n");
    return 0;
}
