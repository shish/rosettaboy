<?php

class APU
{
    public function __construct(
        private bool $silent, // @phpstan-ignore-line
        private bool $debug  // @phpstan-ignore-line
    ) {
    }

    public function tick(): void
    {
        // FIXME: generate some sounds
    }
}
