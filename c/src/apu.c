#include <SDL2/SDL.h>

#include "apu.h"
#include "ram.h"

static int WAVE_LEN = 32;

static u32 HZ = 48000; // 44100;

static u8 duty[4][8] = {
    {1, 0, 0, 0, 0, 0, 0, 0},
    {1, 1, 0, 0, 0, 0, 0, 0},
    {1, 1, 1, 1, 0, 0, 0, 0},
    {1, 1, 1, 1, 1, 1, 0, 0},
};

struct ch1_dat_t {
    // NR10
    // The change of frequency (NR13,NR14) at each shift is calculated by the
    // following formula where X(0) is initial freq & X(t-1) is last freq:
    // X(t) = X(t-1) +/- X(t-1)/2^n
    unsigned int sweep_shift : 3;  // 0 = stop envelope
    unsigned int sweep_negate : 1; // ? -1 : 1
    unsigned int sweep_period : 3; // inc or dec each n/128Hz = (n*44100)/128smp = n*344smp
    unsigned int empty1 : 1;

    // NR11
    unsigned int length_load : 6; // (64-n) * (1/256) seconds
    unsigned int duty : 2;        // {12.5, 25, 50, 75}%

    // NR12
    unsigned int envelope_period : 3; // 1 step = n * (1/64) seconds
    unsigned int envelope_direction : 1;
    unsigned int envelope_vol_load : 4;

    // NR13
    unsigned int frequency_lsb : 8;

    // NR14
    unsigned int frequency_msb : 3;
    unsigned int empty2 : 3;
    unsigned int length_enable : 1;
    unsigned int reset : 1;
};

struct ch2_dat_t {
    // NR20
    unsigned int empty1 : 8;

    // NR21
    unsigned int length_load : 6; // (64-n) * (1/256) seconds
    unsigned int duty : 2;        // {12.5, 25, 50, 75}%

    // NR22
    unsigned int envelope_period : 3; // 1 step = n * (1/64) seconds
    unsigned int envelope_direction : 1;
    unsigned int envelope_vol_load : 4;

    // NR23
    unsigned int frequency_lsb : 8;

    // NR24
    unsigned int frequency_msb : 3;
    unsigned int empty2 : 3;
    unsigned int length_enable : 1;
    unsigned int reset : 1;
};

struct ch3_dat_t {
    // NR30
    unsigned int empty1 : 7;
    unsigned int enabled : 1;

    // NR31
    unsigned int length_load : 8; // (256-n) * (1/256) seconds

    // NR32
    unsigned int empty3 : 5;
    unsigned int volume : 2; // {0,100,50,25}%
    unsigned int empty2 : 1;

    // NR33
    unsigned int frequency_lsb : 8;

    // NR34
    unsigned int frequency_msb : 3;
    unsigned int empty4 : 3;
    unsigned int length_enable : 1;
    unsigned int reset : 1;
};

struct ch4_dat_t {
    // NR40
    unsigned int empty1 : 8;

    // NR41
    unsigned int length_load : 6; // (64-n) * (1/256) seconds
    unsigned int empty2 : 2;

    // NR42
    unsigned int envelope_period : 3; // 1 step = n * (1/64) seconds
    unsigned int envelope_direction : 1;
    unsigned int envelope_vol_load : 4;

    // NR43
    unsigned int divisor_code : 3;
    unsigned int lfsr_mode : 1;
    unsigned int clock_shift : 4;

    // NR44
    unsigned int empty3 : 6;
    unsigned int length_enable : 1;
    unsigned int reset : 1;
};

struct ch_control_t {
    // NR50
    unsigned int s01_volume : 3;
    unsigned int enable_vin_to_s01 : 1;
    unsigned int s02_volume : 3;
    unsigned int enable_vin_to_s02 : 1;

    // NR51
    unsigned int ch1_to_s01 : 1;
    unsigned int ch2_to_s01 : 1;
    unsigned int ch3_to_s01 : 1;
    unsigned int ch4_to_s01 : 1;
    unsigned int ch1_to_s02 : 1;
    unsigned int ch2_to_s02 : 1;
    unsigned int ch3_to_s02 : 1;
    unsigned int ch4_to_s02 : 1;

