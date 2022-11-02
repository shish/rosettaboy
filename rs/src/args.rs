use clap::Parser;

/// RosettaBoy - Rust
#[derive(Parser)]
#[clap(about, author, version)]
pub struct Args {
    /// Path to a .gb file
    #[clap(default_value = "game.gb")]
    pub rom: String,

    /// Disable GUI
    #[clap(short = 'H', long)]
    pub headless: bool,

    /// Disable Sound
    #[clap(short = 'S', long)]
    pub silent: bool,

    /// Debug CPU
    #[clap(short = 'c', long)]
    pub debug_cpu: bool,

    /// Debug GPU
    #[clap(short = 'g', long)]
    pub debug_gpu: bool,

    /// Debug APU
    #[clap(short = 'a', long)]
    pub debug_apu: bool,

    /// Debug RAM
    #[clap(short = 'r', long)]
    pub debug_ram: bool,

    /// Exit after N frames
    #[clap(short, long, default_value = "0")]
    pub frames: u32,

    /// Exit after N seconds
    #[clap(short, long, default_value = "0")]
    pub profile: u32,

    /// No sleep()
    #[clap(short, long)]
    pub turbo: bool,
}
