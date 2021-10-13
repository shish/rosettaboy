extern crate sdl2;
use crate::consts::*;
use crate::ram;
use anyhow::Result;
use sdl2::audio::{AudioQueue, AudioSpecDesired};
use std::convert::TryFrom;

extern crate packed_struct;
use packed_struct::prelude::*;

const WAVE_LEN: u8 = 32;
const HZ: u16 = 48000;
const DUTY: [[u8; 8]; 4] = [
    [0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 1, 0],
];

macro_rules! LENGTH_COUNTER {
    ( $ch:expr, $active:expr, $ctrl:expr, $st:expr) => {
        if $ctrl.length_enable {
            if $st.length > 0 {
                $st.length_timer = ($st.length_timer + 1) % hz_to_samples(256);
                if $st.length_timer == 0 {
                    $st.length -= 1;
                }
                $active = true;
            } else {
                $active = false;
            }
        } else {
            $active = true;
        }
        $ch *= (if $active { 1 } else { 0 });
    };
}

macro_rules! ENVELOPE {
    ( $ch:expr, $ctrl:expr, $st:expr ) => {{
        if $ctrl.envelope_period > 0 {
            $st.envelope_timer =
                ($st.envelope_timer + 1) % ($ctrl.envelope_period as usize * hz_to_samples(64));
            if $st.envelope_timer == 0 {
                if !$ctrl.envelope_direction {
                    if $st.envelope_vol > 0 {
                        $st.envelope_vol -= 1;
                    }
                } else {
                    if $st.envelope_vol < 0x0F {
                        $st.envelope_vol += 1;
                    }
                }
            }
        }
        $ch = (($ch as u16 * $st.envelope_vol as u16) / 0x0F) as u8;
    }};
}

fn envelope(ctrl: &mut Ch1Control, st: &mut Ch1State) -> u16 {
    if ctrl.envelope_period > 0 {
        st.envelope_timer =
            (st.envelope_timer + 1) % (ctrl.envelope_period as usize * hz_to_samples(64));
        if st.envelope_timer == 0 {
            if ctrl.envelope_direction && st.envelope_vol < 0x0F {
                st.envelope_vol += 1;
            }
            if !ctrl.envelope_direction && st.envelope_vol > 0 {
                st.envelope_vol -= 1;
            }
        }
    }
    return st.envelope_vol as u16;
}

fn hz_to_samples(hz: u16) -> usize {
    if hz == 0 {
        HZ as usize
    } else if hz > HZ {
        1
    } else {
        (HZ / hz) as usize
    }
}

#[derive(Default)]
pub struct APU {
    device: Option<AudioQueue<u8>>, // need a reference to avoid deallocation
    _debug: bool,
    cycle: usize,

    ch1: Ch1Control,
    ch1s: Ch1State,
    ch2: Ch2Control,
    ch2s: Ch2State,
    ch3: Ch3Control,
    ch3s: Ch3State,
    ch4: Ch4Control,
    ch4s: Ch4State,
    control: Control,
    samples: [u8; 16],
}

impl APU {
    pub fn new(sdl: &sdl2::Sdl, silent: bool, debug: bool) -> Result<APU> {
        let device = if !silent {
            let audio = sdl.audio().map_err(anyhow::Error::msg)?;
            let spec = AudioSpecDesired {
                freq: Some(HZ as i32),
                channels: Some(2),
                // generate audio for one frame at a time, 735 samples per frame
                samples: Some((HZ / 60) as u16),
            };
            let device = audio
                .open_queue::<u8, _>(None, &spec)
                .map_err(anyhow::Error::msg)?;
            device.resume();
            Some(device)
        } else {
            None
        };

        let mut apu = APU {
            device,
            _debug: debug,
            ..Default::default()
        };
        apu.ch4s.lfsr = 0xFFFF;
        Ok(apu)
    }

    pub fn tick(&mut self, ram: &mut ram::RAM) {
        self.cycle += 1;

        // Ideally this would be in sync every tick, but
        // once per frame should be sufficient...?
        if self.cycle % 17556 == 20 {
            let out = self.render_frame_audio(ram);

            if let Some(device) = &self.device {
                // println!("size = {}", device.size());
                if device.size() <= ((HZ / 60) * 2) as u32 {
                    device.queue(&out);
                    device.queue(&out);
                }
                device.queue(&out);
            }
        }
    }

