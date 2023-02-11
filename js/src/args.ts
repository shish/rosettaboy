import { Command, InvalidArgumentError } from "commander";

function myParseInt(value: string, dummyPrevious: number): number {
    const parsedValue = parseInt(value, 10);
    if (isNaN(parsedValue)) {
        throw new InvalidArgumentError("Not a number.");
    }
    return parsedValue;
}

export function parse_args(argv: Array<string>) {
    const program = new Command();
    program
        .version("0.0.0")
        .description("A gameboy emulator in many languages, javascript edition")
        .option("-c, --debug-cpu", "Debug CPU")
        .option("-g, --debug-gpu", "Debug GPU")
        .option("-r, --debug-ram", "Debug RAM")
        .option("-H, --headless", "Disable GUI")
        .option("-S, --silent", "Disable Sound")
        .option("-t, --turbo", "No sleep()")
        .option("-f, --frames <n>", "Exit after this many frames", myParseInt)
        .option("-p, --profile <n>", "Exit after this many seconds", myParseInt)
        .argument("rom", "path to .gb file");

    let parsed = program.parse(argv);
    let args = parsed.opts();
    args.rom = parsed.args[0];
    return args;
}
