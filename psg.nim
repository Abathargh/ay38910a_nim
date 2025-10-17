import std/[bitops, math]

import avr_io
import writer
import delay

# TODO add docstrings from c proj

const 
  octaves*     = 8
  notes_in_oct = 12
  tot_notes    = notes_in_oct * octaves + 1

proc generate_magic_notes(): array[tot_notes, uint16] =
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


const 
  magicNotes* = generate_magic_notes()

  NOISE_REG      = 0x06
  MIXER_REG      = 0x07
  FINE_ENV_REG   = 0x0B
  COARSE_ENV_REG = 0x0C
  SHAPE_ENV_REG  = 0x0D


type
  ay38910a*[T: WriterU8] {.byref.} = object
    bc1*:  uint8
    bdir*: uint8
    ctl*: Port
    writer*:  T

  channel* = enum
    CHAN_A = 0
    CHAN_B = 1
    CHAN_C = 2

  channelMode* {.size: sizeof(uint8).} = enum
    CHA_TONE  = 0
    CHB_TONE  = 1
    CHC_TONE  = 2
    CHA_NOISE = 3
    CHB_NOISE = 4
    CHC_NOISE = 5
  
  channelModes* = set[channelMode]

  Note* = enum
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

# TODO opt: same trick as port_value for static ints, so no need to do this
# TODO crazy masking
template octave*(n: Note, octave: Natural): uint8 =
  (((n.ord + 12*(octave)) mod tot_notes + tot_notes) mod tot_notes).uint8


template chanToReg(c: channel): uint8 = uint8(ord(c) * 2)
template chanToAmplReg(c: channel): uint8 = uint8(ord(c) + 8)
template toMask(m: channelModes): uint8 = cast[uint8](m)


template inactiveMode(ay: ay38910a) =
  ay.ctl.clearPin(ay.bc1)
  delayUs(1)
  ay.ctl.clearPin(ay.bdir)
  delayUs(1)


template writeMode(ay: ay38910a) = 
  ay.ctl.clearPin(ay.bc1)
  delayUs(1)
  ay.ctl.setPin(ay.bdir)
  delayUs(1)


template latchAddrMode(ay: ay38910a) = 
  ay.ctl.setPin(ay.bc1)
  delayUs(1)
  ay.ctl.setPin(ay.bdir)
  delayUs(1)


proc writeData(ay: ay38910a; address, data: uint8) = 
  ay.inactiveMode()
  ay.writer.write(address)
  ay.latchAddrMode()
  ay.inactiveMode()

  ay.writeMode()
  ay.writer.write(data)
  ay.inactiveMode()


proc init*(ay: ay38910a) =
  ay.ctl.asOutputPin(ay.bc1)
  ay.ctl.asOutputPin(ay.bdir)
  ay.writer.init()


proc channelOn*(ay: sink ay38910a, m: channelModes) =
  ay.writeData(MIXER_REG, bitops.bitnot(m.toMask()))


proc channelOff*(ay: ay38910a, m: channelModes) =
  ay.writeData(MIXER_REG, m.toMask())


proc setAmplitude*(ay: ay38910a, chan: channel, amp: uint8, envelope = false) =
  let amplitude = (amp and 0x0f) or (if envelope: 0x10 else: 0x00)
  ay.writeData(chanToAmplReg(chan), amplitude)


proc playNote*(ay: ay38910a, chan: channel, note: uint16) =
  let actualNote = note mod magicNotes.len()
  let chanRegister = chanToReg(chan)
  let magicNote = uint16(magicNotes[actualNote])

  ay.writeData(chanRegister, uint8(magicNote) and 0xff)
  ay.writeData(chanRegister + 1, uint8(magicNote shr 8) and 0x0f)
