#define DRAM_BASE 0x80000000

.section .text.start, "ax", @progbits
.globl _start
_start:
        j _start+6

.section .rodata.dtb, "a", @progbits
.globl _dtb
.align 5, 0
_dtb:
.ascii "DTB goes here"
