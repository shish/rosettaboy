<?php

declare(strict_types=1);

// Controlled Exits
class ControlledExit extends Exception
{
}

class Quit extends ControlledExit
{
}

class Timeout extends ControlledExit
{
    public function __construct(private int $frames, private float $duration)
    {
    }

    public function __toString(): string
    {
        return sprintf("Emulated %5d frames in %5.2fs (%.0ffps)", $this->frames, $this->duration, $this->frames / $this->duration);
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
    public function __construct(private int $opcode)
    {
    }

    public function __toString(): string
    {
        return sprintf("Invalid OpCode: 0x%02X", $this->opcode);
    }
}

// User Errors
class UserException extends Exception
{
}
class UnsupportedCart extends UserException
{
    public function __construct(private int $cart_type)
    {
    }

    public function __toString(): string
    {
        return sprintf("Unsupported cart type: 0x%02X", $this->cart_type);
    }
}

class LogoChecksumFailed extends UserException
{
    public function __construct(private int $logo_checksum)
    {
    }

    public function __toString(): string
    {
        return sprintf("Logo checksum failed: %04X", $this->logo_checksum);
    }
}

class HeaderChecksumFailed extends UserException
{
    public function __construct(private int $header_checksum)
    {
    }

    public function __toString(): string
    {
        return sprintf("Header checksum failed: %04X", $this->header_checksum);
    }
}
