import avr_io
import bitops

type
  WriterU8* = concept
    proc init(s: Self)
    proc write(s: Self, word: uint8)

  ShiftRegHC595* {.byref.} = object
    port*:  Port
    data*:  uint8
    latch*: uint8
    clock*: uint8


proc init*(port: Port) =
  port.as_output_port()


proc write*(port: Port, word: uint8) =
  port.set_port_value(word)


proc init*(ser: ShiftRegHC595) =
  ser.port.as_output_pin(ser.data)
  ser.port.as_output_pin(ser.latch)
  ser.port.as_output_pin(ser.clock)


proc write*(ser: ShiftRegHC595, word: uint8) =
  ser.port.clear_pin(ser.latch)
  var word = word

  # most significant first
  for _ in 0..7:
    if bitand(word, 0x80) == 0: ser.port.clear_pin(ser.data)
    else:                       ser.port.set_pin(ser.data)
    word = word shl 1
    ser.port.set_pin(ser.clock)
    ser.port.clear_pin(ser.clock)
  ser.port.set_pin(ser.latch)
