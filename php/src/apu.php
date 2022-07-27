<?php

class APU
{
    private bool $silent;
    private bool $debug;

    public function __construct(bool $silent, bool $debug)
    {
        $this->silent = $silent;
        $this->debug = $debug;
    }

    public function tick(): void
    {
        // FIXME: generate some sounds
    }
}
