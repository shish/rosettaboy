extern crate sdl2;
use crate::consts;
use crate::ram;
use sdl2::audio::{AudioCallback, AudioDevice, AudioSpecDesired};
use std::sync::{Arc, RwLock};

const BIT_0: u16 = 0b00000001;
const BIT_1: u16 = 0b00000010;
const BIT_6: u16 = 0b00100000;
const WAVE_LEN: u8 = 32;
const HZ: u16 = 44100;
const DUTY: [[u8; 8]; 4] = [
    [0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 1, 0],
];

macro_rules! LENGTH_COUNTER {
    // ch1,
    // self.control.ch1_active,
    // self.ch1.length_enable,
    // self.ch1.length,
    // self.ch1.length_timer,
    ( $ch:expr, $active:expr, $length_enable:expr, $length:expr, $length_timer:expr) => {
        if $length_enable {
            if $length > 0 {
                $length_timer = ($length_timer + 1) % hz_to_samples(1, 256);
                if $length_timer == 0 {
                    $length -= 1;
                }
                $active = true;
            } else {
                $active = false;
            }
        } else {
            $active = true;
        }
        $ch = $ch * (if $active { 1 } else { 0 });
    };
}

macro_rules! ENVELOPE {
    ( $ch:expr, $ctrl:expr ) => {{
        if $ctrl.envelope_period > 0 {
            $ctrl.envelope_timer =
                ($ctrl.envelope_timer + 1) % hz_to_samples($ctrl.envelope_period, 64);
            if $ctrl.envelope_timer == 0 {
                if !$ctrl.envelope_direction {
                    if $ctrl.envelope_vol > 0 {
                        $ctrl.envelope_vol -= 1;
                    }
                } else {
                    if $ctrl.envelope_vol < 0x0F {
                        $ctrl.envelope_vol += 1;
                    }
                }
            }
        }
        $ch = (($ch as u16 * $ctrl.envelope_vol as u16) / 0x0F) as u8;
    }};
}

fn hz_to_samples(n: u8, hz: u16) -> usize {
    if hz == 0 {
        HZ as usize
    } else if hz > HZ {
        1
    } else {
        ((n as usize * HZ as usize) / hz as usize) as usize
    }
}

pub struct APU {
    _device: Option<AudioDevice<SoundSettings>>, // need a reference to avoid deallocation
    _debug: bool,
    control_buffer: Arc<RwLock<[u8; 23]>>,
    samples_buffer: Arc<RwLock<[u8; 16]>>,
    cycle: usize,
}

impl APU {
    pub fn init(sdl: &sdl2::Sdl, silent: bool, debug: bool) -> Result<APU, String> {
        let buffer = Arc::new(RwLock::new([0; 23]));
        let sample_buffer = Arc::new(RwLock::new([0; 16]));

        let _device = if !silent {
            let audio = sdl.audio()?;
            let spec = AudioSpecDesired {
                freq: Some(HZ as i32),
                channels: Some(2),
                // generate audio for one frame at a time, 735 samples per frame
                samples: Some((HZ / 60) as u16),
            };
            let device = audio.open_playback(None, &spec, |spec| {
                // Show obtained AudioSpec
                println!("{:?}", spec);

                // initialize the audio callback
                let mut ss = SoundSettings::default();
                ss.control_buffer = buffer.clone();
                ss.ch4.lfsr = 0xFFFF;

                ss.lphase_inc = 440.0 / spec.freq as f32;
                ss.lphase = 0.0;
                ss.rphase_inc = 220.0 / spec.freq as f32;
                ss.rphase = 0.0;

                ss
            })?;
            device.resume();
            Some(device)
        } else {
            None
        };

        Ok(APU {
            _device,
            _debug: debug,
            control_buffer: buffer,
            samples_buffer: sample_buffer,
            cycle: 0,
        })
    }

    pub fn tick(&mut self, ram: &ram::RAM) {
        self.cycle += 1;

        // Ideally this would be in sync every tick, but
        // once per frame should be sufficient...?
        if self.cycle % 17556 == 20 {
            let audio_controls =
                &ram.data[consts::IO::NR10 as usize..consts::IO::NR10 as usize + 23];
            let mut control_buffer = self.control_buffer.write().unwrap();
            control_buffer.copy_from_slice(&audio_controls);

            let audio_samples = &ram.data[0xFF30..0xFF40];
            let mut samples_buffer = self.samples_buffer.write().unwrap();
            samples_buffer.copy_from_slice(&audio_samples);
        }
    }
}

