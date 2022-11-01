use criterion::{criterion_group, criterion_main, Criterion};

fn all(c: &mut Criterion) {
    let mut gb = rosettaboy_rs::gameboy::GameBoy::new(rosettaboy_rs::args::Args {
        rom: "../test_roms/games/opus5.gb".to_string(),
        headless: true,
        silent: true,
        debug_cpu: false,
        debug_gpu: false,

        debug_apu: false,
        debug_ram: false,

        profile: 600,

        turbo: true,
    })
    .unwrap();
    c.bench_function("tick", |b| b.iter(|| gb.tick()));
}

criterion_group!(benches, all);
criterion_main!(benches);
