<?php

// Controlled Exits
class ControlledExit extends Exception
{
}

class Quit extends ControlledExit
{
}

class Timeout extends ControlledExit
{
    public function __construct(int $frames, float $duration)
    {
        $this->frames = $frames;
        $this->duration = $duration;
    }

    public function __toString(): string
    {
        return sprintf("Emulated %d frames in %5.2fs (%.0ffps)\n", $this->frames, $this->duration, $this->frames / $this->duration);
    }
}

class UnitTestPassed extends ControlledExit
{
}

class UnitTestFailed extends ControlledExit
{
}

// Game Errors
class GameException extends Exception
{
}
class InvalidOpcode extends GameException
{
    public function __construct($opcode)
    {
        $this->opcode = $opcode;
    }
}

// User Errors
class UserException extends Exception
{
}
class UnsupportedCart extends UserException
{
    public function __construct($cart_type)
    {
        $this->cart_type = $cart_type;
    }
}

class LogoChecksumFailed extends UserException
{
    public function __construct($logo_checksum)
    {
        $this->logo_checksum = $logo_checksum;
    }
}

class HeaderChecksumFailed extends UserException
{
    public function __construct($header_checksum)
    {
        $this->header_checksum = $header_checksum;
    }
}
