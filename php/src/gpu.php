<?php

class GPU
{
    public function __construct(CPU $cpu, bool $debug, bool $headless)
    {
        $this->cpu = $cpu;
        $this->debug = $debug;
    }

    public function tick(): bool
    {
        // FIXME: implement graphics
        return true;
    }
}
