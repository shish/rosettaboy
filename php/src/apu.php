<?php

class APU {
    function __construct(bool $silent, bool $debug) {
        $this->silent = $silent;
        $this->debug = $debug;
    }

    function tick(): bool {
        // FIXME: generate some sounds
        return true;
    }
}
