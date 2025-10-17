{.push stackTrace:off.}
proc delay_us*(us: cuint) {.inline.} =
  asm """
    "MOV ZH,%B0\n\t"  // MOV: 1 cycle
    "MOV ZL,%A0\n\t"  // MOV: 1 cycle
    "%=:\n\t"         // 16 cycles (last BRNE = 1 evens out with MOV)
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "SBIW Z,1\n\t"    // SBIW: 2 cycles
    "BRNE %=b\n\t"    // BRNE: 2 if condition is false, 1 otherwise
    :
    : "r" (`us`)
    : "r30", "r31"
  """
{.pop.}

{.push stackTrace:off.}
proc delay_ms*(ms: cuint) {.inline.} =
  asm """
    "MOV ZH,%B0\n\t"  // MOV: 1 cycle
    "MOV ZL,%A0\n\t"  // MOV: 1 cycle => 1 + (16012 + 4) * ms = rep*16016 + 1
    "OUTER%=:\n\t"    // (4000 + 3) * 4 = 16012
    "LDI R18,4\n\t"   // LDI: 1 cycle
    "MILLISEC%=:\n\t" // 16 * 250 = 4000 cycles
    "LDI R17,250\n\t" // LDI: 1 cycle
    "MICROSEC%=:\n\t" // MICROSEC LOOP: 16 cycles tot (including previous LDI per cycle)
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "NOP\n\t"
    "DEC R17\n\t"
    "BRNE MICROSEC%=\n\t"
    "DEC R18\n\t"
    "BRNE MILLISEC%=\n\t"
    "SBIW Z,1\n\t"        // SBIW: 2 cycles
    "BRNE OUTER%=\n\t"    // BRNE: 2 if condition is false, 1 otherwise
    :
    : "r" (`ms`)
    : "r17", "r18", "r30", "r31"
  """
{.pop.}