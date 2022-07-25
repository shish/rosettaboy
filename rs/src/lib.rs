#![allow(clippy::needless_return)]
#![allow(clippy::identity_op)]
#![allow(clippy::upper_case_acronyms)]
#![allow(clippy::many_single_char_names)]

#[macro_use]
extern crate bitflags;

mod apu;
pub mod args;
mod buttons;
mod cart;
mod clock;
mod consts;
mod cpu;
mod errors;
pub mod gameboy;
mod gpu;
mod ram;
