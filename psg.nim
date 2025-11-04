## This module implements the low level driver for the AY38910A programmable
## sound generator chip. This is achieved by providing the following features:
##   - interfacing with the AY38910A address/data bus
##   - interfacing with the AY38910A bus control line
##
## Note that the PSG needs a 2MHz clock signal as input to properly work with
## this library, which you should provide when initializing the Ay38910.

import std/[bitops, math]

import avr_io
import writer
import delay

export writer


const 
  octaves*      = 8 ## Number of supported octaves.
  notes_in_oct* = 12
  tot_notes     = notes_in_oct * octaves + 1


## The AY38910A tone generation works in the following way: the clock signal
## gets scaled by a factor of 16 and by an additional factor depending on the
## value contained in the 12 less significant bits of the two registers
## related to the channel that is being used.
##
## f_clk  = 2MHz
## f_high = f / 16 = 125 KHz          => Highest note programmable
## f_low  = (f / 16) / 2^12 ~ 30.5 Hz => Lowest note programmable
##
## This array contains some pre-computed magic numbers that correspond to real
## notes following the mathematical equation just introduced. The frequencies
## used in the calculations refer to the notes in the equal temperament tuning
## system, with A4 = 440 Hz.
##
## The range of notes is from a B0 to a B8 (8 octaves).
const magic_notes = (proc(): array[tot_notes, uint16] =
  const
    b4_idx  = 2               # A4 = 0 => B4 = 2
    b0_idx  = (b4_idx - (4 * notes_in_oct)).int16
    b8_idx  = (b4_idx + (4 * notes_in_oct)).int16
    freq_a4 = 440 # Hz
    f_clk   = 2_000_000.uint32 # Hz

  template freq(n: int16): float32 =
    freq_a4.float32 * (2.0.pow(1.0 / 12)).pow(n.float32)

  template mask(f: float32): uint16 =
    (f_clk div (16 * f).uint32).uint16

  var ctr = 0
  for i in b0_idx..b8_idx:
    result[ctr] = mask(freq(i))
    inc ctr
)()


const
  NOISE_REG      = 0x06
  MIXER_REG      = 0x07
  FINE_ENV_REG   = 0x0B
  COARSE_ENV_REG = 0x0C
  SHAPE_ENV_REG  = 0x0D

  # Envelope shape functions
  FHOLD      = 0x01
  FALTERNATE = 0x02
  FATTACK    = 0x04
  FCONTINUE  = 0x08


type
  Ay38910a*[T: WriterU8] {.byref.} = object ## \
    ## Handle for the Ay38910a PSG, it can be safefly initialized as const.
    ## Once constructed and initialized (with `init`), you can use it to
    ## play music on on of the tone channels.
    ##
    ## Note that you must provide a writer for this to work: the default one
    ## is `Port`, which can be used directly by just importing this module.
    ##
    ## Another popular one for e.g. projects with this chip and an Arduino,
    ## is the Shift Register one using a HC595 chip. You can provide a custom
    ## one by implementing the `WriterU8` concept.
    bc1*:    uint8
    bdir*:   uint8
    ctl*:    Port
    writer*: T

  Channel* = enum ## Enum representing the three channels of the Ay38910a.
    CHAN_A = 0
    CHAN_B = 1
    CHAN_C = 2

  ChannelMode* {.size: sizeof(uint8).} = enum ## \
    ## Modes of operation for the PSG to output tone/noise, use as bitset.
    CHA_TONE  = 0
    CHB_TONE  = 1
    CHC_TONE  = 2
    CHA_NOISE = 3
    CHB_NOISE = 4
    CHC_NOISE = 5
  
  ChannelModes* = set[ChannelMode] ## Bitset for the PSG mode of operations.

  Note* = enum ## \
    ## The supported notes: note that the PSG can actually also output
    ## microtone intervals.
    B_NOTE       = 0 
    C_NOTE       = 1 
    C_SHARP_NOTE = 2 
    D_NOTE       = 3 
    D_SHARP_NOTE = 4 
    E_NOTE       = 5 
    F_NOTE       = 6 
    F_SHARP_NOTE = 7 
    G_NOTE       = 8 
    G_SHARP_NOTE = 9 
    A_NOTE       = 10
    A_SHARP_NOTE = 11

  EnvelopeShape* {.size: sizeof(uint8).} = enum ## \
    ## These are the only possible correct combinations of the envelope
    ## functions available in the PSG.
    ReverseSawtooth = FCONTINUE,                         ## \|\|\|\|\|\|\|\
    TriangularDown  = FCONTINUE or FALTERNATE,           ## \/\/\/\/\/\/\/\
    Gate            = FCONTINUE or FALTERNATE or FHOLD,  ## \/‾‾‾‾‾‾‾‾‾‾‾‾‾
    Triangular      = FCONTINUE or FALTERNATE or FATTACK ## /|/|/|/|/|/|/|/
    RampGate        = FCONTINUE or FATTACK    or FHOLD,  ## /‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    Sawtooth        = FCONTINUE or FATTACK,              ## /\/\/\/\/\/\/\/


