use clap::Parser;

fn main() {
    divan::main();
}

#[divan::bench]
fn tick(bencher: divan::Bencher) {
    let args = rosettaboy_rs::args::Args::parse_from([
        "rosettaboy_rs", "--silent", "--headless", "--turbo",
        "../gb-autotest-roms/blargg-cpu-instructions/01-special.gb"
    ].iter());
    let mut gb = rosettaboy_rs::gameboy::GameBoy::new(args).unwrap();
    bencher.bench_local(|| gb.tick().unwrap());
}

#[divan::bench]
fn ram_get() -> u64 {
    let ram = rosettaboy_rs::ram::RAM::new(
        rosettaboy_rs::cart::Cart::new(
            "../gb-autotest-roms/blargg-cpu-instructions/01-special.gb"
        ).unwrap(),
        false,
    )
    .unwrap();
    let mut sum = 0;
    for i in 0..0x3FFF {
        sum += ram.get(i as u16);
    }
    sum as u64
}