    fn render_frame_audio(&mut self, ram: &mut ram::RAM) -> [u8; (HZ / 60) as usize] {
        let audio_controls = &mut ram.data[Mem::NR10 as usize..Mem::NR10 as usize + 23];
        let mut out = [0; (HZ / 60) as usize];

        self.ram_to_regs(audio_controls);
        let mut sample = 0;
        for (n, x) in out.iter_mut().enumerate() {
            if n % 2 == 0 {
                sample = self.get_next_sample();
                *x = ((sample & 0xFF00) >> 8) as u8;
            } else {
                *x = ((sample & 0x00FF) >> 0) as u8;
            }
        }
        self.regs_to_ram(audio_controls);
        out
    }

    fn ram_to_regs(&mut self, buffer: &[u8]) {
        self.ch1 = Ch1Control::unpack(<&[u8; 5]>::try_from(&buffer[0..=4]).unwrap()).unwrap();
        self.ch2 = Ch2Control::unpack(<&[u8; 5]>::try_from(&buffer[5..=9]).unwrap()).unwrap();
        self.ch3 = Ch3Control::unpack(<&[u8; 5]>::try_from(&buffer[10..=14]).unwrap()).unwrap();
        self.ch4 = Ch4Control::unpack(<&[u8; 5]>::try_from(&buffer[15..=19]).unwrap()).unwrap();
        self.control = Control::unpack(<&[u8; 3]>::try_from(&buffer[20..=22]).unwrap()).unwrap();
    }

    fn regs_to_ram(&mut self, buffer: &mut [u8]) {
        let cbuf = self.ch1.pack();
        buffer[0] = cbuf[0];
        buffer[1] = cbuf[1];
        buffer[2] = cbuf[2];
        buffer[3] = cbuf[3];
        buffer[4] = cbuf[4];

        let cbuf = self.ch2.pack();
        buffer[5] = cbuf[0];
        buffer[6] = cbuf[1];
        buffer[7] = cbuf[2];
        buffer[8] = cbuf[3];
        buffer[9] = cbuf[4];

        let cbuf = self.ch3.pack();
        buffer[10] = cbuf[0];
        buffer[11] = cbuf[1];
        buffer[12] = cbuf[2];
        buffer[13] = cbuf[3];
        buffer[14] = cbuf[4];

        let cbuf = self.ch4.pack();
        buffer[15] = cbuf[0];
        buffer[16] = cbuf[1];
        buffer[17] = cbuf[2];
        buffer[18] = cbuf[3];
        buffer[19] = cbuf[4];

        let cbuf = self.control.pack();
        buffer[20] = cbuf[0];
        buffer[21] = cbuf[1];
        buffer[22] = cbuf[2];
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
            * self.control.s01_volume.to_primitive() as u32
            / 4) as u8;
        let s02 = (((ch1 as u32 >> 2) * self.control.ch1_to_s02 as u32
            + (ch2 as u32 >> 2) * self.control.ch2_to_s02 as u32
            + (ch3 as u32 >> 2) * self.control.ch3_to_s02 as u32
            + (ch4 as u32 >> 2) * self.control.ch4_to_s02 as u32)
            * self.control.s02_volume.to_primitive() as u32
            / 4) as u8;