template octave*(n: Note, octave: Natural): uint8 =
  ## Safely computes the correct index to play the passed note in the specified
  ## octave. Note: the range of notes is from a B0 to a B8 (8 octaves).
  let note = n.ord + 12 * octave
  ((note mod tot_notes + tot_notes) mod tot_notes).uint8


# Utility templates to convert enums to correct register values

template chan_to_reg(c: Channel):      uint8 = uint8(ord(c) * 2)
template chan_to_ampl_reg(c: Channel): uint8 = uint8(ord(c) + 8)
template to_mask(m: ChannelModes):     uint8 = cast[uint8](m)


# These are the "lower level" primitived that map directly to the AY38910a
# operations that need to be done to make the chip output some sound.
# More info on the GI datasheet, timing diagrams section.

template inactive_mode(ay: Ay38910a) =
  ay.ctl.clear_pin(ay.bc1)
  delay_us(1)
  ay.ctl.clear_pin(ay.bdir)
  delay_us(1)


template write_mode(ay: Ay38910a) =
  ay.ctl.clear_pin(ay.bc1)
  delay_us(1)
  ay.ctl.set_pin(ay.bdir)
  delay_us(1)


template latch_addr_mode(ay: Ay38910a) =
  ay.ctl.set_pin(ay.bc1)
  delay_us(1)
  ay.ctl.set_pin(ay.bdir)
  delay_us(1)


proc write_data(ay: Ay38910a; address, data: uint8) =
  ay.inactive_mode()
  ay.writer.write(address)
  ay.latch_addr_mode()
  ay.inactive_mode()

  ay.write_mode()
  ay.writer.write(data)
  ay.inactive_mode()


proc init*(ay: Ay38910a) =
  ## Initialize the Ay38910a peripheral. Call before anything else.
  ## This also calls the init function of the provided writer, so you do not
  ## need to do that yourself.
  ay.ctl.as_output_pin(ay.bc1)
  ay.ctl.as_output_pin(ay.bdir)
  ay.writer.init()


proc channel_on*(ay: sink Ay38910a, m: ChannelModes) =
  ## Enables the channels specified in the passed bitset.
  ay.write_data(MIXER_REG, bitops.bitnot(m.to_mask()))


proc set_amplitude*(ay: Ay38910a, chan: Channel, amp: uint8, envelope = false) =
  ## Sets the amplitude for the specified channel.
  ##
  ## When setting the amplitude, only the first five less significant bits
  ## hold information, with the first four bits referring to the amplitude
  ## itself (0-16), and the fifth bit referring to the envelope filter being
  ## enabled.
  ##
  ## Enabling the envelope filter disables the usage of fixed amplitude
  ## through bits[0:3].
  let amplitude = (amp and 0x0f) or (if envelope: 0x10 else: 0x00)
  ay.write_data(chan_to_ampl_reg(chan), amplitude)


proc set_envelope*(ay: Ay38910a, shape: EnvelopeShape, freq: uint16) =
  ## Sets the function bits for the envelope generator and scales the frequency
  ## of the envelope by a specific factor.
  ##
  ## The final frequency of the envelope is calculated by taking the input
  ## clock, scaling it by a factor of 256, and then scaling it again by a
  ## 16-bit value that is passed by the user. This implies that the range of
  ## frequencies that can be applied is 0.12-7.8k Hz.
  ay.write_data(FINE_ENV_REG,   bitand(freq.uint8, 0xff))
  ay.write_data(COARSE_ENV_REG, bitand((freq shr 8).uint8, 0xff))
  ay.write_data(SHAPE_ENV_REG,  cast[uint8](shape))


proc play_note*(ay: Ay38910a, chan: Channel, note: uint16) =
  ## Plays a note on the specified channel. The note is actually the prescaler
  ## value used to scale the input clock signal. This allows to play any tone
  ## in the supported domain.
  ##
  ## If used together with the `octave` template, this can be used to output
  ## notes with pitches derived from the equal temperament system.
  let actual_note   = note mod magic_notes.len()
  let magic_note    = uint16(magic_notes[actual_note])
  let chan_register = chan_to_reg(chan)

  ay.write_data(chan_register, uint8(magic_note) and 0xff)
  ay.write_data(chan_register + 1, uint8(magic_note shr 8) and 0x0f)


proc play_noise*(ay: Ay38910a, divider: uint8) =
  ## Plays a sound on the noise channel.
  ay.write_data(NOISE_REG, bitand(divider, 0x1f))
