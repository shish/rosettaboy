#ifndef ROSETTABOY_APU_H
#define ROSETTABOY_APU_H

#include <SDL2/SDL.h>

#include "cpu.h"

static int WAVE_LEN = 32;

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

class APU {
private:
    bool debug = false;
    int ch1_freq_timer = 0, ch2_freq_timer = 0, ch3_freq_timer = 0, ch4_freq_timer = 0;
    int ch1_envelope_vol = 0, ch2_envelope_vol = 0, ch4_envelope_vol = 0;
    int ch1_sweep_timer = 0, ch1_shadow_freq = 0;
    int ch1_envelope_timer = 0, ch2_envelope_timer = 0, ch4_envelope_timer = 0;
    int ch1_length_timer = 0, ch2_length_timer = 0, ch3_length_timer = 0, ch4_length_timer = 0;
    int ch1_length = 0, ch2_length = 0, ch3_length = 0, ch4_length = 0;
    u8 ch1_sweep = 0;
    u8 ch1_duty_pos = 0;
    u8 ch2_duty_pos = 0;
    u8 ch3_sample = 0;
    u16 ch4_lfsr = 0xFFFF;

public:
    CPU *cpu = nullptr;

public:
    APU(CPU *cpu, bool debug);
    ~APU();
    u16 get_next_sample();

private:
    u8 get_ch1_sample(ch_control_t *ch_control, ch1_dat_t *ch_dat);
    u8 get_ch2_sample(ch_control_t *ch_control, ch2_dat_t *ch_dat);
    u8 get_ch3_sample(ch_control_t *ch_control, ch3_dat_t *ch_dat);
    u8 get_ch4_sample(ch_control_t *ch_control, ch4_dat_t *ch_dat);
};

void audio_callback(void *, Uint8 *, int);

#endif // ROSETTABOY_APU_H
