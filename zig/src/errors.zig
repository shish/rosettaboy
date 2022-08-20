const ControlledExit = error{
    Quit,
    Timeout,
    UnitTestPassed,
    UnitTestFailed,
};
const GameException = error{
    InvalidOpcode,
    InvalidRamRead,
    InvalidRamWrite,
};
const UserException = error{
    RomMissing,
    LogoChecksumFailed,
    HeaderChecksumFailed,
};
