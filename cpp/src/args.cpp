#include <iostream>

#include "args.h"

Args::Args(int argc, char *argv[]) {
    args::ArgumentParser parser("RosettaBoy - C++", "");
    args::HelpFlag help(parser, "help", "Display this help menu", {'h', "help"});
    args::Flag headless(parser, "headless", "Disable GUI", {'H', "headless"});
    args::Flag silent(parser, "silent", "Disable Sound", {'S', "silent"});
    args::Flag debug_cpu(parser, "debug-cpu", "Debug CPU", {'c', "debug-cpu"});
    args::Flag debug_gpu(parser, "debug-gpu", "Debug GPU", {'g', "debug-gpu"});
    args::Flag debug_apu(parser, "debug-apu", "Debug APU", {'a', "debug-apu"});
    args::ValueFlag<int> profile(parser, "profile", "Exit after N frames", {'p', "profile"});
    args::Flag turbo(parser, "turbo", "No sleep between frames", {'t', "turbo"});
    args::Positional<std::string> rom(parser, "rom", "Path to a .gb file");
    args::CompletionFlag completion(parser, {"complete"});

    try {
        parser.ParseCLI(argc, argv);
    } catch(args::Completion e) {
        std::cout << e.what();
        this->exit_code = 0;
        return;
    } catch(args::Help) {
        std::cout << parser;
        this->exit_code = 0;
        return;
    } catch(args::ParseError e) {
        std::cerr << e.what() << std::endl << parser;
        this->exit_code = 1;
        return;
    }

    this->headless = headless;
    this->silent = silent;
    this->debug_cpu = debug_cpu;
    this->debug_apu = debug_apu;
    this->debug_gpu = debug_gpu;
    this->profile = profile ? args::get(profile) : 0;
    this->turbo = turbo;
    this->rom = args::get(rom);
}