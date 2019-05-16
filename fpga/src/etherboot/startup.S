# start sequence of the bootloader
# 
# 
#include <smp.h>
#define SP_BASE   0x4000FFF0
#define DRAM_BASE 0x87FE0000
#define DRAM_END  0x87FFFFF8

  .section .text.init
  .option norvc
  .globl _prog_start
_prog_start:
  smp_pause(s1, s2)
# use a delay to allow the debugger in
  li t4, 10
_wait_dbg:
  add t4, t4, -1
  bne t4, zero, _wait_dbg

  li sp, SP_BASE
  la t0, init_uart
  jalr ra, t0
  la t0, print_uart
  la a0, hello
  jalr ra, t0
  la t1, gpio_sw
  jalr ra, t1
  srli a0, a0, 0x5
  li t1, 2
  beq a0, t1, dram_main      
  li sp, DRAM_END
  la a0, relocmsg
  jalr ra, t0
  la a1, _prog_start
  la a2, _DATA_END_
  li a3, DRAM_BASE
# use a delay before we try the DDR memory
  li t4, 1000000
_wait:
  ld a4, 0(a1)
  add t4, t4, -1
  ld a4, 8(a1)
  bne t4, zero, _wait      

  ld a4, 0(a3)
_copy:
  ld a4, 0(a1)
  sd a4, 0(a3)
  ld a4, 8(a1)
  sd a4, 8(a3)
  ld a4, 16(a1)
  sd a4, 16(a3)
  ld a4, 24(a1)
  sd a4, 24(a3)
  add a1, a1, 32
  add a3, a3, 32
  blt a1, a2, _copy
  la a5, _reloc
  add a5, a5, a3      
  sub a5, a5, a1
_reloc:
  la a5, trap_entry
  csrw mtvec, a5  
  la a1, _BSS_START_
  la a2, _BSS_END_
_zbss:
  sd zero, 0(a1)
  sd zero, 8(a1)
  sd zero, 16(a1)
  sd zero, 24(a1)
  add a1, a1, 32
  blt a1, a2, _zbss
  call main
  smp_resume(s1, s2)
trap_entry:
  csrr t0, mcause
  csrr t1, mepc
1:      
  wfi
  j 1b
hello:
  .ascii "Hello from Ariane! Please wait a moment...\n\000"
relocmsg:
  .ascii "Relocating to DDR memory\n\000"
skiprelocmsg:
  .ascii "Skip relocating to DDR memory\n\000"

