# Elektor SCMS Copybit Killer
# Elektor Jul/Aug 1998
# Author: Hans-Juergen Hanft
#
# ROM Generator
# K.Allen 21/Feb/2021
#
# Outputs an ASCII hex file and a binary file:
# elektor_scms_rom.hex (Readable in a text editor)
# elektor_scms_rom.bin (Pure binary)
# 
# Run with:
# wish elektor_scms_rom.tcl
#
# On Linux, to view the binary file, use:
# linux> hexdump -vC elektor_scms_rom.bin
#
# Yup, this is pretty crude/clumsy Tcl code, sorry. Please rewrite!
#
# See other "documentation" including the State Diagram on:
# http://forums.sonyinsider.com/topic/30611-elektor-copybit-stripper
#
# Instigated by zedstarr finding and extracting the ROM image:
# https://zedstarr.com/2021/02/07/minidisc-bit-stripper-the-elektor-scms-killer/
#
# All kicked off by James_S looking for the ROM image for a friend back in March 2020.
#

set ROM_SIZE 65536  ;# 27C512
set BLOCK_SIZE 256

array set rom {}

# Block fill with an even/odd pair with optional block increment.
proc block_fill {block inc} {
  global rom BLOCK_SIZE
  #puts [format "(block_fill) Block %2x"  $block]
  for {set offset 0} {$offset<$BLOCK_SIZE} {incr offset} {
    set addr [expr {$block*$BLOCK_SIZE + $offset}]
    set byte [expr {($block+$inc)<<1 | ($offset & 0x01)}]
    set rom($addr) $byte
  }
  return $addr
}

# Block fill with a 8-byte pattern.
proc block_fill_8byte {block b} {
  global rom BLOCK_SIZE
  #puts [format "(block_fill_8byte) Block %2x"  $block]
  for {set offset 0} {$offset<$BLOCK_SIZE} {incr offset 8} {
    set addr [expr {$block*$BLOCK_SIZE + $offset}]
    for {set i 0} {$i<8} {incr i} {
      set rom([expr {$addr+$i}]) [lindex $b $i]
    }
  }
  return $addr
}

# Flood fill entire ROM with 0x00.
for {set addr 0} {$addr<$ROM_SIZE} {incr addr} {
  set rom($addr) 0
}

# Flood fill bottom 32KB with even/odd 0x00/0x01 pairs.
# This handles any "illegal" states, 0x0a-0x0f.
for {set addr 0} {$addr<32768} {incr addr 2} {
  set rom([expr {$addr+0}]) 0x00
  set rom([expr {$addr+1}]) 0x01
}

# Add incrementer states 0x00-0x07, 0x10-0x44, 0x48-0x7c.
for {set block 0x00} {$block<=0x06} {incr block} {
  block_fill $block 1
}
for {set block 0x10} {$block<=0x44} {incr block} {
  block_fill $block 1
}
for {set block 0x48} {$block<=0x7c} {incr block} {
  block_fill $block 1
}
# States that loop on themselves.
block_fill 0x07 0
block_fill 0x08 0
block_fill 0x09 0
block_fill 0x47 0
block_fill 0x7f 0

# COPY and PARITY processing, 0x45-0x46, 0x7d-0x7e
block_fill_8byte 0x45 {0x8d 0x8d 0x8c 0x8c 0x8d 0x8d 0x8c 0x8c}
block_fill_8byte 0x46 {0x00 0x8e 0x8e 0x01 0x00 0x8f 0x8f 0x01}

block_fill_8byte 0x7d {0xfd 0xfd 0xfc 0xfc 0xfd 0xfd 0xfc 0xfc}
block_fill_8byte 0x7e {0x00 0xfe 0xfe 0x01 0x00 0xff 0xff 0x01}

# The exceptions.
# Jump to state8 when Z preamble matched.
set rom([expr {0x0717}]) 0x11
set rom([expr {0x07e8}]) 0x10

# Jump to state9 when Frame 1 X preamble matched.
set rom([expr {0x081d}]) 0x13
set rom([expr {0x08e2}]) 0x12

# Jump to state10 when Frame 2 X preamble matched.
set rom([expr {0x091d}]) 0x21
set rom([expr {0x09e2}]) 0x20

# Jump to state48 when Frame 2 Y preamble matched.
set rom([expr {0x471b}]) 0x91
set rom([expr {0x47e4}]) 0x90

# Jump to state8 when Z preamble matched.
set rom([expr {0x7f17}]) 0x11
set rom([expr {0x7fe8}]) 0x10

# Write out.
set fp_hex [open "elektor_scms_rom.hex" "w"]
set fp_bin [open "elektor_scms_rom.bin" "wb"]
fconfigure $fp_bin -translation binary -encoding binary
for {set row_addr 0} {$row_addr<$ROM_SIZE} {incr row_addr 16} {
  puts -nonewline $fp_hex [format "%06x " $row_addr]
  for {set offset 0} {$offset<16} {incr offset} {
    set addr [expr {$row_addr + $offset}]
    #puts [format "%06x %02x" $addr $rom($addr)]
    puts -nonewline $fp_hex [format " %02x" $rom($addr)]
    puts -nonewline $fp_bin [binary format c [expr {$rom($addr)}]]
  }
  puts $fp_hex ""
}
close $fp_hex
close $fp_bin

exit

# END

