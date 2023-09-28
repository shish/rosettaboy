package main

import "github.com/veandco/go-sdl2/sdl"

const WAVE_LEN uint8 = 32
const HZ uint16 = 48000

var DUTY [][]uint8 = [][]uint8{
	{0, 0, 0, 0, 0, 0, 0, 1},
	{1, 0, 0, 0, 0, 0, 0, 1},
	{1, 0, 0, 0, 0, 1, 1, 1},
	{0, 1, 1, 1, 1, 1, 1, 0},
}

// //#[derive(Default, Debug, PackedStruct)]
// #[packed_struct(bit_numbering = "msb0")]
type Ch1Control struct {
	// NR10
	// The change of frequency (NR13,NR14) at each shift is calculated by the
	// following formula where X(0) is initial freq & X(t-1) is last freq:
	// X(t) = X(t-1) +/- X(t-1)/2^n
	// //#[packed_field(bits="0")]
	//#[packed_field(bits = "1:3")]
	sweep_period uint8 // 3  // inc or dec each n/128Hz = (n*44100)/128smp = n*344smp
	//#[packed_field(bits = "4")]
	sweep_negate bool // ? -1 : 1
	//#[packed_field(bits = "5:7")]
	sweep_shift uint8 // 3  // 0 = stop envelope

	// NR11
	//#[packed_field(bits = "8:9")]
	duty uint8 // 2  // {12.5, 25, 50, 75}%
	//#[packed_field(bits = "10:15")]
	length_load uint8 // 6  // (64-n) * (1/256) seconds

	// NR12
	//#[packed_field(bits = "16:19")]
	envelope_vol_load uint8 // 4
	//#[packed_field(bits = "20")]
	envelope_direction bool
	//#[packed_field(bits = "21:23")]
	envelope_period uint8 // 3  // 1 step = n * (1/64) seconds

	// NR13
	//#[packed_field(bits = "24:31")]
	frequency_lsb uint8 // 8

	// NR14
	//#[packed_field(bits = "32")]
	reset bool
	//#[packed_field(bits = "33")]
	length_enable bool
	// //#[packed_field(bits="34:36")]
	//#[packed_field(bits = "37:39")]
	frequency_msb uint8 // 3
}

// #[derive(Default, Debug)]
type Ch1State struct {
	duty_pos       uint8
	envelope_timer int
	envelope_vol   uint8
	freq_timer     int
	length         uint8
	length_timer   int
	shadow_freq    uint16
	sweep          uint8
	sweep_timer    int
}

// #[derive(Default, Debug, PackedStruct)]
// #[packed_struct(bit_numbering = "msb0")]
type Ch2Control struct {
	// NR20
	//#[packed_field(bits = "0:7")]
	_reserved1 uint8 // : ReservedZeroes<packed_bits::Bits8>,

	// NR21
	//#[packed_field(bits = "8:9")]
	duty uint8 // 2  // {12.5, 25, 50, 75}%
	//#[packed_field(bits = "10:15")]
	length_load uint8 // 6  // (64-n) * (1/256) seconds

	// NR22
	//#[packed_field(bits = "16:19")]
	envelope_vol_load uint8 // 4
	//#[packed_field(bits = "20")]
	envelope_direction bool
	//#[packed_field(bits = "21:23")]
	envelope_period uint8 // 3  // 1 step = n * (1/64) seconds

	// NR23
	//#[packed_field(bits = "24:31")]
	frequency_lsb uint8 // 8

	// NR24
	//#[packed_field(bits = "32")]
	reset bool
	//#[packed_field(bits = "33")]
	length_enable bool
	// //#[packed_field(bits="34:36")]
	//#[packed_field(bits = "37:39")]
	frequency_msb uint8 // 3
}

// #[derive(Default, Debug)]
type Ch2State struct {
	duty_pos       uint8
	envelope_timer int
	envelope_vol   uint8
	freq_timer     int
	length         uint8
	length_timer   int
}

// #[derive(Default, Debug, PackedStruct)]
// #[packed_struct(bit_numbering = "msb0")]
type Ch3Control struct {
	// NR30
	//#[packed_field(bits = "0")]
	enabled bool
	// //#[packed_field(bits="1:7")]

	// NR31
	//#[packed_field(bits = "8:15")]
	length_load uint8 // (256-n) * (1/256) seconds

	// NR32
	// //#[packed_field(bits="16")]
	//#[packed_field(bits = "17:18")]
	volume uint8 // 2  // {0,100,50,25}%
	// //#[packed_field(bits="19:23")]

	// NR33
	//#[packed_field(bits = "24:31")]
	frequency_lsb uint8 // 8

	// NR34
	//#[packed_field(bits = "32")]
	reset bool
	//#[packed_field(bits = "33")]
	length_enable bool
	// //#[packed_field(bits="34:36")]
	//#[packed_field(bits = "37:39")]
	frequency_msb uint8 // 3
}

// #[derive(Default, Debug)]
type Ch3State struct {
	freq_timer   int
	length       uint8
	length_timer int
	sample       uint8
}

