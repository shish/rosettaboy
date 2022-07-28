<?php

class EmuError extends Exception
{
    public function __construct()
    {
        $this->exit_code = 1;
    }
}

class Quit extends EmuError
{
    public function __construct()
    {
        $this->exit_code = 0;
    }
}

class Timeout extends EmuError
{
    public function __construct(int $frames, float $duration)
    {
        $this->exit_code = 0;
        $this->frames = $frames;
        $this->duration = $duration;
    }

    public function __toString(): string
    {
        return sprintf("Emulated %d frames in %5.2fs (%.0ffps)\n", $this->frames, $this->duration, $this->frames / $this->duration);
    }
}

class UnsupportedCart extends EmuError
{
    public function __construct($cart_type)
    {
        $this->cart_type = $cart_type;
    }
}

class LogoChecksumFailed extends EmuError
{
    public function __construct($logo_checksum)
    {
        $this->logo_checksum = $logo_checksum;
    }
}

class HeaderChecksumFailed extends EmuError
{
    public function __construct($header_checksum)
    {
        $this->header_checksum = $header_checksum;
    }
}

class UnitTestPassed extends EmuError
{
    public function __construct()
    {
        $this->exit_code = 0;
    }
}

class UnitTestFailed extends EmuError
{
    public function __construct()
    {
        $this->exit_code = 2;
    }
}

class InvalidOpcode extends EmuError
{
    public function __construct($opcode)
    {
        $this->opcode = $opcode;
    }
}
