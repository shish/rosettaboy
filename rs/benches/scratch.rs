fn main() {
    divan::main();
}

// Define a `fibonacci` function and
// register it for benchmarking.
#[divan::bench]
fn fibonacci() -> u64 {
    fn compute(n: u64) -> u64 {
        if n <= 1 {
            1
        } else {
            compute(n - 2) + compute(n - 1)
        }
    }

    compute(divan::black_box(10))
}