// #[derive(Default, Debug, PackedStruct)]
// #[packed_struct(bit_numbering = "msb0")]
type Ch4Control struct {
	// NR40
	// //#[packed_field(bits="0:7")]

	// NR41
	// //#[packed_field(bits="8:9")]
	//#[packed_field(bits = "10:15")]
	length_load uint8 // (64-n) * (1/256) seconds

	// NR42
	//#[packed_field(bits = "16:19")]
	envelope_vol_load uint8
	//#[packed_field(bits = "20")]
	envelope_direction bool
	//#[packed_field(bits = "21:23")]
	envelope_period uint8 // 1 step = n * (1/64) seconds

	// NR43
	//#[packed_field(bits = "24:27")]
	clock_shift uint8 // 4
	//#[packed_field(bits = "28")]
	lfsr_mode bool
	//#[packed_field(bits = "29:31")]
	divisor_code uint8 // 3

	// NR44
	//#[packed_field(bits = "32")]
	reset bool
	//#[packed_field(bits = "33")]
	length_enable bool
	// //#[packed_field(bits="34:39")]
}

// #[derive(Default, Debug)]
type Ch4State struct {
	// Internal state
	envelope_timer int
	envelope_vol   uint8
	freq_timer     int
	length         uint8
	length_timer   int
	lfsr           uint16 // = 0xFFFF;
}

// #[derive(Default, Debug, PackedStruct)]
// #[packed_struct(bit_numbering = "msb0")]
type Control struct {
	// NR50
	//#[packed_field(bits = "0")]
	enable_vin_to_s02 bool
	//#[packed_field(bits = "1:3")]
	s02_volume uint8 // Integer<u8, packed_bits::Bits3>,
	//#[packed_field(bits = "4")]
	enable_vin_to_s01 bool
	//#[packed_field(bits = "5:7")]
	s01_volume uint8 // Integer<u8, packed_bits::Bits3>,

	// NR51
	//#[packed_field(bits = "8")]
	ch4_to_s02 uint8
	//#[packed_field(bits = "9")]
	ch3_to_s02 uint8
	//#[packed_field(bits = "10")]
	ch2_to_s02 uint8
	//#[packed_field(bits = "11")]
	ch1_to_s02 uint8
	//#[packed_field(bits = "12")]
	ch4_to_s01 uint8
	//#[packed_field(bits = "13")]
	ch3_to_s01 uint8
	//#[packed_field(bits = "14")]
	ch2_to_s01 uint8
	//#[packed_field(bits = "15")]
	ch1_to_s01 uint8

	// NR52
	//#[packed_field(bits = "16")]
	snd_enable bool
	// //#[packed_field(bits="17:19")]
	//#[packed_field(bits = "20")]
	ch4_active bool
	//#[packed_field(bits = "21")]
	ch3_active bool
	//#[packed_field(bits = "22")]
	ch2_active bool
	//#[packed_field(bits = "23")]
	ch1_active bool
}

type APU struct {
	device sdl.AudioDeviceID
	debug  bool
	cpu    *CPU
	silent bool
	cycle  int

	ch1     Ch1Control
	ch1s    Ch1State
	ch2     Ch2Control
	ch2s    Ch2State
	ch3     Ch3Control
	ch3s    Ch3State
	ch4     Ch4Control
	ch4s    Ch4State
	control Control
	samples []uint8 // 16
}

func NewAPU(cpu *CPU, debug bool, silent bool) (*APU, error) {
	var device sdl.AudioDeviceID = 0
	if !silent {
		if err := sdl.Init(uint32(sdl.INIT_AUDIO)); err != nil {
			return nil, err
		}

		var spec = sdl.AudioSpec{
			Freq:     int32(HZ),
			Format:   123,
			Channels: 2,
			Silence:  0,
			// generate audio for one frame at a time, 735 samples per frame
			Samples: HZ / 60,
			//_: 0,
			Size:     0,
			Callback: nil,
			UserData: nil,
		}
		_device, err := sdl.OpenAudioDevice("", false, &spec, &spec, 1)
		if err != nil {
			return nil, err
		}
		device = _device
		//device.resume()
	}

	return &APU{
		device, debug, cpu, silent, 0,
		Ch1Control{0, false, 0, 0, 0, 0, false, 0, 0, false, false, 0},
		Ch1State{0, 0, 0, 0, 0, 0, 0, 0, 0},
		Ch2Control{0, 0, 0, 0, false, 0, 0, false, false, 0},
		Ch2State{0, 0, 0, 0, 0, 0},
		Ch3Control{false, 0, 0, 0, false, false, 0},
		Ch3State{0, 0, 0, 0},
		Ch4Control{0, 0, false, 0, 0, false, 0, false, false},
		Ch4State{0, 0, 0, 0, 0, 0xFFFF},
		Control{false, 0, false, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, false, false, false, false},
		make([]uint8, 16),
	}, nil
}

