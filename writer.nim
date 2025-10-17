import avr_io
import bitops

type
  WriterU8* = concept ## uint8 writer concept to use with the Ay38910a module
    proc init(s: Self)
    proc write(s: Self, word: uint8)

  ShiftRegHC595* {.byref.} = object ## \
    ## Writer implementation for interfacing with the AY38910a chip through an
    ## HC595 serial to parallel shift register, for microcontrollers with
    ## limited number of GPIOs available, e.g. atmega328p on arduino uno
    port*:  Port
    data*:  uint8
    latch*: uint8
    clock*: uint8


proc init*(ser: ShiftRegHC595) =
  ## Initializes the shift register.
  ser.port.as_output_pin(ser.data)
  ser.port.as_output_pin(ser.latch)
  ser.port.as_output_pin(ser.clock)


proc write*(ser: ShiftRegHC595, word: uint8) =
  ## Writes the data to the Ay38190a through the shift register.
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


# The following is an implementation of the WriterU8 concept for the Port type
# exposed by avr_io. This module is automatically exported when importing
# `ay38910a/psg` so you should not need to import it explicitly to make things
# work. Nim does not have defaul generics so it cannot be enforced, but this
# is what you should use in a base case with the ay38910a.

proc init*(port: Port) =
  ## Initializes the Port as an output one.
  port.as_output_port()


proc write*(port: Port, word: uint8) =
  ## Writes the data to the initialized port.
  port.set_port_value(word)