#[derive(Default)]
struct Ch1Control {
    // NR10
    // The change of frequency (NR13,NR14) at each shift is calculated by the
    // following formula where X(0) is initial freq & X(t-1) is last freq:
    // X(t) = X(t-1) +/- X(t-1)/2^n
    sweep_shift: u8,    // 3  // 0 = stop envelope
    sweep_negate: bool, // ? -1 : 1
    sweep_period: u8,   // 3  // inc or dec each n/128Hz = (n*44100)/128smp = n*344smp
    // empty1: bool,

    // NR11
    length_load: u8, // 6  // (64-n) * (1/256) seconds
    duty: u8,        // 2  // {12.5, 25, 50, 75}%

    // NR12
    envelope_period: u8, // 3  // 1 step = n * (1/64) seconds
    envelope_direction: bool,
    envelope_vol_load: u8, // 4

    // NR13
    frequency_lsb: u8, // 8

    // NR14
    frequency_msb: u8, // 3
    // empty2: u8,  // 3
    length_enable: bool,
    reset: bool,

    // Internal state
    duty_pos: u8,
    envelope_timer: usize,
    envelope_vol: u8,
    freq_timer: usize,
    length: u8,
    length_timer: usize,
    shadow_freq: u16,
    sweep: u8,
    sweep_timer: usize,
}

#[derive(Default)]
struct Ch2Control {
    // NR20
    // empty1: u8,  // 8

    // NR21
    length_load: u8, // 6  // (64-n) * (1/256) seconds
    duty: u8,        // 2  // {12.5, 25, 50, 75}%

    // NR22
    envelope_period: u8, // 3  // 1 step = n * (1/64) seconds
    envelope_direction: bool,
    envelope_vol_load: u8, // 4

    // NR23
    frequency_lsb: u8, // 8

    // NR24
    frequency_msb: u8, // 3
    // empty2: u8,  // 3
    length_enable: bool,
    reset: bool,

    // Internal State
    duty_pos: u8,
    envelope_timer: usize,
    envelope_vol: u8,
    freq_timer: usize,
    length: u8,
    length_timer: usize,
}

#[derive(Default)]
struct Ch3Control {
    // NR30
    // empty1: u8,  // 7;
    enabled: bool,

    // NR31
    length_load: u8, // 8  // (256-n) * (1/256) seconds

    // NR32
    // empty3: u8,  // 5;
    volume: u8, // 2  // {0,100,50,25}%
    // empty2: bool,

    // NR33
    frequency_lsb: u8, // 8

    // NR34
    frequency_msb: u8, // 3
    // empty4: u8,  // 3
    length_enable: bool,
    reset: bool,

    // Internal state
    freq_timer: usize,
    length: u8,
    length_timer: usize,
    sample: u8,
}

#[derive(Default)]
struct Ch4Control {
    // NR40
    // empty1: u8,  // 8

    // NR41
    length_load: u8, // 6  // (64-n) * (1/256) seconds
    // empty2: u8,  // 2

    // NR42
    envelope_period: u8, // 3  // 1 step = n * (1/64) seconds
    envelope_direction: bool,
    envelope_vol_load: u8, // 4

    // NR43
    divisor_code: u8, // 3
    lfsr_mode: bool,
    clock_shift: u8, // 4

    // NR44
    // empty3: u8,  // 6
    length_enable: bool,
    reset: bool,

    // Internal state
    envelope_timer: usize,
    envelope_vol: u8,
    freq_timer: usize,
    length: u8,
    length_timer: usize,
    lfsr: u16, // = 0xFFFF;
}

#[derive(Default)]
struct Control {
    // NR50
    s01_volume: u8, // 3
    enable_vin_to_s01: bool,
    s02_volume: u8, // 3
    enable_vin_to_s02: bool,

    // NR51
    ch1_to_s01: u8, // 1
    ch2_to_s01: u8, // 1
    ch3_to_s01: u8, // 1
    ch4_to_s01: u8, // 1
    ch1_to_s02: u8, // 1
    ch2_to_s02: u8, // 1
    ch3_to_s02: u8, // 1
    ch4_to_s02: u8, // 1

