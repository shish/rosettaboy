#ifndef ROSETTABOY_APU_H
#define ROSETTABOY_APU_H

#include "consts.h"

struct APU {
    struct CPU *cpu;
    struct RAM *ram;
    bool debug;
    int ch1_freq_timer;
    int ch2_freq_timer;
    int ch3_freq_timer;
    int ch4_freq_timer;
    int ch1_envelope_vol;
    int ch2_envelope_vol;
    int ch4_envelope_vol;
    int ch1_sweep_timer;
    int ch1_shadow_freq;
    int ch1_envelope_timer;
    int ch2_envelope_timer;
    int ch4_envelope_timer;
    int ch1_length_timer;
    int ch2_length_timer;
    int ch3_length_timer;
    int ch4_length_timer;
    int ch1_length;
    int ch2_length;
    int ch3_length;
    int ch4_length;
    u8 ch1_sweep;
    u8 ch1_duty_pos;
    u8 ch2_duty_pos;
    u8 ch3_sample;
    u16 ch4_lfsr;
};

void apu_ctor(struct APU *self, struct CPU *cpu, struct RAM *ram, bool debug);
void apu_dtor(struct APU *apu);

#endif // ROSETTABOY_APU_H
