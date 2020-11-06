extern crate sdl2;
use sdl2::audio::{AudioCallback, AudioDevice, AudioSpecDesired};

const HZ: u32 = 44100;
/*
let duty: u8 [4][8] = {
    {0,0,0,0,0,0,1},
    {1,0,0,0,0,0,1},
    {1,0,0,0,1,1,1},
    {0,1,1,1,1,1,0},
};
*/

fn hz_to_samples(n: u32, hz: u32) -> u32 {
    if hz == 0 {
        HZ
    } else if hz > HZ {
        1
    } else {
        (n * HZ) / hz
    }
}

pub struct APU {
    _device: Option<AudioDevice<SquareWave>>, // need a reference to avoid deallocation
    debug: bool,
}

impl APU {
    pub fn init(sdl: &sdl2::Sdl, silent: bool, debug: bool) -> Result<APU, String> {
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
                SquareWave {
                    phase_inc: 440.0 / spec.freq as f32,
                    phase: 0.0,
                    volume: 0.25,
                }
            })?;
            device.resume();
            Some(device)
        } else {
            None
        };

        Ok(APU { _device, debug })
    }

    pub fn tick(&self) {}
}

struct SquareWave {
    phase_inc: f32,
    phase: f32,
    volume: f32,
}

impl AudioCallback for SquareWave {
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
