/*
 * arch/riscv/include/asm/lowrisc-sdhi.h
 *
 * SD/MMC driver for LowRISC Ariane SOC
 *
 * Based on drivers/mmc/sh-sdhi.h
 * Copyright (C) 2013-2017 Renesas Electronics Corporation
 * Copyright (C) 2008-2009 Renesas Solutions Corp.
 *
 * SPDX-License-Identifier:	GPL-2.0
 */

#ifndef _SH_SDHI_H
#define _SH_SDHI_H

/* For quirk */
#define SH_SDHI_QUIRK_16BIT_BUF		BIT(0)
#define SH_SDHI_QUIRK_64BIT_BUF		BIT(1)

enum {align_reg,clk_din_reg,arg_reg,cmd_reg,
      setting_reg,start_reg,reset_reg,blkcnt_reg,
      blksiz_reg,timeout_reg,clk_pll_reg,irq_en_reg,
      unused1,unused2,unused3,led_reg};

enum {resp0,resp1,resp2,resp3,
      wait_resp,status_resp,packet_resp0,packet_resp1,
      data_wait_resp,trans_cnt_resp,obsolete1,obsolet2,
      detect_resp,xfr_addr_resp,irq_stat_resp,pll_resp,
      align_resp,clk_din_resp,arg_resp,cmd_i_resp,
      setting_resp,start_resp,reset_resp,blkcnt_resp,
      blksize_resp,timeout_resp,clk_pll_resp,irq_en_resp};

enum {SD_APP_OP_COND=41, data_buffer_offset=0x2000};

enum {SD_CARD_RESP_END=1,SD_CARD_RW_END=2, SD_CARD_CARD_REMOVED_0=4, SD_CARD_CARD_INSERTED_0=8};

extern int lowrisc_init(unsigned long addr, int ch, unsigned long quirks);

#include "ariane.h"

enum { sd_base_addr = SPIBase };

#endif /* _SH_SDHI_H */
