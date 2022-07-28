#[derive(Debug)]
pub enum EmuError {
    Quit,
    Timeout(u32, f32),
    UnsupportedCart(crate::cart::CartType),
    LogoChecksumFailed(u16),
    HeaderChecksumFailed(u16),
    UnitTestPassed,
    UnitTestFailed,
    InvalidOpcode(u8),
}

impl EmuError {
    pub fn exit_code(&self) -> i32 {
        match self {
            EmuError::Quit => 0,
            EmuError::Timeout(_, _) => 0,
            EmuError::UnsupportedCart(_) => 1,
            EmuError::LogoChecksumFailed(_) => 1,
            EmuError::HeaderChecksumFailed(_) => 1,
            EmuError::UnitTestPassed => 0,
            EmuError::UnitTestFailed => 2,
            EmuError::InvalidOpcode(_) => 1,
        }
    }
}
impl std::error::Error for EmuError {}
impl std::fmt::Display for EmuError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            EmuError::Timeout(frames, duration) => write!(
                f,
                "Emulated {} frames in {:5.2}s ({:.0}fps)",
                frames,
                duration,
                *frames as f32 / duration
            ),
            EmuError::UnsupportedCart(cart_type) => {
                write!(f, "Unsupported cart type: {:?}", cart_type)
            }
            EmuError::InvalidOpcode(opcode) => write!(f, "Invalid Opcode: {}", opcode),
            EmuError::UnitTestPassed => write!(f, "Unit test passed"),
            EmuError::UnitTestFailed => write!(f, "Unit test failed"),
            _ => write!(f, "Error: {:?}", self),
        }
    }
}
