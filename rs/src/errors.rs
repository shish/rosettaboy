#[derive(Debug)]
pub enum ControlledExit {
    Quit,
    Timeout(u32, f32),
    UnitTestPassed,
    UnitTestFailed,
}
impl std::error::Error for ControlledExit {}
impl std::fmt::Display for ControlledExit {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            ControlledExit::Timeout(frames, duration) => write!(
                f,
                "Emulated {} frames in {:5.2}s ({:.0}fps)",
                frames,
                duration,
                *frames as f32 / duration
            ),
            ControlledExit::UnitTestPassed => write!(f, "Unit test passed"),
            ControlledExit::UnitTestFailed => write!(f, "Unit test failed"),
            _ => write!(f, "Quit for unspecified reason: {:?}", self),
        }
    }
}

#[derive(Debug)]
pub enum GameException {
    InvalidOpcode(u8),
}
impl std::error::Error for GameException {}
impl std::fmt::Display for GameException {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            GameException::InvalidOpcode(opcode) => write!(f, "Invalid Opcode: {}", opcode),
            // _ => write!(f, "Unspecified game error: {:?}", self),
        }
    }
}

#[derive(Debug)]
pub enum UserException {
    UnsupportedCart(crate::cart::CartType),
    LogoChecksumFailed(u16),
    HeaderChecksumFailed(u16),
}
impl std::error::Error for UserException {}
impl std::fmt::Display for UserException {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            UserException::UnsupportedCart(cart_type) => {
                write!(f, "Unsupported cart type: {:?}", cart_type)
            }
            _ => write!(f, "Unspecified user error: {:?}", self),
        }
    }
}