    // NR52
    ch1_active: bool,
    ch2_active: bool,
    ch3_active: bool,
    ch4_active: bool,
    // empty: u8,  // 3
    snd_enable: bool,
}

#[derive(Default)]
struct SoundSettings {
    // settings as raw bytes
    control_buffer: Arc<RwLock<[u8; 23]>>,
    samples_buffer: Arc<RwLock<[u8; 16]>>,
    samples: [u8; 16],

    // settings parsed
    ch1: Ch1Control,
    ch2: Ch2Control,
    ch3: Ch3Control,
    ch4: Ch4Control,
    control: Control,

    // temporary state
    lphase_inc: f32,
    lphase: f32,
    rphase_inc: f32,
    rphase: f32,
}

impl AudioCallback for SoundSettings {
    type Channel = u8; //f32;
    fn callback(&mut self, out: &mut [Self::Channel]) {
        self.update_regs();
        let mut sample = 0;
        for (n, x) in out.iter_mut().enumerate() {
            if n % 2 == 0 {
                sample = self.get_next_sample();
                *x = (sample & 0xFF00 >> 8) as u8;
            } else {
                *x = (sample & 0x00FF >> 0) as u8;
            }
        }
    }
}

impl SoundSettings {
    #[rustfmt::skip]
    fn update_regs(&mut self) {
        let buffer = self.control_buffer.read().unwrap();
        let samples_buffer = self.samples_buffer.read().unwrap();
        self.samples.copy_from_slice(&samples_buffer[..]);

        ///////////////////////////////////////////////////////////////
        // NR10
        self.ch1.sweep_shift  = (buffer[0] & 0b00000111) >> 0; // 3  // 0 = stop envelope
        self.ch1.sweep_negate = (buffer[0] & 0b00001000) >> 3 == 1; // ? -1 : 1
        self.ch1.sweep_period = (buffer[0] & 0b01110000) >> 4; // 3  // inc or dec each n/128Hz = (n*44100)/128smp = n*344smp

        // NR11
        self.ch1.length_load  = (buffer[1] & 0b00111111) >> 0; // 6  // (64-n) * (1/256) seconds
        self.ch1.duty         = (buffer[1] & 0b11000000) >> 6; // 2  // {12.5, 25, 50, 75}%

        // NR12
        self.ch1.envelope_period    = (buffer[2] & 0b00000111) >> 0; // 3  // 1 step = n * (1/64) seconds
        self.ch1.envelope_direction = (buffer[2] & 0b00001000) >> 3 == 1;
        self.ch1.envelope_vol_load  = (buffer[2] & 0b11110000) >> 4; // 4

        // NR13
        self.ch1.frequency_lsb = buffer[3]; // 8

        // NR14
        self.ch1.frequency_msb = (buffer[4] & 0b00000111) >> 0; // 3
        self.ch1.length_enable = (buffer[4] & 0b01000000) >> 6 == 1;
        self.ch1.reset         = (buffer[4] & 0b10000000) >> 7 == 1;

        ///////////////////////////////////////////////////////////////
        // NR20
        // buffer[5]

        // NR21
        self.ch2.length_load = (buffer[6] & 0b00111111) >> 0; // 6  // (64-n) * (1/256) seconds
        self.ch2.duty        = (buffer[6] & 0b11000000) >> 6; // 2  // {12.5, 25, 50, 75}%

        // NR22
        self.ch2.envelope_period    = (buffer[7] & 0b00000111) >> 0; // 3  // 1 step = n * (1/64) seconds
        self.ch2.envelope_direction = (buffer[7] & 0b00001000) >> 3 == 1;
        self.ch2.envelope_vol_load  = (buffer[7] & 0b11110000) >> 4; // 4

        // NR23
        self.ch2.frequency_lsb = buffer[8]; // 8

        // NR24
        self.ch2.frequency_msb = (buffer[9] & 0b00000111) >> 0; // 3
        self.ch2.length_enable = (buffer[9] & 0b01000000) >> 6 == 1;
        self.ch2.reset         = (buffer[9] & 0b10000000) >> 7 == 1;

        ///////////////////////////////////////////////////////////////
        // NR30
        self.ch3.enabled = (buffer[10] & 0b10000000) >> 7 == 1;

        // NR31
        self.ch3.length_load = buffer[11]; // (256-n) * (1/256) seconds

        // NR32
        self.ch3.volume = (buffer[12] & 0b01100000) >> 5; // {0,100,50,25}%

        // NR33
        self.ch3.frequency_lsb = buffer[13]; // 8

        // NR34
        self.ch3.frequency_msb = (buffer[14] & 0b00000111) >> 0; // 3
        self.ch3.length_enable = (buffer[14] & 0b01000000) >> 6 == 1;
        self.ch3.reset         = (buffer[14] & 0b10000000) >> 7 == 1;

        ///////////////////////////////////////////////////////////////
        // NR40
        // buffer[15]

        // NR41
        self.ch4.length_load = (buffer[16] & 0b00111111) >> 0; // 6  // (64-n) * (1/256) seconds

        // NR42
        self.ch4.envelope_period    = (buffer[17] & 0b00000111) >> 0; // 3  // 1 step = n * (1/64) seconds
        self.ch4.envelope_direction = (buffer[17] & 0b00001000) >> 3 == 1;
        self.ch4.envelope_vol_load  = (buffer[17] & 0b11110000) >> 4; // 4

        // NR43
        self.ch4.divisor_code = (buffer[18] & 0b00000111) >> 0; // 3  // 1 step = n * (1/64) seconds
        self.ch4.lfsr_mode    = (buffer[18] & 0b00001000) >> 3 == 1;
        self.ch4.clock_shift  = (buffer[18] & 0b11110000) >> 4; // 4

        // NR44
        self.ch4.length_enable = (buffer[19] & 0b01000000) >> 6 == 1;
        self.ch4.reset         = (buffer[19] & 0b10000000) >> 7 == 1;

        ///////////////////////////////////////////////////////////////
        // NR50
        self.control.s01_volume        = (buffer[20] & 0b00000111) >> 0;
        self.control.enable_vin_to_s01 = (buffer[20] & 0b00001000) >> 3 == 1;
        self.control.s02_volume        = (buffer[20] & 0b01110000) >> 4;
        self.control.enable_vin_to_s02 = (buffer[20] & 0b10000000) >> 7 == 1;

        // NR51
        self.control.ch1_to_s01 = (buffer[21] & 0b00000001) >> 0;
        self.control.ch2_to_s01 = (buffer[21] & 0b00000010) >> 1;
        self.control.ch3_to_s01 = (buffer[21] & 0b00000100) >> 2;
        self.control.ch4_to_s01 = (buffer[21] & 0b00001000) >> 3;
        self.control.ch1_to_s02 = (buffer[21] & 0b00010000) >> 4;
        self.control.ch2_to_s02 = (buffer[21] & 0b00100000) >> 5;
        self.control.ch3_to_s02 = (buffer[21] & 0b01000000) >> 6;
        self.control.ch4_to_s02 = (buffer[21] & 0b10000000) >> 7;

        // NR52
        self.control.ch1_active = (buffer[22] & 0b00000001) >> 0 == 1;
        self.control.ch2_active = (buffer[22] & 0b00000010) >> 1 == 1;
        self.control.ch3_active = (buffer[22] & 0b00000100) >> 2 == 1;
        self.control.ch4_active = (buffer[22] & 0b00001000) >> 3 == 1;
        self.control.snd_enable = (buffer[22] & 0b10000000) >> 7 == 1;
    }

