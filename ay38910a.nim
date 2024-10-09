import avr_io
import delay
import psg


proc genClock(clockPort: Port, clockPin: uint8) =
  clockPort.asOutputPin(clockPin)
  OCR2A[] = 3
  timer2.setTimerFlag({TimCtlAFlag.wgm1, coma0})
  timer2.setTimerFlag({TimCtlBFlag.cs0})

proc loop =
  genClock(portB, 4)
  const ay = ay38910a(bc1Pin: 4, bdirPin: 5, ctlPort: portH, dataPort: portA)
  ay.init()
  ay.channelOn({CHA_TONE})
  ay.setAmplitude(CHAN_A, 15, false)

  while true:
    for oct in 0..octaves:
      for note in Note.low..Note.high:
        ay.playNote(CHAN_A, note.octave(oct))
        delayMs(20)

when isMainModule:
  loop()
