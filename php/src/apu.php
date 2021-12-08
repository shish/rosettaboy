<?php

class APU
{
    public function __construct(bool $silent, bool $debug)
    {
        $this->silent = $silent;
        $this->debug = $debug;
    }

    public function tick(): bool
    {
        // FIXME: generate some sounds
        return true;
    }
}
