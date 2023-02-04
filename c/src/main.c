#include "args.h"
#include "errors.h"
#include "gameboy.h"

int main(int argc, char *argv[]) {
    struct Args args;

    parse_args(&args, argc, argv);

    if (args.exit_code > 0) {
        return args.exit_code;
    }

    struct GameBoy gameboy = {0};
    gameboy_ctor(&gameboy, &args);
    gameboy_run(&gameboy);
    gameboy_dtor(&gameboy);

    printf("\n");
    return 0;
}
