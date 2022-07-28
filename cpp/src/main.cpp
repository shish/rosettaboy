#include <iostream>

#include "args.h"
#include "gameboy.h"
#include "errors.h"

int main(int argc, char *argv[]) {
    Args *args = new Args(argc, argv);
    if(args->exit_code >= 0) {
        return args->exit_code;
    }

    try {
        GameBoy *gameboy = new GameBoy(args); 
        gameboy->run();
    } catch(EmuException *e) {
        std::cout << e->what() << std::endl;
        return e->exit_code;
    }

    printf("\n");
    return 0;
}