    fn get_next_sample(&mut self) -> u16 {
        // sample_n = (sample_n + 1) % HZ;

        if !self.control.snd_enable {
            // TODO: wipe all registers
            return 0;
        }

        let ch1 = self.get_ch1_sample();
        let ch2 = self.get_ch2_sample();
        let ch3 = self.get_ch3_sample();
        let ch4 = self.get_ch4_sample();

        let s01 = (((ch1 as u32 >> 2) * self.control.ch1_to_s01 as u32
            + (ch2 as u32 >> 2) * self.control.ch2_to_s01 as u32
            + (ch3 as u32 >> 2) * self.control.ch3_to_s01 as u32
            + (ch4 as u32 >> 2) * self.control.ch4_to_s01 as u32)
            * self.control.s01_volume as u32
            / 4) as u8;
        let s02 = (((ch1 as u32 >> 2) * self.control.ch1_to_s02 as u32
            + (ch2 as u32 >> 2) * self.control.ch2_to_s02 as u32
            + (ch3 as u32 >> 2) * self.control.ch3_to_s02 as u32
            + (ch4 as u32 >> 2) * self.control.ch4_to_s02 as u32)
            * self.control.s02_volume as u32
            / 4) as u8;

        return (s01 as u16) << 8 | s02 as u16; // s01 = right, s02 = left
    }

