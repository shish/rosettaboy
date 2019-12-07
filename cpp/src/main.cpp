#include <iostream>

#include "args.h"

#include "cart.h"
#include "cpu.h"
#include "gpu.h"
#include "buttons.h"
#include "apu.h"
#include "clock.h"

using namespace std;

int main(int argc, char *argv[]) {
    args::ArgumentParser parser("Shish's no-longer PYthon GamebOy emulaTor", "");
    args::HelpFlag help(parser, "help", "Display this help menu", {'h', "help"});
    args::Flag headless(parser, "headless", "Disable GUI", {'H', "headless"});
    args::Flag silent(parser, "silent", "Disable Sound", {'S', "silent"});
    args::Flag debug_cpu(parser, "debug-cpu", "Debug CPU", {'c', "debug-cpu"});
    args::Flag debug_gpu(parser, "debug-gpu", "Debug GPU", {'g', "debug-gpu"});
    args::Flag debug_apu(parser, "debug-apu", "Debug APU", {'a', "debug-apu"});
    args::Flag profile(parser, "profile", "Exit after some instructions", {'p', "profile"});
    args::Flag turbo(parser, "turbo", "No sleep between frames", {'t', "turbo"});
    args::Positional<std::string> rom(parser, "rom", "Path to a .gb file");
    args::CompletionFlag completion(parser, {"complete"});
    try { parser.ParseCLI(argc, argv); }
    catch (args::Completion e) { std::cout << e.what(); return 0; }
    catch (args::Help) { std::cout << parser; return 0; }
    catch (args::ParseError e) { std::cerr << e.what() << std::endl << parser; return 1; }

    Cart *cart = nullptr;
    RAM *ram = nullptr;
    CPU *cpu = nullptr;
    GPU *io = nullptr;
    Buttons *buttons = nullptr;
    Clock *clock = nullptr;

    cart = new Cart(args::get(rom).c_str());
    ram = new RAM(cart);
    cpu = new CPU(ram, debug_cpu);
    io = new GPU(cpu, headless, debug_gpu);
    buttons = new Buttons(cpu);
    if(!silent) new APU(cpu, debug_apu);
    clock = new Clock(buttons, profile, turbo);

    while(true) {
        if(!cpu->tick()) break;
        if(!io->tick()) break;
        if(!buttons->tick()) break;
        if(!clock->tick()) break;
    }

    printf("\n");
    return cpu->A;
}
