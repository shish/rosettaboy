<?php

declare(strict_types=1);

final class Args
{
    private const SHORT_LONG_MAP = [
        'h' => 'help',
        'c' => 'debug-cpu',
        'g' => 'debug-gpu',
        'r' => 'debug-ram',
        'a' => 'debug-apu',
        'H' => 'headless',
        'S' => 'silent',
        't' => 'turbo',
        'f' => 'frames',
        'p' => 'profile',
        'v' => 'version',
    ];

    private const USAGE = <<<EOF
Usage: rosettaboy-php [OPTION]... [ROM]
Example: rosettaboy-php --turbo opus5.gb

Options:
  -h, --help              Display this help menu
  -H, --headless          Disable GUI
  -S, --silent            Disable Sound
  -c, --debug-cpu         Debug CPU
  -g, --debug-gpu         Debug GPU
  -a, --debug-apu         Debug APU
  -r, --debug-ram         Debug RAM
  -f, --frames=FRAMES     Exit after N frames
  -p, --profile=PROFILE   Exit after N seconds
  -t, --turbo             No sleep between frames
  -v, --version           Show build info
EOF;

    /**
     * @param string[] $argv The command line arguments.
     */
    public static function parse(array $argv): self
    {
        $rest_index = null;
        $opts = getopt("cgraHStf:p:hv", ["debug-cpu", "debug-gpu", "debug-ram", "debug-apu", "headless", "silent", "turbo", "frames:", "profile:", "help", "version"], $rest_index) ?: [];
        $pos_args = array_slice($argv, $rest_index);

        if (isset($opts['version'])) {
            echo phpversion() . "\n";
            exit(0);
        }
        if (isset($opts['help']) || count($pos_args) === 0) {
            echo self::USAGE . "\n";
            exit(0);
        }

        // @phpstan-ignore-next-line
        return new self(
            rom: $pos_args[0],
            profile: (int)($opts['profile'] ?? $opts["p"] ?? 0),
            frames: (int)($opts['frames'] ?? $opts["f"] ?? 0),
            turbo: isset($opts['turbo']) || isset($opts["t"]),
            silent: isset($opts['silent']) || isset($opts["S"]),
            headless: isset($opts['headless']) || isset($opts["H"]),
            debug_apu: isset($opts['debug-apu']) || isset($opts["a"]),
            debug_ram: isset($opts['debug-ram']) || isset($opts["r"]),
            debug_gpu: isset($opts['debug-gpu']) || isset($opts["g"]),
            debug_cpu: isset($opts['debug-cpu']) || isset($opts["c"])
        );
    }

    public function __construct(
        public readonly string $rom,
        public readonly int $profile = 0,
        public readonly int $frames = 0,
        public readonly bool $turbo = false,
        public readonly bool $silent = false,
        public readonly bool $headless = false,
        public readonly bool $debug_apu = false,
        public readonly bool $debug_ram = false,
        public readonly bool $debug_gpu = false,
        public readonly bool $debug_cpu = false
    ) {
    }
}
