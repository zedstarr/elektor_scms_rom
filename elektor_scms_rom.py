# 
# Elektor SCMS Copybit Killer
# Elektor Jul/Aug 1998
# Author: Hans-Juergen Hanft
#
# ROM Generator
# Based on C code by K.Allen 21/Feb/2021
# Converted to python by @zedstarr 22/Feb/2021
# 
# Requires python3
# 
# execute as:
# 
# python3 elektor_scms_rom.py
# 
# Outputs an ASCII hex file and a binary file:
# elektor_scms_rom.hex (Readable in a text editor)
# elektor_scms_rom.bin (Pure binary)
# 
# On Linux, to view the binary file, use:
# linux> hexdump -vC elektor_scms_rom.bin
#
# Yup, this is pretty crude/clumsy python, sorry. Please rewrite!
#

import sys

ROM_SIZE = 65536  # 27C512
BLOCK_SIZE = 256

# create data array filled with zeros
rom_data = []
for i in range(ROM_SIZE):
    rom_data.append(0)

def fprintf(stream, format_spec, *args):
    stream.write(format_spec % args)

# // Block fill with an even/odd pair with optional block increment.
def block_fill(block, incr):
  
  # //printf("Block %2x\n", block);
  offset = 0
  while offset<BLOCK_SIZE:
    addr = block*BLOCK_SIZE + offset
    byte = (block+incr)<<1 | (offset & 0x01)
    rom_data[addr] = byte
    offset += 1


# // Block fill with a 8-byte pattern.
def block_fill_8byte(block, b):

  offset=0
  while offset < BLOCK_SIZE:
    addr = block*BLOCK_SIZE + offset
    i=0
    while i < 8:
      rom_data[addr+i] = b[i]
      i += 1
    offset += 8


try:

# // Flood fill bottom 32KB with even/odd 0x00/0x01 pairs.
# // This handles any "illegal" states, 0x0a-0x0f.
  addr = 0
  while addr<32678:
    rom_data[addr] = 0x00
    rom_data[addr+1] = 0x01
    addr += 2

# // Add incrementer states 0x00-0x06, 0x10-0x44, 0x48-0x7c.
  block = 0x00
  while  block <= 0x06:
    block_fill(block,1)
    block += 1

  block = 0x10
  while block <= 0x44:
    block_fill(block,1)
    block += 1

  block = 0x48
  while block <= 0x7c:
    block_fill(block,1)
    block +=1

# // States that loop on themselves.
  block_fill(0x07,0)
  block_fill(0x08,0)
  block_fill(0x09,0)
  block_fill(0x47,0)
  block_fill(0x7f,0)

# // COPY and PARITY processing, 0x45-0x46, 0x7d-0x7e
  block_fill_8byte(0x45, (0x8d, 0x8d, 0x8c, 0x8c, 0x8d, 0x8d, 0x8c, 0x8c) )
  block_fill_8byte(0x46, (0x00, 0x8e, 0x8e, 0x01, 0x00, 0x8f, 0x8f, 0x01) )

  block_fill_8byte(0x7d, (0xfd, 0xfd, 0xfc, 0xfc, 0xfd, 0xfd, 0xfc, 0xfc) )
  block_fill_8byte(0x7e, (0x00, 0xfe, 0xfe, 0x01, 0x00, 0xff, 0xff, 0x01) )

# // The exceptions.
# // Jump to state8 when Z preamble matched.
  rom_data[0x0717] = 0x11
  rom_data[0x07e8] = 0x10

# // Jump to state9 when Frame 1 X preamble matched.
  rom_data[0x081d] = 0x13
  rom_data[0x08e2] = 0x12

# // Jump to state10 when Frame 2 X preamble matched.
  rom_data[0x091d] = 0x21
  rom_data[0x09e2] = 0x20

# // Jump to state48 when Frame 2 Y preamble matched.
  rom_data[0x471b] = 0x91
  rom_data[0x47e4] = 0x90

# // Jump to state8 when Z preamble matched.
  rom_data[0x7f17] = 0x11
  rom_data[0x7fe8] = 0x10
  
# // Write out.
  hex_file = open("elektor_scms_rom.hex", "w")
  bin_file = open("elektor_scms_rom.bin", "wb")

  row_addr = 0
  while row_addr < ROM_SIZE:
    fprintf(hex_file, "%06x ", row_addr)
    offset = 0
    while offset < 16:
      addr = row_addr + offset
      fprintf(hex_file, " %02x", rom_data[addr])
      offset += 1  
    fprintf(hex_file, "\n");
    row_addr += 16

  addr = 0
  while addr < 65536:
    # print(rom_data[addr])
    bin_file.write(rom_data[addr].to_bytes(1, byteorder='big', signed=False))
    addr += 1
    
  bin_file.close()
  hex_file.close()
    
except KeyboardInterrupt:
    print ("Keyboard Interrupt.\n")
