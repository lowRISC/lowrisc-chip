// Based on https://raw.githubusercontent.com/lowRISC/u-boot-riscv/master/include/linux/poison.h
// LICENSE: not specified: assumed GPL-2.0+

#ifndef _LINUX_POISON_H
#define _LINUX_POISON_H

/********** include/linux/list.h **********/
/*
 * used to verify that nobody uses non-initialized list entries.
 */
#define LIST_POISON1  ((void *) 0x0)
#define LIST_POISON2  ((void *) 0x0)

#endif