    fn get_ch1_sample(&mut self) -> u8 {
        //=================================================================
        // Square 1: Sweep -> Timer -> Duty -> Length Counter -> Envelope -> Mixer

        // Sweep
        if self.ch1.sweep_period > 0 {
            self.ch1.sweep_timer =
                (self.ch1.sweep_timer + 1) % hz_to_samples(self.ch1.sweep_period, 128);
            if self.ch1.sweep_timer == 0 {
                if self.ch1.sweep_negate {
                    self.ch1.sweep = self.ch1.sweep.overflowing_sub(1).0;
                } else {
                    self.ch1.sweep = self.ch1.sweep.overflowing_add(1).0;
                };
            }
        }

        // Timer
        // 1651 -> 331Hz
        let ch1_freq = (131072
            / (2048 - (((self.ch1.frequency_msb as u32) << 8) | self.ch1.frequency_lsb as u32)))
            as u16;
        // x8 to get through the whole 8-bit cycle every HZ
        // "ch1_freq = 850" = A = 440Hz. Approx ch1_freq/2 = target hz.
        self.ch1.freq_timer =
            (self.ch1.freq_timer + 1) % hz_to_samples(1, ((ch1_freq * 8) / 2) as u16);

        // Duty
        if self.ch1.freq_timer == 0 {
            self.ch1.duty_pos = (self.ch1.duty_pos + 1) % 8;
        }
        let mut ch1 = DUTY[self.ch1.duty as usize][self.ch1.duty_pos as usize] * 0xFF;

        // Length Counter
        LENGTH_COUNTER!(
            ch1,
            self.control.ch1_active,
            self.ch1.length_enable,
            self.ch1.length,
            self.ch1.length_timer // len=63
        );

        // Envelope
        ENVELOPE!(ch1, self.ch1);

        // Reset handler
        if self.ch1.reset {
            self.ch1.reset = false;
            self.ch1.length = if self.ch1.length_load > 0 {
                self.ch1.length_load
            } else {
                63
            }; // channel enabled
            self.ch1.length_timer = 1;
            self.ch1.freq_timer = 1; // frequency timer reloaded with period
            self.ch1.envelope_timer = 1; // volume envelope timer is reloaded with period
            self.ch1.envelope_vol = self.ch1.envelope_vol_load; // volume reloaded from NRx2
                                                                // sweep does "several things"
            self.ch1.sweep_timer = 1;
            self.ch1.shadow_freq = ch1_freq as u16;
        }

        return ch1;
    }

    fn get_ch2_sample(&mut self) -> u8 {
        //=================================================================
        // Square 2:          Timer -> Duty -> Length Counter -> Envelope -> Mixer

        // Timer
        let ch2_freq = (131072
            / (2048 - (((self.ch2.frequency_msb as u32) << 8) | self.ch2.frequency_lsb as u32)))
            as u16;
        self.ch2.freq_timer = (self.ch2.freq_timer + 1) % hz_to_samples(1, (ch2_freq * 8) / 2);

        // Duty
        if self.ch2.freq_timer == 0 {
            self.ch2.duty_pos = (self.ch2.duty_pos + 1) % 8;
        }
        let mut ch2 = DUTY[self.ch2.duty as usize][self.ch2.duty_pos as usize] * 0xFF;

        // Length Counter
        LENGTH_COUNTER!(
            ch2,
            self.control.ch2_active,
            self.ch2.length_enable,
            self.ch2.length,
            self.ch2.length_timer // len=63
        );

        // Envelope
        ENVELOPE!(ch2, self.ch2);

        // Reset handler
        if self.ch2.reset {
            self.ch2.reset = false;
            self.ch2.length = if self.ch2.length_load > 0 {
                self.ch2.length_load
            } else {
                63
            }; // channel enabled
            self.ch2.length_timer = 1;
            self.ch2.freq_timer = 1; // frequency timer reloaded with period
            self.ch2.envelope_timer = 1; // volume envelope timer is reloaded with period
            self.ch2.envelope_vol = self.ch2.envelope_vol_load; // volume reloaded from NRx2
        }

        return ch2;
    }

