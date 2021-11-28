<?php

class CPU {
    function __construct(RAM $ram, bool $debug) {
        $this->ram = $ram;
        $this->debug = $debug;
    }

    function tick(): bool {
        return true;
    }
}