func (apu *APU) tick() {
	apu.cycle += 1

	// Ideally this would be in sync every tick, but
	// once per frame should be sufficient...?
	if apu.cycle%17556 == 20 {
		var out = apu.render_frame_audio()

		if apu.device > 0 {
			// println!("size = {}", device.size());
			if int(sdl.GetQueuedAudioSize(apu.device)) <= int((HZ/60)*2) {
				sdl.QueueAudio(apu.device, out)
				sdl.QueueAudio(apu.device, out)
			}
			sdl.QueueAudio(apu.device, out)
		}
	}
}

func (apu *APU) render_frame_audio() []uint8 { // return len = HZ / 60
	var audio_controls = apu.cpu.ram.data[IO_NR10 : IO_NR10+23]
	var out = make([]uint8, HZ/60)

	apu.ram_to_regs(audio_controls)
	var sample uint16 = 0
	for n := range out {
		if n%2 == 0 {
			sample = apu.get_next_sample()
			out[n] = uint8((sample & 0xFF00) >> 8)
		} else {
			out[n] = uint8((sample & 0x00FF) >> 0)
		}
	}
	apu.regs_to_ram(audio_controls)
	return out
}

func (apu *APU) ram_to_regs(buffer []uint8) {
	apu.ch1 = ch1unpack(buffer[0:4])
	apu.ch2 = ch2unpack(buffer[5:9])
	apu.ch3 = ch3unpack(buffer[10:14])
	apu.ch4 = ch4unpack(buffer[15:19])
	apu.control = conunpack(buffer[20:22])
}

func ch1unpack(buffer []uint8) Ch1Control {
	return Ch1Control{}
}
func ch2unpack(buffer []uint8) Ch2Control {
	return Ch2Control{}
}
func ch3unpack(buffer []uint8) Ch3Control {
	return Ch3Control{}
}
func ch4unpack(buffer []uint8) Ch4Control {
	return Ch4Control{}
}
func conunpack(buffer []uint8) Control {
	return Control{}
}

func (apu *Ch1Control) pack() []uint8 {
	return make([]uint8, 5)
}
func (apu *Ch2Control) pack() []uint8 {
	return make([]uint8, 5)
}
func (apu *Ch3Control) pack() []uint8 {
	return make([]uint8, 5)
}
func (apu *Ch4Control) pack() []uint8 {
	return make([]uint8, 5)
}
func (apu *Control) pack() []uint8 {
	return make([]uint8, 3)
}

func (apu *APU) regs_to_ram(buffer []uint8) {
	var cbuf = apu.ch1.pack()
	buffer[0] = cbuf[0]
	buffer[0] = cbuf[0]
	buffer[1] = cbuf[1]
	buffer[2] = cbuf[2]
	buffer[3] = cbuf[3]
	buffer[4] = cbuf[4]

	cbuf = apu.ch2.pack()
	buffer[5] = cbuf[0]
	buffer[6] = cbuf[1]
	buffer[7] = cbuf[2]
	buffer[8] = cbuf[3]
	buffer[9] = cbuf[4]

	cbuf = apu.ch3.pack()
	buffer[10] = cbuf[0]
	buffer[11] = cbuf[1]
	buffer[12] = cbuf[2]
	buffer[13] = cbuf[3]
	buffer[14] = cbuf[4]

	cbuf = apu.ch4.pack()
	buffer[15] = cbuf[0]
	buffer[16] = cbuf[1]
	buffer[17] = cbuf[2]
	buffer[18] = cbuf[3]
	buffer[19] = cbuf[4]

	cbuf = apu.control.pack()
	buffer[20] = cbuf[0]
	buffer[21] = cbuf[1]
	buffer[22] = cbuf[2]
}

func (apu *APU) get_next_sample() uint16 {
	if !apu.control.snd_enable {
		// TODO: wipe all registers
		return 0
	}

	var ch1 = apu.get_ch1_sample()
	var ch2 = apu.get_ch2_sample()
	var ch3 = apu.get_ch3_sample()
	var ch4 = apu.get_ch4_sample()

	var s01 uint8 = (((ch1>>2)*apu.control.ch1_to_s01 +
		(ch2>>2)*apu.control.ch2_to_s01 +
		(ch3>>2)*apu.control.ch3_to_s01 +
		(ch4>>2)*apu.control.ch4_to_s01) *
		apu.control.s01_volume / 4)
	var s02 uint8 = (((ch1>>2)*apu.control.ch1_to_s02 +
		(ch2>>2)*apu.control.ch2_to_s02 +
		(ch3>>2)*apu.control.ch3_to_s02 +
		(ch4>>2)*apu.control.ch4_to_s02) *
		apu.control.s02_volume / 4)

	return (uint16(s01) << 8) | uint16(s02) // s01 = right, s02 = left
}

func (apu *APU) get_ch1_sample() uint8 {
	// FIXME
	return 0
}
func (apu *APU) get_ch2_sample() uint8 {
	// FIXME
	return 0
}
func (apu *APU) get_ch3_sample() uint8 {
	// FIXME
	return 0
}
func (apu *APU) get_ch4_sample() uint8 {
	// FIXME
	return 0
}
