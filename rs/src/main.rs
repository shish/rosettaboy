#![allow(clippy::needless_return)]
#![allow(clippy::identity_op)]
#![allow(clippy::upper_case_acronyms)]
#![allow(clippy::many_single_char_names)]

use anyhow::{anyhow, Result};
use clap::Parser;
extern crate sdl2;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::errors::ControlledExit;

#[macro_use]
extern crate bitflags;

mod apu;
mod args;
mod buttons;
mod cart;
mod clock;
mod consts;
mod cpu;
mod errors;
mod gameboy;
mod gpu;
mod ram;

fn configure_logging(args: &args::Args) {
    let mut levels = "rosettaboy_rs=warn".to_string();
    if args.debug_apu {
        levels.push_str(",rosettaboy_rs::apu=debug");
    }
    if args.debug_cpu {
        levels.push_str(",rosettaboy_rs::cpu=debug");
    }
    if args.debug_gpu {
        levels.push_str(",rosettaboy_rs::gpu=debug");
    }
    if args.debug_ram {
        levels.push_str(",rosettaboy_rs::ram=debug");
    }
    let filter_layer =
        tracing_subscriber::EnvFilter::new(std::env::var("RUST_LOG").unwrap_or(levels));
    let format_layer = tracing_subscriber::fmt::layer()
        .without_time()
        .with_level(false)
        .with_target(false);
    tracing_subscriber::registry()
        .with(filter_layer)
        .with(format_layer)
        .init();
}

fn main() -> Result<()> {
    let args = args::Args::parse();
    configure_logging(&args);
    match gameboy::GameBoy::new(args)?.run() {
        Ok(_) => Err(anyhow!("Main loop exited with no error??")),
        Err(e) => {
            if let Some(e) = e.downcast_ref::<errors::ControlledExit>() {
                println!("{}", e);
                let exit_code = match e {
                    ControlledExit::UnitTestFailed => 2,
                    _ => 0,
                };
                std::process::exit(exit_code)
            }
            if let Some(e) = e.downcast_ref::<errors::GameException>() {
                println!("{}", e);
                std::process::exit(3);
            }
            if let Some(e) = e.downcast_ref::<errors::UserException>() {
                println!("{}", e);
                std::process::exit(4);
            }
            Err(e)
        }
    }
}
