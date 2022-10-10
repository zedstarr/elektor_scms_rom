/* Elektor SCMS Copybit Killer
 * Elektor Jul/Aug 1998
 * Author: Hans-Juergen Hanft
 *
 * ROM Generator
 * K.Allen 21/Feb/2021
 *
 * Outputs an ASCII hex file and a binary file:
 * elektor_scms_rom.hex (Readable in a text editor)
 * elektor_scms_rom.bin (Pure binary)
 * 
 * On Linux, compile with:
 * linux> gcc elektor_scms_rom.c -o elektor_scms_rom.exe
 * linux> ./elektor_scms_rom.exe
 *
 * On Linux, to view the binary file, use:
 * linux> hexdump -vC elektor_scms_rom.bin
 *
 * Yup, this is pretty crude/clumsy C code, sorry. Please rewrite!
 *
 */

#include <stdio.h>

#define ROM_SIZE 65536  // 27C512
#define BLOCK_SIZE 256

unsigned char rom[ROM_SIZE];

// Block fill with an even/odd pair with optional block increment.
unsigned int block_fill(unsigned int block, unsigned int incr) {
  unsigned int addr, offset;
  unsigned char byte;

  //printf("Block %2x\n", block);
  for (offset=0; offset<BLOCK_SIZE; offset++) {
    addr = block*BLOCK_SIZE + offset;
    byte = (block+incr)<<1 | (offset & 0x01);
    rom[addr] = byte;
  }
  return addr;
}

// Block fill with a 8-byte pattern.
unsigned int block_fill_8byte(unsigned int block, unsigned char b[8]) {
  unsigned int addr, offset, i;

  for (offset=0; offset<BLOCK_SIZE; offset+=8) {
    addr = block*BLOCK_SIZE + offset;
    for (i=0; i<8; i++) {
      rom[addr+i] = b[i];
    }
  }
  return addr;
}

unsigned int addr, offset, block;

int main(int argc, char *argv[]) {
  // Flood fill entire ROM with 0x00.
  for (addr=0; addr<sizeof(rom); addr++) {
    rom[addr] = 0x00;
  }

  // Flood fill bottom 32KB with even/odd 0x00/0x01 pairs.
  // This handles any "illegal" states, 0x0a-0x0f.
  for (addr=0; addr<32678; addr+=2) {
    rom[addr] = 0x00;
    rom[addr+1] = 0x01;
  }

  // Add incrementer states 0x00-0x06, 0x10-0x44, 0x48-0x7c.
  unsigned char byte;
  for (block=0x00; block<=0x06; block++) {
    block_fill(block,1);
  }
  for (block=0x10; block<=0x44; block++) {
    block_fill(block,1);
  }
  for (block=0x48; block<=0x7c; block++) {
    block_fill(block,1);
  }
  // States that loop on themselves.
  block_fill(0x07,0);
  block_fill(0x08,0);
  block_fill(0x09,0);
  block_fill(0x47,0);
  block_fill(0x7f,0);

  // COPY and PARITY processing, 0x45-0x46, 0x7d-0x7e
  block_fill_8byte(0x45, (unsigned char[]){0x8d, 0x8d, 0x8c, 0x8c, 0x8d, 0x8d, 0x8c, 0x8c});
  block_fill_8byte(0x46, (unsigned char[]){0x00, 0x8e, 0x8e, 0x01, 0x00, 0x8f, 0x8f, 0x01});

  block_fill_8byte(0x7d, (unsigned char[]){0xfd, 0xfd, 0xfc, 0xfc, 0xfd, 0xfd, 0xfc, 0xfc});
  block_fill_8byte(0x7e, (unsigned char[]){0x00, 0xfe, 0xfe, 0x01, 0x00, 0xff, 0xff, 0x01});

  // The exceptions.
  // Jump to state8 when Z preamble matched.
  rom[0x0717]=0x11;
  rom[0x07e8]=0x10;

  // Jump to state9 when Frame 1 X preamble matched.
  rom[0x081d]=0x13;
  rom[0x08e2]=0x12;

  // Jump to state10 when Frame 2 X preamble matched.
  rom[0x091d]=0x21;
  rom[0x09e2]=0x20;

  // Jump to state48 when Frame 2 Y preamble matched.
  rom[0x471b]=0x91;
  rom[0x47e4]=0x90;

  // Jump to state8 when Z preamble matched.
  rom[0x7f17]=0x11;
  rom[0x7fe8]=0x10;
  
  // Write out.
  FILE *fp_hex = fopen("elektor_scms_rom.hex", "w");
  FILE *fp_bin = fopen("elektor_scms_rom.bin", "wb");
  unsigned int row_addr;
  for (row_addr=0; row_addr<sizeof(rom); row_addr+=16) {
    fprintf(fp_hex, "%06x ", row_addr);
    for (offset=0; offset<16; offset++) {
      addr = row_addr + offset;
      fprintf(fp_hex, " %02x", rom[addr]);
      fwrite(&rom[addr], 1, 1, fp_bin);
    }
    fprintf(fp_hex, "\n");
  }
  fclose(fp_hex);
  fclose(fp_bin);
};

// END

