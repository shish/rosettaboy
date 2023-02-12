<?php

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
EOF;

    public static function parse(array $argv): self
    {
        $rest_index = null;
        /** @var array<string, mixed> $opts */
        $opts = getopt("cgraHStf:p:h", ["debug-cpu", "debug-gpu", "debug-ram", "debug-apu", "headless", "silent", "turbo", "frames:", "profile:", "help"], $rest_index) ?: [];
        $pos_args = array_slice($argv, $rest_index);

        $opts = array_combine(
            array_map(function (string $k) {
                return str_replace('-', '_', self::SHORT_LONG_MAP[$k] ?? $k);
            }, array_keys($opts)),
            array_map(function (mixed $v) {
                return $v === false ? true : $v;
            }, array_values($opts))
        );

        if (isset($opts['help']) || count($pos_args) === 0) {
            echo self::USAGE;
            exit(0);
        }

        return new self($pos_args[0], ...$opts);
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
