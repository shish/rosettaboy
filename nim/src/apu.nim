type
    APU* = ref object
        silent: bool
        debug: bool
        ch1_freq_timer, ch2_freq_timer, ch3_freq_timer, ch4_freq_timer: int
        ch1_envelope_vol, ch2_envelope_vol, ch4_envelope_vol: int
        ch1_sweep_timer, ch1_shadow_freq: int
        ch1_envelope_timer, ch2_envelope_timer, ch4_envelope_timer: int
        ch1_length_timer, ch2_length_timer, ch3_length_timer, ch4_length_timer: int
        ch1_length, ch2_length, ch3_length, ch4_length: int
        ch1_sweep, ch1_duty_pos, ch2_duty_pos, ch3_sample: uint8
        ch4_lfsr: uint16

proc create*(silent: bool, debug: bool): APU =
    return APU(
      silent: silent,
      debug: debug,
    )

# FIXME: implement this
proc tick*(apu: APU) =
    return