    // NR52
    unsigned int ch1_active : 1;
    unsigned int ch2_active : 1;
    unsigned int ch3_active : 1;
    unsigned int ch4_active : 1;
    unsigned int empty : 3;
    unsigned int snd_enable : 1;
};

static inline int hz_to_samples(int hz) {
    if (hz == 0)
        return HZ;
    if (hz > HZ)
        return 1;
    return HZ / hz;
}

#define LENGTH_COUNTER(ch)                                                                                             \
    if (ch##_dat->length_enable == 1) {                                                                                \
        if (self->ch##_length > 0) {                                                                                   \
            self->ch##_length_timer = (self->ch##_length_timer + 1) % hz_to_samples(256);                              \
            if (self->ch##_length_timer == 0)                                                                          \
                self->ch##_length--;                                                                                   \
            ch_control->ch##_active = true;                                                                            \
        } else {                                                                                                       \
            ch_control->ch##_active = false;                                                                           \
        }                                                                                                              \
    } else {                                                                                                           \
        ch_control->ch##_active = true;                                                                                \
    }                                                                                                                  \
    ch = ch * (ch_control->ch##_active ? 1 : 0);

#define ENVELOPE(ch)                                                                                                   \
    if (ch##_dat->envelope_period) {                                                                                   \
        self->ch##_envelope_timer = (self->ch##_envelope_timer + 1) % (ch##_dat->envelope_period * hz_to_samples(64)); \
        if (self->ch##_envelope_timer == 0) {                                                                          \
            if (ch##_dat->envelope_direction == 0) {                                                                   \
                if (self->ch##_envelope_vol > 0)                                                                       \
                    self->ch##_envelope_vol--;                                                                         \
            } else {                                                                                                   \
                if (self->ch##_envelope_vol < 0x0F)                                                                    \
                    self->ch##_envelope_vol++;                                                                         \
            }                                                                                                          \
        }                                                                                                              \
    }                                                                                                                  \
    ch = ch * self->ch##_envelope_vol / 0x0F;

static inline u8 apu_get_ch1_sample(struct APU *self, struct ch_control_t *ch_control, struct ch1_dat_t *ch1_dat) {
    //=================================================================
    // Square 1: Sweep -> Timer -> Duty -> Length Counter -> Envelope -> Mixer

    // Sweep
    if (ch1_dat->sweep_period) {
        self->ch1_sweep_timer = (self->ch1_sweep_timer + 1) % (ch1_dat->sweep_period * hz_to_samples(128));
        if (self->ch1_sweep_timer == 0) {
            u8 sweep_adj = ch1_dat->sweep_negate ? -1 : 1;
            self->ch1_sweep += sweep_adj;
        }
    }

    // Timer
    // 1651 -> 330Hz
    u16 ch1_freq = 131072 / (2048 - ((ch1_dat->frequency_msb << 8) | ch1_dat->frequency_lsb));
    // x8 to get through the whole 8-bit cycle every HZ
    // "ch1_freq = 1750" = A = 440Hz.
    self->ch1_freq_timer = (self->ch1_freq_timer + 1) % hz_to_samples(ch1_freq * 8);

    // Duty
    if (self->ch1_freq_timer == 0) {
        self->ch1_duty_pos = (self->ch1_duty_pos + 1) % 8;
    }
    u8 ch1 = duty[ch1_dat->duty][self->ch1_duty_pos] * 0xFF;

    // Length Counter
    LENGTH_COUNTER(ch1);

    // Envelope
    ENVELOPE(ch1);

    // Reset handler
    if (ch1_dat->reset) {
        ch1_dat->reset = 0;
        self->ch1_length = ch1_dat->length_load ? ch1_dat->length_load : 63; // channel enabled
        self->ch1_length_timer = 1;
        self->ch1_freq_timer = 1;                            // frequency timer reloaded with period
        self->ch1_envelope_timer = 1;                        // volume envelope timer is reloaded with period
        self->ch1_envelope_vol = ch1_dat->envelope_vol_load; // volume reloaded from NRx2
        // sweep does "several things"
        self->ch1_sweep_timer = 1;
        self->ch1_shadow_freq = ch1_freq;
    }

    return ch1;
}

static inline u8 apu_get_ch2_sample(struct APU *self, struct ch_control_t *ch_control, struct ch2_dat_t *ch2_dat) {
    //=================================================================
    // Square 2:          Timer -> Duty -> Length Counter -> Envelope -> Mixer

    // Timer
    u16 ch2_freq = 131072 / (2048 - ((ch2_dat->frequency_msb << 8) | ch2_dat->frequency_lsb));
    self->ch2_freq_timer = (self->ch2_freq_timer + 1) % hz_to_samples(ch2_freq * 8);

    // Duty
    if (self->ch2_freq_timer == 0) {
        self->ch2_duty_pos = (self->ch2_duty_pos + 1) % 8;
    }
    u8 ch2 = duty[ch2_dat->duty][self->ch2_duty_pos] * 0xFF;

    // Length Counter
    LENGTH_COUNTER(ch2);

    // Envelope
    ENVELOPE(ch2);

    // Reset handler
    if (ch2_dat->reset) {
        ch2_dat->reset = 0;
        self->ch2_length = ch2_dat->length_load ? ch2_dat->length_load : 63; // channel enabled
        self->ch2_length_timer = 1;
        self->ch2_freq_timer = 1;                            // frequency timer reloaded with period
        self->ch2_envelope_timer = 1;                        // volume envelope timer is reloaded with period
        self->ch2_envelope_vol = ch2_dat->envelope_vol_load; // volume reloaded from NRx2
    }

    return ch2;
}

static inline u8 apu_get_ch3_sample(struct APU *self, struct ch_control_t *ch_control, struct ch3_dat_t *ch3_dat) {
    //=================================================================
    // Wave:              Timer -> Wave -> Length Counter -> Volume -> Mixer

    // Timer
    u16 ch3_freq = 65536 / (2048 - ((ch3_dat->frequency_msb << 8) | ch3_dat->frequency_lsb));
    self->ch3_freq_timer = (self->ch3_freq_timer + 1) % hz_to_samples(ch3_freq * 8);
    // do we want one 4-bit sample, or 32 4-bit samples to appear $freq times per sec?
    // assuming here that we want the whole waveform N times/sec
    if (self->ch3_freq_timer == 0) {
        self->ch3_sample = (self->ch3_sample + 1) % WAVE_LEN;
    }

    // Wave
    u8 ch3 = 127;
    if (ch3_dat->enabled) {
        u8 *ch3_samples = &self->ram->data[0xFF30]; // until 0xFF3F
        if (self->ch3_sample % 2 == 0) {
            ch3 = ch3_samples[self->ch3_sample / 2] & 0xF0;
        } else {
            ch3 = (ch3_samples[self->ch3_sample / 2] & 0x0F) << 4;
        }
    } else {
        ch3 = 0;
        self->ch3_sample = 0;
    }

    // Length Counter
    LENGTH_COUNTER(ch3);

    // Volume
    if (ch3_dat->volume == 0)
        ch3 = 0;
    else
        ch3 >>= (ch3_dat->volume - 1);

    // Reset handler
    if (ch3_dat->reset) {
        ch3_dat->reset = 0;
        self->ch3_length = ch3_dat->length_load ? ch3_dat->length_load : 255; // channel enabled
        self->ch3_length_timer = 1;
        self->ch3_freq_timer = 1; // frequency timer reloaded with period
        self->ch3_sample = 0;     // wave channel's position set to 0
    }
    return ch3;
}

static inline u8 apu_get_ch4_sample(struct APU *self, struct ch_control_t *ch_control, struct ch4_dat_t *ch4_dat) {
    //=================================================================
    // Noise:             Timer -> LFSR -> Length Counter -> Envelope -> Mixer

    // Timer
    int ch4_div = 0;
    switch (ch4_dat->divisor_code) {
        case 0:
            ch4_div = 8;
            break;
        case 1:
            ch4_div = 16;
            break;
        case 2:
            ch4_div = 32;
            break;
        case 3:
            ch4_div = 48;
            break;
        case 4:
            ch4_div = 64;
            break;
        case 5:
            ch4_div = 80;
            break;
        case 6:
            ch4_div = 96;
            break;
        case 7:
            ch4_div = 112;
            break;
    }
    self->ch4_freq_timer = (self->ch4_freq_timer + 1) % (ch4_div << ch4_dat->clock_shift);

    // LFSR
    if (self->ch4_freq_timer == 0) {
        u8 new_bit = ((self->ch4_lfsr & 0b10) >> 1) ^ (self->ch4_lfsr & 0b01); // xor two low bits
        self->ch4_lfsr >>= 1;                                                  // shift right
        self->ch4_lfsr |= new_bit << 14;                                       // bit15 = new
        if (ch4_dat->lfsr_mode == 1)
            self->ch4_lfsr = (self->ch4_lfsr & ~(1 << 6)) | (new_bit << 6); // bit7 = new
    }
    u8 ch4 = 0xFF - ((self->ch4_lfsr & 0b01) * 0xFF); // bit0, inverted

    // Length Counter
    LENGTH_COUNTER(ch4);

    // Envelope
    ENVELOPE(ch4);

    // Reset handler
    if (ch4_dat->reset) {
        ch4_dat->reset = 0;
        self->ch4_length = ch4_dat->length_load ? ch4_dat->length_load : 63; // channel enabled
        self->ch4_length_timer = 1;
        self->ch4_freq_timer = 1;                            // frequency timer reloaded with period
        self->ch4_envelope_timer = 1;                        // volume envelope timer is reloaded with period
        self->ch4_envelope_vol = ch4_dat->envelope_vol_load; // volume reloaded from NRx2
        self->ch4_lfsr = 0xFFFF;                             // ch4_lfsr bits all set to 1
    }

    return ch4;
}

static inline u16 apu_get_next_sample(struct APU *self) {
    //=================================================================
    // Control

    struct ch_control_t *ch_control = (struct ch_control_t *) &self->ram->data[MEM_NR50];

    if (!ch_control->snd_enable) {
        // TODO: wipe all registers
        return 0;
    }

    u8 *ram = self->ram->data;
    u8 ch1 = apu_get_ch1_sample(self, ch_control, (struct ch1_dat_t *) &ram[MEM_NR10]);
    u8 ch2 = apu_get_ch2_sample(self, ch_control, (struct ch2_dat_t *) &ram[MEM_NR20]);
    u8 ch3 = apu_get_ch3_sample(self, ch_control, (struct ch3_dat_t *) &ram[MEM_NR30]);
    u8 ch4 = apu_get_ch4_sample(self, ch_control, (struct ch4_dat_t *) &ram[MEM_NR40]);

    //=================================================================
    // Mixer

    u8 s01 = ((ch1 >> 2) * ch_control->ch1_to_s01 + (ch2 >> 2) * ch_control->ch2_to_s01 +
              (ch3 >> 2) * ch_control->ch3_to_s01 + (ch4 >> 2) * ch_control->ch4_to_s01) *
             ch_control->s01_volume / 4;
    u8 s02 = ((ch1 >> 2) * ch_control->ch1_to_s02 + (ch2 >> 2) * ch_control->ch2_to_s02 +
              (ch3 >> 2) * ch_control->ch3_to_s02 + (ch4 >> 2) * ch_control->ch4_to_s02) *
             ch_control->s02_volume / 4;
    return s01 << 8 | s02; // s01 = right, s02 = left
}

static void audio_callback(void *_sound, Uint8 *_stream, int _length) {
    u16 *stream = (u16 *) _stream;
    struct APU *sound = (struct APU *) _sound;
    int length = _length / sizeof(stream[0]);

    for (int i = 0; i < length; i++) {
        stream[i] = apu_get_next_sample(sound);
    }
}

void apu_ctor(struct APU *self, struct CPU *cpu, struct RAM *ram, bool debug) {
    self->cpu = cpu;
    self->ram = ram;
    self->debug = debug;
    self->ch4_lfsr = 0xFFFF;

    SDL_InitSubSystem(SDL_INIT_AUDIO);

    SDL_AudioSpec desiredSpec, obtainedSpec;
    desiredSpec.freq = HZ;
    desiredSpec.format = AUDIO_U8; // AUDIO_S16SYS;
    desiredSpec.channels = 2;
    desiredSpec.samples = (HZ / 60); // generate audio for one frame at a time, 735 samples per frame
    desiredSpec.callback = audio_callback;
    desiredSpec.userdata = self;
    SDL_OpenAudio(&desiredSpec, &obtainedSpec); // check for errors?
    SDL_PauseAudio(false);
}

void apu_dtor(struct APU *apu) {
    SDL_CloseAudio();
}
