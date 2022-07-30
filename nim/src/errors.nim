
type ControlledExit* = object of CatchableError
type Quit* = object of ControlledExit
type Timeout* = object of ControlledExit
type UnitTestPassed* = object of ControlledExit
type UnitTestFailed* = object of ControlledExit

type GameException* = object of CatchableError
type InvalidOpcode* = object of GameException
type InvalidRamRead* = object of GameException
type InvalidRamWrite* = object of GameException

type UserException* = object of CatchableError
type RomMissing* = object of UserException
type LogoChecksumFailed* = object of UserException
type HeaderChecksumFailed* = object of UserException