    fn get_ch3_sample(&mut self) -> u8 {
        //=================================================================
        // Wave:              Timer -> Wave -> Length Counter -> Volume -> Mixer

        // Timer
        let ch3_freq = (65536
            / (2048 - (((self.ch3.frequency_msb as u32) << 8) | self.ch3.frequency_lsb as u32)))
            as u16;
        self.ch3.freq_timer = (self.ch3.freq_timer + 1) % hz_to_samples(1, ch3_freq * 8);
        // do we want one 4-bit sample, or 32 4-bit samples to appear $freq times per sec?
        // assuming here that we want the whole waveform N times/sec
        if self.ch3.freq_timer == 0 {
            self.ch3.sample = (self.ch3.sample + 1) % WAVE_LEN;
        }

        // Wave
        let mut ch3 = if self.ch3.enabled {
            if self.ch3.sample % 2 == 0 {
                self.samples[(self.ch3.sample / 2) as usize] & 0xF0
            } else {
                (self.samples[(self.ch3.sample / 2) as usize] & 0x0F) << 4
            }
        } else {
            self.ch3.sample = 0;
            0
        };

        // Length Counter
        LENGTH_COUNTER!(
            ch3,
            self.control.ch3_active,
            self.ch3.length_enable,
            self.ch3.length,
            self.ch3.length_timer // len=255
        );

        // Volume
        if self.ch3.volume == 0 {
            ch3 = 0;
        } else {
            ch3 >>= self.ch3.volume - 1;
        }

        // Reset handler
        if self.ch3.reset {
            self.ch3.reset = false;
            self.ch3.length = if self.ch3.length_load > 0 {
                self.ch3.length_load
            } else {
                255
            }; // channel enabled
            self.ch3.length_timer = 1;
            self.ch3.freq_timer = 1; // frequency timer reloaded with period
            self.ch3.sample = 0; // wave channel's position set to 0
        }
        return ch3;
    }

    fn get_ch4_sample(&mut self) -> u8 {
        //=================================================================
        // Noise:             Timer -> LFSR -> Length Counter -> Envelope -> Mixer

        // Timer
        let ch4_div = match self.ch4.divisor_code {
            0 => 8,
            1 => 16,
            2 => 32,
            3 => 48,
            4 => 64,
            5 => 80,
            6 => 96,
            7 => 112,
            _ => 0,
        };
        self.ch4.freq_timer = (self.ch4.freq_timer + 1) % (ch4_div << self.ch4.clock_shift);

        // LFSR
        if self.ch4.freq_timer == 0 {
            let new_bit = ((self.ch4.lfsr & BIT_1) >> 1) ^ (self.ch4.lfsr & BIT_0); // xor two low bits
            self.ch4.lfsr >>= 1; // shift right
            self.ch4.lfsr |= new_bit << 14; // bit15 = new
            if self.ch4.lfsr_mode {
                self.ch4.lfsr = (self.ch4.lfsr & !BIT_6) | (new_bit << 6); // bit7 = new
            }
        }
        let mut ch4 = 0xFF - ((self.ch4.lfsr & BIT_0) as u8 * 0xFF); // bit0, inverted

        // Length Counter
        LENGTH_COUNTER!(
            ch4,
            self.control.ch4_active,
            self.ch4.length_enable,
            self.ch4.length,
            self.ch4.length_timer // len=63
        );

        // Envelope
        ENVELOPE!(ch4, self.ch4);

        // Reset handler
        if self.ch4.reset {
            self.ch4.reset = false;
            self.ch4.length = if self.ch4.length_load > 0 {
                self.ch4.length_load
            } else {
                63
            }; // channel enabled
            self.ch4.length_timer = 1;
            self.ch4.freq_timer = 1; // frequency timer reloaded with period
            self.ch4.envelope_timer = 1; // volume envelope timer is reloaded with period
            self.ch4.envelope_vol = self.ch4.envelope_vol_load; // volume reloaded from NRx2
            self.ch4.lfsr = 0xFFFF; // ch4_lfsr bits all set to 1
        }

        return ch4;
    }
}
