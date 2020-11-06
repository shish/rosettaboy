extern crate sdl2;
use crate::ram;
use crate::consts;
use sdl2::audio::{AudioCallback, AudioDevice, AudioSpecDesired};
use std::sync::{Arc,RwLock};

const HZ: u32 = 44100;
/*
let duty: u8 [4][8] = {
    {0,0,0,0,0,0,1},
    {1,0,0,0,0,0,1},
    {1,0,0,0,1,1,1},
    {0,1,1,1,1,1,0},
};
*/

/*
fn hz_to_samples(n: u32, hz: u32) -> u32 {
    if hz == 0 {
        HZ
    } else if hz > HZ {
        1
    } else {
        (n * HZ) / hz
    }
}
*/

struct SoundSettings {
    phase_inc: f32,
    phase: f32,
    volume: f32,
    _raw: Arc<RwLock<[u8; 23]>>,
}

pub struct APU {
    _device: Option<AudioDevice<SoundSettings>>,  // need a reference to avoid deallocation
    _debug: bool,
    buffer: Arc<RwLock<[u8; 23]>>,
}

impl APU {
    pub fn init(sdl: &sdl2::Sdl, silent: bool, debug: bool) -> Result<APU, String> {
        let buffer = Arc::new(RwLock::new([0; 23]));

        let _device = if !silent {
            let audio = sdl.audio()?;
            let spec = AudioSpecDesired {
                freq: Some(HZ as i32),
                // format: sdl2::audio::AudioFormat::U8,
                channels: Some(2),
                // generate audio for one frame at a time, 735 samples per frame
                samples: Some((HZ / 60) as u16),
            };
            let device = audio.open_playback(None, &spec, |spec| {
                // Show obtained AudioSpec
                println!("{:?}", spec);

                // initialize the audio callback
                SoundSettings {
                    phase_inc: 440.0 / HZ as f32,
                    phase: 0.0,
                    volume: 0.25,
                    _raw: buffer.clone(),
                }
            })?;
            device.resume();
            Some(device)
        } else {
            None
        };

        Ok(APU { _device, _debug: debug, buffer })
    }

    pub fn tick(&mut self, ram: &ram::RAM) {
        // FIXME: do we need to do this EVERY tick?
        let audio_controls = &ram.data[consts::IO::NR10 as usize .. consts::IO::NR10 as usize+23];
        let mut buffer = self.buffer.write().unwrap();
        buffer.copy_from_slice(&audio_controls);
    }
}


impl AudioCallback for SoundSettings {
    type Channel = f32;

    fn callback(&mut self, out: &mut [f32]) {
        // Generate a square wave
        for x in out.iter_mut() {
            *x = if self.phase <= 0.5 {
                self.volume
            } else {
                -self.volume
            };
            self.phase = (self.phase + self.phase_inc) % 1.0;
        }
        /*
            fn audio_callback(void *_sound, Uint8 *_stream, int _length) {
                u16 *stream = (u16*) _stream;
                APU* sound = (APU*) _sound;
                int length = _length / sizeof(stream[0]);

                for(int i=0; i<length; i++) {
                    stream[i] = sound->get_next_sample();
                }
            }
        */
    }
}
