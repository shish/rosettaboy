pub const ControlledExit = error{
    Quit,
    Help,
    Timeout,
    UnitTestPassed,
    UnitTestFailed,
};
pub const GameException = error{
    InvalidOpcode,
    InvalidRamRead,
    InvalidRamWrite,
};
pub const UserException = error{
    RomMissing,
    LogoChecksumFailed,
    HeaderChecksumFailed,
};
