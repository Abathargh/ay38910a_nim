switch("os", "standalone")
switch("cpu", "avr")
switch("gc", "none")
switch("stackTrace", "off")
switch("lineTrace", "off")
switch("define", "danger")
switch("define", "USING_ATMEGA2560")
switch("passC", "-mmcu=atmega2560 -DF_CPU=16000000")
switch("passL", "-mmcu=atmega2560 -DF_CPU=16000000")
switch("nimcache", ".nimcache")

switch("cc", "gcc")
switch("avr.standalone.gcc.options.linker", "-static")
switch("avr.standalone.gcc.exe", "avr-gcc")
switch("avr.standalone.gcc.linkerexe", "avr-gcc")

when defined(windows):
  switch("gcc.options.always", "")