        return ((s01 as u16) << 8) | s02 as u16; // s01 = right, s02 = left
    }

    fn get_ch1_sample(&mut self) -> u8 {
        //=================================================================
        // Square 1: Sweep -> Timer -> Duty -> Length Counter -> Envelope -> Mixer

        // Sweep
        if self.ch1.sweep_period > 0 {
            self.ch1s.sweep_timer =
                (self.ch1s.sweep_timer + 1) % (self.ch1.sweep_period as usize * hz_to_samples(128));
            if self.ch1s.sweep_timer == 0 {
                if self.ch1.sweep_negate {
                    self.ch1s.sweep = self.ch1s.sweep.overflowing_sub(1).0;
                } else {
                    self.ch1s.sweep = self.ch1s.sweep.overflowing_add(1).0;
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
        self.ch1s.freq_timer =
            (self.ch1s.freq_timer + 1) % hz_to_samples(((ch1_freq * 8) / 2) as u16);

        // Duty
        if self.ch1s.freq_timer == 0 {
            self.ch1s.duty_pos = (self.ch1s.duty_pos + 1) % 8;
        }
        let mut ch1 = DUTY[self.ch1.duty as usize][self.ch1s.duty_pos as usize] * 0xFF;

        // Length Counter
        LENGTH_COUNTER!(ch1, self.control.ch1_active, self.ch1, self.ch1s);

        // Envelope
        //ENVELOPE!(ch1, self.ch1, self.ch1s);
        ch1 = ((ch1 as u16 * envelope(&mut self.ch1, &mut self.ch1s)) / 0x0F) as u8;

        // Reset handler
        if self.ch1.reset {
            self.ch1.reset = false;
            self.ch1s.length = if self.ch1.length_load > 0 {
                self.ch1.length_load
            } else {
                63
            }; // channel enabled
            self.ch1s.length_timer = 1;
            self.ch1s.freq_timer = 1; // frequency timer reloaded with period
            self.ch1s.envelope_timer = 1; // volume envelope timer is reloaded with period
            self.ch1s.envelope_vol = self.ch1.envelope_vol_load; // volume reloaded from NRx2
                                                                 // sweep does "several things"
            self.ch1s.sweep_timer = 1;
            self.ch1s.shadow_freq = ch1_freq as u16;
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
        self.ch2s.freq_timer = (self.ch2s.freq_timer + 1) % hz_to_samples((ch2_freq * 8) / 2);

        // Duty
        if self.ch2s.freq_timer == 0 {
            self.ch2s.duty_pos = (self.ch2s.duty_pos + 1) % 8;
        }
        let mut ch2 = DUTY[self.ch2.duty as usize][self.ch2s.duty_pos as usize] * 0xFF;

        // Length Counter
        LENGTH_COUNTER!(ch2, self.control.ch2_active, self.ch2, self.ch2s);

        // Envelope
        ENVELOPE!(ch2, self.ch2, self.ch2s);

        // Reset handler
        if self.ch2.reset {
            self.ch2.reset = false;
            self.ch2s.length = if self.ch2.length_load > 0 {
                self.ch2.length_load
            } else {
                63
            }; // channel enabled
            self.ch2s.length_timer = 1;
            self.ch2s.freq_timer = 1; // frequency timer reloaded with period
            self.ch2s.envelope_timer = 1; // volume envelope timer is reloaded with period
            self.ch2s.envelope_vol = self.ch2.envelope_vol_load; // volume reloaded from NRx2
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
        self.ch3s.freq_timer = (self.ch3s.freq_timer + 1) % hz_to_samples(ch3_freq * 8);
        // do we want one 4-bit sample, or 32 4-bit samples to appear $freq times per sec?
        // assuming here that we want the whole waveform N times/sec
        if self.ch3s.freq_timer == 0 {
            self.ch3s.sample = (self.ch3s.sample + 1) % WAVE_LEN;
        }

        // Wave
        let mut ch3 = if self.ch3.enabled {
            if self.ch3s.sample % 2 == 0 {
                self.samples[(self.ch3s.sample / 2) as usize] & 0xF0
            } else {
                (self.samples[(self.ch3s.sample / 2) as usize] & 0x0F) << 4
            }
        } else {
            self.ch3s.sample = 0;
            0
        };

        // Length Counter
        LENGTH_COUNTER!(ch3, self.control.ch3_active, self.ch3, self.ch3s);

        // Volume
        if self.ch3.volume == 0 {
            ch3 = 0;
        } else {
            ch3 >>= self.ch3.volume - 1;
        }

        // Reset handler
        if self.ch3.reset {
            self.ch3.reset = false;
            self.ch3s.length = if self.ch3.length_load > 0 {
                self.ch3.length_load
            } else {
                255
            }; // channel enabled
            self.ch3s.length_timer = 1;
            self.ch3s.freq_timer = 1; // frequency timer reloaded with period
            self.ch3s.sample = 0; // wave channel's position set to 0
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
        self.ch4s.freq_timer = (self.ch4s.freq_timer + 1) % (ch4_div << self.ch4.clock_shift);

        // LFSR
        if self.ch4s.freq_timer == 0 {
            let new_bit = ((self.ch4s.lfsr & (1 << 1)) >> 1) ^ (self.ch4s.lfsr & (1 << 0)); // xor two low bits
            self.ch4s.lfsr >>= 1; // shift right
            self.ch4s.lfsr |= new_bit << 14; // bit15 = new
            if self.ch4.lfsr_mode {
                self.ch4s.lfsr = (self.ch4s.lfsr & !(1 << 6)) | (new_bit << 6); // bit7 = new
            }
        }
        let mut ch4 = 0xFF - ((self.ch4s.lfsr & (1 << 0)) as u8 * 0xFF); // bit0, inverted

        // Length Counter
        LENGTH_COUNTER!(ch4, self.control.ch4_active, self.ch4, self.ch4s);

        // Envelope
        ENVELOPE!(ch4, self.ch4, self.ch4s);

        // Reset handler
        if self.ch4.reset {
            self.ch4.reset = false;
            self.ch4s.length = if self.ch4.length_load > 0 {
                self.ch4.length_load
            } else {
                63
            }; // channel enabled
            self.ch4s.length_timer = 1;
            self.ch4s.freq_timer = 1; // frequency timer reloaded with period
            self.ch4s.envelope_timer = 1; // volume envelope timer is reloaded with period
            self.ch4s.envelope_vol = self.ch4.envelope_vol_load; // volume reloaded from NRx2
            self.ch4s.lfsr = 0xFFFF; // ch4_lfsr bits all set to 1
        }

        return ch4;
    }
}

#[derive(Default, Debug, PackedStruct)]
#[packed_struct(bit_numbering = "msb0")]
pub struct Ch1Control {
    // NR10
    // The change of frequency (NR13,NR14) at each shift is calculated by the
    // following formula where X(0) is initial freq & X(t-1) is last freq:
    // X(t) = X(t-1) +/- X(t-1)/2^n
    // #[packed_field(bits="0")]
    #[packed_field(bits = "1:3")]
    sweep_period: u8, // 3  // inc or dec each n/128Hz = (n*44100)/128smp = n*344smp
    #[packed_field(bits = "4")]
    sweep_negate: bool, // ? -1 : 1
    #[packed_field(bits = "5:7")]
    sweep_shift: u8, // 3  // 0 = stop envelope

    // NR11
    #[packed_field(bits = "8:9")]
    duty: u8, // 2  // {12.5, 25, 50, 75}%
    #[packed_field(bits = "10:15")]
    length_load: u8, // 6  // (64-n) * (1/256) seconds

    // NR12
    #[packed_field(bits = "16:19")]
    envelope_vol_load: u8, // 4
    #[packed_field(bits = "20")]
    envelope_direction: bool,
    #[packed_field(bits = "21:23")]
    envelope_period: u8, // 3  // 1 step = n * (1/64) seconds

    // NR13
    #[packed_field(bits = "24:31")]
    frequency_lsb: u8, // 8

    // NR14
    #[packed_field(bits = "32")]
    reset: bool,
    #[packed_field(bits = "33")]
    length_enable: bool,
    // #[packed_field(bits="34:36")]
    #[packed_field(bits = "37:39")]
    frequency_msb: u8, // 3
}

#[derive(Default, Debug)]
struct Ch1State {
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

#[derive(Default, Debug, PackedStruct)]
#[packed_struct(bit_numbering = "msb0")]
pub struct Ch2Control {
    // NR20
    #[packed_field(bits = "0:7")]
    _reserved1: ReservedZeroes<packed_bits::Bits8>,

    // NR21
    #[packed_field(bits = "8:9")]
    duty: u8, // 2  // {12.5, 25, 50, 75}%
    #[packed_field(bits = "10:15")]
    length_load: u8, // 6  // (64-n) * (1/256) seconds

    // NR22
    #[packed_field(bits = "16:19")]
    envelope_vol_load: u8, // 4
    #[packed_field(bits = "20")]
    envelope_direction: bool,
    #[packed_field(bits = "21:23")]
    envelope_period: u8, // 3  // 1 step = n * (1/64) seconds

    // NR23
    #[packed_field(bits = "24:31")]
    frequency_lsb: u8, // 8

    // NR24
    #[packed_field(bits = "32")]
    reset: bool,
    #[packed_field(bits = "33")]
    length_enable: bool,
    // #[packed_field(bits="34:36")]
    #[packed_field(bits = "37:39")]
    frequency_msb: u8, // 3
}

#[derive(Default, Debug)]
struct Ch2State {
    duty_pos: u8,
    envelope_timer: usize,
    envelope_vol: u8,
    freq_timer: usize,
    length: u8,
    length_timer: usize,
}

#[derive(Default, Debug, PackedStruct)]
#[packed_struct(bit_numbering = "msb0")]
pub struct Ch3Control {
    // NR30
    #[packed_field(bits = "0")]
    enabled: bool,
    // #[packed_field(bits="1:7")]

    // NR31
    #[packed_field(bits = "8:15")]
    length_load: u8, // (256-n) * (1/256) seconds

    // NR32
    // #[packed_field(bits="16")]
    #[packed_field(bits = "17:18")]
    volume: u8, // 2  // {0,100,50,25}%
    // #[packed_field(bits="19:23")]

    // NR33
    #[packed_field(bits = "24:31")]
    frequency_lsb: u8, // 8

    // NR34
    #[packed_field(bits = "32")]
    reset: bool,
    #[packed_field(bits = "33")]
    length_enable: bool,
    // #[packed_field(bits="34:36")]
    #[packed_field(bits = "37:39")]
    frequency_msb: u8, // 3
}

#[derive(Default, Debug)]
struct Ch3State {
    freq_timer: usize,
    length: u8,
    length_timer: usize,
    sample: u8,
}

#[derive(Default, Debug, PackedStruct)]
#[packed_struct(bit_numbering = "msb0")]
pub struct Ch4Control {
    // NR40
    // #[packed_field(bits="0:7")]

    // NR41
    // #[packed_field(bits="8:9")]
    #[packed_field(bits = "10:15")]
    length_load: u8, // (64-n) * (1/256) seconds

    // NR42
    #[packed_field(bits = "16:19")]
    envelope_vol_load: u8,
    #[packed_field(bits = "20")]
    envelope_direction: bool,
    #[packed_field(bits = "21:23")]
    envelope_period: u8, // 1 step = n * (1/64) seconds

    // NR43
    #[packed_field(bits = "24:27")]
    clock_shift: u8, // 4
    #[packed_field(bits = "28")]
    lfsr_mode: bool,
    #[packed_field(bits = "29:31")]
    divisor_code: u8, // 3

    // NR44
    #[packed_field(bits = "32")]
    reset: bool,
    #[packed_field(bits = "33")]
    length_enable: bool,
    // #[packed_field(bits="34:39")]
}

#[derive(Default, Debug)]
pub struct Ch4State {
    // Internal state
    envelope_timer: usize,
    envelope_vol: u8,
    freq_timer: usize,
    length: u8,
    length_timer: usize,
    lfsr: u16, // = 0xFFFF;
}

#[derive(Default, Debug, PackedStruct)]
#[packed_struct(bit_numbering = "msb0")]
pub struct Control {
    // NR50
    #[packed_field(bits = "0")]
    enable_vin_to_s02: bool,
    #[packed_field(bits = "1:3")]
    s02_volume: Integer<u8, packed_bits::Bits3>,
    #[packed_field(bits = "4")]
    enable_vin_to_s01: bool,
    #[packed_field(bits = "5:7")]
    s01_volume: Integer<u8, packed_bits::Bits3>,

    // NR51
    #[packed_field(bits = "8")]
    ch4_to_s02: u8,
    #[packed_field(bits = "9")]
    ch3_to_s02: u8,
    #[packed_field(bits = "10")]
    ch2_to_s02: u8,
    #[packed_field(bits = "11")]
    ch1_to_s02: u8,
    #[packed_field(bits = "12")]
    ch4_to_s01: u8,
    #[packed_field(bits = "13")]
    ch3_to_s01: u8,
    #[packed_field(bits = "14")]
    ch2_to_s01: u8,
    #[packed_field(bits = "15")]
    ch1_to_s01: u8,

    // NR52
    #[packed_field(bits = "16")]
    snd_enable: bool,
    // #[packed_field(bits="17:19")]
    #[packed_field(bits = "20")]
    ch4_active: bool,
    #[packed_field(bits = "21")]
    ch3_active: bool,
    #[packed_field(bits = "22")]
    ch2_active: bool,
    #[packed_field(bits = "23")]
    ch1_active: bool,
}
