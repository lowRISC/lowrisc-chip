# start sequence of the bootloader
# 
# 
#include <smp.h>
#define DRAM_BASE 0x87FE0000
#define DRAM_END  0x87FFFFF8

  .section .text.init
  .option norvc
  .globl _prog_start
_prog_start:
  li sp, DRAM_END
  li a0, 0
  li a1, 0x80000000
  li a2, 0
  li a3, 1
  jal ra, disk_test
  la a1, _prog_start
  li a2, 0x8000
  add a2, a1, a2
  li a3, DRAM_BASE
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
  li a2, DRAM_END
  jal ra, _reloc      
_reloc:
  li a1, DRAM_BASE
  and ra, ra, a1
  bne ra, zero, _clr
  add ra, a1, zero
  ret
_clr:
  sd zero, 0(a3)
  sd zero, 8(a3)
  sd zero, 16(a3)
  sd zero, 24(a3)
  add a3, a3, 32
  blt a3, a2, _clr
        
  la a5, trap_entry
  csrw mtvec, a5  
  call main
trap_entry:
  csrr t0, mcause
  csrr t1, mepc
1:      
  wfi
        j 1b
	.align	1
	.globl	disk_test
	.type	disk_test, @function
disk_test:
	addi	sp,sp,-32
	slli	a2,a2,32
	sd	s0,16(sp)
	sd	ra,24(sp)
	sd	s1,8(sp)
	li	a5,1107296256
	srli	a2,a2,32
	sd	a2,0(a5)
	slli	a4,a3,32
	sd	zero,8(a5)
	srli	a4,a4,32
	li	s0,1
	sd	a4,16(a5)
	sllw	s0,s0,a3
	li	a4,1
	mv	a0,a1
	addiw	s0,s0,-1
	sd	a4,24(a5)
.L51:
	ld	a4,16(a5)
	andi	a4,a4,16
	beq	a4,zero,.L51
	sd	zero,24(a5)
	ld	s1,24(a5)
	slliw	a3,a3,9
	slli	a2,a3,32
	srli	a2,a2,32
	li	a1,1107329024
	call	memcpy
	and	s1,s1,s0
	li	a0,2
	bne	s0,s1,.L52
	li	a0,0
.L52:
	ld	ra,24(sp)
	ld	s0,16(sp)
	ld	s1,8(sp)
	addi	sp,sp,32
	jr	ra
	.size	disk_test, .-disk_test

