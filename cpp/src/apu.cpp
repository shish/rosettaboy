#include <SDL2/SDL.h>

#include "apu.h"

u32 HZ = 48000; // 44100;
u8 duty[4][8] = {
    {1, 0, 0, 0, 0, 0, 0, 0},
    {1, 1, 0, 0, 0, 0, 0, 0},
    {1, 1, 1, 1, 0, 0, 0, 0},
    {1, 1, 1, 1, 1, 1, 0, 0},
};

static int hz_to_samples(int hz) {
    if(hz == 0) return HZ;
    if(hz > HZ) return 1;
    return HZ / hz;
}

#define LENGTH_COUNTER(ch)                                                                                             \
    if(ch##_dat->length_enable == 1) {                                                                                 \
        if(this->ch##_length > 0) {                                                                                    \
            this->ch##_length_timer = (this->ch##_length_timer + 1) % hz_to_samples(256);                              \
            if(this->ch##_length_timer == 0) this->ch##_length--;                                                      \
            ch_control->ch##_active = true;                                                                            \
        } else {                                                                                                       \
            ch_control->ch##_active = false;                                                                           \
        }                                                                                                              \
    } else {                                                                                                           \
        ch_control->ch##_active = true;                                                                                \
    }                                                                                                                  \
    ch = ch * (ch_control->ch##_active ? 1 : 0);

#define ENVELOPE(ch)                                                                                                   \
    if(ch##_dat->envelope_period) {                                                                                    \
        this->ch##_envelope_timer = (this->ch##_envelope_timer + 1) % (ch##_dat->envelope_period * hz_to_samples(64)); \
        if(this->ch##_envelope_timer == 0) {                                                                           \
            if(ch##_dat->envelope_direction == 0) {                                                                    \
                if(ch##_envelope_vol > 0) ch##_envelope_vol--;                                                         \
            } else {                                                                                                   \
                if(ch##_envelope_vol < 0x0F) ch##_envelope_vol++;                                                      \
            }                                                                                                          \
        }                                                                                                              \
    }                                                                                                                  \
    ch = ch * ch##_envelope_vol / 0x0F;

APU::APU(CPU *cpu, bool debug) {
    SDL_InitSubSystem(SDL_INIT_AUDIO);

    this->cpu = cpu;
    this->debug = debug;

    SDL_AudioSpec desiredSpec, obtainedSpec;
    desiredSpec.freq = HZ;
    desiredSpec.format = AUDIO_U8; // AUDIO_S16SYS;
    desiredSpec.channels = 2;
    desiredSpec.samples = (HZ / 60); // generate audio for one frame at a time, 735 samples per frame
    desiredSpec.callback = audio_callback;
    desiredSpec.userdata = this;
    SDL_OpenAudio(&desiredSpec, &obtainedSpec); // check for errors?
    SDL_PauseAudio(false);
}

APU::~APU() { SDL_CloseAudio(); }

u16 APU::get_next_sample() {
    //=================================================================
    // Control

    ch_control_t *ch_control = (ch_control_t *)&this->cpu->ram->data[Mem::NR50];

    if(!ch_control->snd_enable) {
        // TODO: wipe all registers
        return 0;
    }

    u8 *ram = this->cpu->ram->data;
    u8 ch1 = this->get_ch1_sample(ch_control, (ch1_dat_t *)&ram[Mem::NR10]);
    u8 ch2 = this->get_ch2_sample(ch_control, (ch2_dat_t *)&ram[Mem::NR20]);
    u8 ch3 = this->get_ch3_sample(ch_control, (ch3_dat_t *)&ram[Mem::NR30]);
    u8 ch4 = this->get_ch4_sample(ch_control, (ch4_dat_t *)&ram[Mem::NR40]);

    //=================================================================
    // Mixer

    // clang-format off
    u8 s01 = (
        (ch1 >> 2) * ch_control->ch1_to_s01 +
        (ch2 >> 2) * ch_control->ch2_to_s01 +
        (ch3 >> 2) * ch_control->ch3_to_s01 +
        (ch4 >> 2) * ch_control->ch4_to_s01
    ) * ch_control->s01_volume / 4;
    u8 s02 = (
        (ch1 >> 2) * ch_control->ch1_to_s02 +
        (ch2 >> 2) * ch_control->ch2_to_s02 +
        (ch3 >> 2) * ch_control->ch3_to_s02 +
        (ch4 >> 2) * ch_control->ch4_to_s02
    ) * ch_control->s02_volume / 4;
    // clang-format on
    return s01 << 8 | s02; // s01 = right, s02 = left
}

u8 APU::get_ch1_sample(ch_control_t *ch_control, ch1_dat_t *ch1_dat) {
    //=================================================================
    // Square 1: Sweep -> Timer -> Duty -> Length Counter -> Envelope -> Mixer

    // Sweep
    if(ch1_dat->sweep_period) {
        this->ch1_sweep_timer = (this->ch1_sweep_timer + 1) % (ch1_dat->sweep_period * hz_to_samples(128));
        if(this->ch1_sweep_timer == 0) {
            u8 sweep_adj = ch1_dat->sweep_negate ? -1 : 1;
            this->ch1_sweep += sweep_adj;
        }
    }

    // Timer
    // 1651 -> 330Hz
    u16 ch1_freq = 131072 / (2048 - ((ch1_dat->frequency_msb << 8) | ch1_dat->frequency_lsb));
    // x8 to get through the whole 8-bit cycle every HZ
    // "ch1_freq = 1750" = A = 440Hz.
    this->ch1_freq_timer = (this->ch1_freq_timer + 1) % hz_to_samples(ch1_freq * 8);

    // Duty
    if(this->ch1_freq_timer == 0) {
        this->ch1_duty_pos = (this->ch1_duty_pos + 1) % 8;
    }
    u8 ch1 = duty[ch1_dat->duty][this->ch1_duty_pos] * 0xFF;

    // Length Counter
    LENGTH_COUNTER(ch1);

    // Envelope
    ENVELOPE(ch1);

    // Reset handler
    if(ch1_dat->reset) {
        ch1_dat->reset = 0;
        this->ch1_length = ch1_dat->length_load ? ch1_dat->length_load : 63; // channel enabled
        this->ch1_length_timer = 1;
        this->ch1_freq_timer = 1;                            // frequency timer reloaded with period
        this->ch1_envelope_timer = 1;                        // volume envelope timer is reloaded with period
        this->ch1_envelope_vol = ch1_dat->envelope_vol_load; // volume reloaded from NRx2
        // sweep does "several things"
        this->ch1_sweep_timer = 1;
        this->ch1_shadow_freq = ch1_freq;
    }

    return ch1;
}

u8 APU::get_ch2_sample(ch_control_t *ch_control, ch2_dat_t *ch2_dat) {
    //=================================================================
    // Square 2:          Timer -> Duty -> Length Counter -> Envelope -> Mixer

    // Timer
    u16 ch2_freq = 131072 / (2048 - ((ch2_dat->frequency_msb << 8) | ch2_dat->frequency_lsb));
    this->ch2_freq_timer = (this->ch2_freq_timer + 1) % hz_to_samples(ch2_freq * 8);

    // Duty
    if(ch2_freq_timer == 0) {
        this->ch2_duty_pos = (this->ch2_duty_pos + 1) % 8;
    }
    u8 ch2 = duty[ch2_dat->duty][this->ch2_duty_pos] * 0xFF;

    // Length Counter
    LENGTH_COUNTER(ch2);

    // Envelope
    ENVELOPE(ch2);

    // Reset handler
    if(ch2_dat->reset) {
        ch2_dat->reset = 0;
        this->ch2_length = ch2_dat->length_load ? ch2_dat->length_load : 63; // channel enabled
        this->ch2_length_timer = 1;
        this->ch2_freq_timer = 1;                            // frequency timer reloaded with period
        this->ch2_envelope_timer = 1;                        // volume envelope timer is reloaded with period
        this->ch2_envelope_vol = ch2_dat->envelope_vol_load; // volume reloaded from NRx2
    }

    return ch2;
}

u8 APU::get_ch3_sample(ch_control_t *ch_control, ch3_dat_t *ch3_dat) {
    //=================================================================
    // Wave:              Timer -> Wave -> Length Counter -> Volume -> Mixer

    // Timer
    u16 ch3_freq = 65536 / (2048 - ((ch3_dat->frequency_msb << 8) | ch3_dat->frequency_lsb));
    this->ch3_freq_timer = (this->ch3_freq_timer + 1) % hz_to_samples(ch3_freq * 8);
    // do we want one 4-bit sample, or 32 4-bit samples to appear $freq times per sec?
    // assuming here that we want the whole waveform N times/sec
    if(this->ch3_freq_timer == 0) {
        this->ch3_sample = (this->ch3_sample + 1) % WAVE_LEN;
    }

    // Wave
    u8 ch3 = 127;
    if(ch3_dat->enabled) {
        u8 *ch3_samples = &this->cpu->ram->data[0xFF30]; // until 0xFF3F
        if(this->ch3_sample % 2 == 0) {
            ch3 = ch3_samples[this->ch3_sample / 2] & 0xF0;
        } else {
            ch3 = (ch3_samples[this->ch3_sample / 2] & 0x0F) << 4;
        }
    } else {
        ch3 = 0;
        this->ch3_sample = 0;
    }

    // Length Counter
    LENGTH_COUNTER(ch3);

    // Volume
    if(ch3_dat->volume == 0)
        ch3 = 0;
    else
        ch3 >>= (ch3_dat->volume - 1);

    // Reset handler
    if(ch3_dat->reset) {
        ch3_dat->reset = 0;
        this->ch3_length = ch3_dat->length_load ? ch3_dat->length_load : 255; // channel enabled
        this->ch3_length_timer = 1;
        this->ch3_freq_timer = 1; // frequency timer reloaded with period
        this->ch3_sample = 0;     // wave channel's position set to 0
    }
    return ch3;
}

u8 APU::get_ch4_sample(ch_control_t *ch_control, ch4_dat_t *ch4_dat) {
    //=================================================================
    // Noise:             Timer -> LFSR -> Length Counter -> Envelope -> Mixer

    // Timer
    int ch4_div = 0;
    switch(ch4_dat->divisor_code) {
        case 0: ch4_div = 8; break;
        case 1: ch4_div = 16; break;
        case 2: ch4_div = 32; break;
        case 3: ch4_div = 48; break;
        case 4: ch4_div = 64; break;
        case 5: ch4_div = 80; break;
        case 6: ch4_div = 96; break;
        case 7: ch4_div = 112; break;
    }
    this->ch4_freq_timer = (this->ch4_freq_timer + 1) % (ch4_div << ch4_dat->clock_shift);

    // LFSR
    if(this->ch4_freq_timer == 0) {
        u8 new_bit = ((ch4_lfsr & 0b10) >> 1) ^ (ch4_lfsr & 0b01);                      // xor two low bits
        ch4_lfsr >>= 1;                                                                 // shift right
        ch4_lfsr |= new_bit << 14;                                                      // bit15 = new
        if(ch4_dat->lfsr_mode == 1) ch4_lfsr = (ch4_lfsr & ~(1 << 6)) | (new_bit << 6); // bit7 = new
    }
    u8 ch4 = 0xFF - ((ch4_lfsr & 0b01) * 0xFF); // bit0, inverted

    // Length Counter
    LENGTH_COUNTER(ch4);

    // Envelope
    ENVELOPE(ch4);

    // Reset handler
    if(ch4_dat->reset) {
        ch4_dat->reset = 0;
        this->ch4_length = ch4_dat->length_load ? ch4_dat->length_load : 63; // channel enabled
        this->ch4_length_timer = 1;
        this->ch4_freq_timer = 1;                            // frequency timer reloaded with period
        this->ch4_envelope_timer = 1;                        // volume envelope timer is reloaded with period
        this->ch4_envelope_vol = ch4_dat->envelope_vol_load; // volume reloaded from NRx2
        this->ch4_lfsr = 0xFFFF;                             // ch4_lfsr bits all set to 1
    }

    return ch4;
}

void audio_callback(void *_sound, Uint8 *_stream, int _length) {
    u16 *stream = (u16 *)_stream;
    APU *sound = (APU *)_sound;
    int length = _length / sizeof(stream[0]);

    for(int i = 0; i < length; i++) {
        stream[i] = sound->get_next_sample();
    }
}
