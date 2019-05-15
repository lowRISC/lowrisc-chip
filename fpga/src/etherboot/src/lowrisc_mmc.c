/*
 * drivers/mmc/lowrisc.c
 *
 * SD/MMC driver for Renesas rmobile ARM SoCs.
 *
 * Copyright (C) 2011,2013-2017 Renesas Electronics Corporation
 * Copyright (C) 2014 Nobuhiro Iwamatsu <nobuhiro.iwamatsu.yj@renesas.com>
 * Copyright (C) 2008-2009 Renesas Solutions Corp.
 *
 * SPDX-License-Identifier:	GPL-2.0
 */

#include <common.h>
#include <malloc.h>
#include <mmc.h>
#include <dm.h>
#include <linux/errno.h>
#include <linux/compat.h>
#include <linux/io.h>
#include <linux/sizes.h>
#include <asm/lowrisc-sdhi.h>
#include <clk.h>
#include "ariane.h"

#define CONFIG_SYS_SH_SDHI_NR_CHANNEL 1
#define CONFIG_SH_SDHI_FREQ	97500000
#define DRIVER_NAME "lowrisc_sd"

struct lowrisc_sd_host {
  void __iomem *ioaddr;
  int ch, bus_shift, irq, int_en, width_setting, error, cmdidx;
  unsigned long quirks;
  unsigned char wait_int;
  unsigned char sd_error;
  unsigned char app_cmd;
  struct mmc_cmd *cmd;
  struct mmc_data *data;
};

#define VERBOSE 0
#define LOGV(l) // debug l
#define LOG(l) debug l

void sd_align(struct lowrisc_sd_host *host, int d_align)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[align_reg] = d_align;
}

void sd_clk_div(struct lowrisc_sd_host *host, int clk_div)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  /* This section is incomplete */
  sd_base[clk_din_reg] = clk_div;
}

void sd_arg(struct lowrisc_sd_host *host, uint32_t arg)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[arg_reg] = arg;
}

void sd_cmd(struct lowrisc_sd_host *host, uint32_t cmd)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[cmd_reg] = cmd;
}

void sd_setting(struct lowrisc_sd_host *host, int setting)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[setting_reg] = setting;
}

void sd_cmd_start(struct lowrisc_sd_host *host, int sd_cmd)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[start_reg] = sd_cmd;
}

void sd_reset(struct lowrisc_sd_host *host, int sd_rst, int clk_rst, int data_rst, int cmd_rst)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[reset_reg] = ((sd_rst&1) << 3)|((clk_rst&1) << 2)|((data_rst&1) << 1)|((cmd_rst&1) << 0);
}

void sd_blkcnt(struct lowrisc_sd_host *host, int d_blkcnt)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[blkcnt_reg] = d_blkcnt&0xFFFF;
}

void sd_blksize(struct lowrisc_sd_host *host, int d_blksize)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[blksiz_reg] = d_blksize&0xFFF;
}

void sd_timeout(struct lowrisc_sd_host *host, int d_timeout)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[timeout_reg] = d_timeout;
}

void sd_irq_en(struct lowrisc_sd_host *host, int mask)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[irq_en_reg] = mask;
  host->int_en = mask;
}

static void lowrisc_sd_init(struct lowrisc_sd_host *host)
{

}

static void *mmc_priv(struct mmc *mmc)
{
	return (void *)mmc->priv;
}

static void lowrisc_sd_set_led(struct lowrisc_sd_host *host, unsigned char state)
{
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  sd_base[led_reg] = state;
}

static void lowrisc_sd_finish_request(struct lowrisc_sd_host *host)
{
	/* Write something to end the command */
	host->cmd = NULL;
	host->data = NULL;

	sd_reset(host, 0,1,0,1);
	sd_cmd_start(host, 0);
	sd_reset(host, 0,1,1,1);
	lowrisc_sd_set_led(host, 0);
}
  
static void lowrisc_sd_cmd_irq(struct lowrisc_sd_host *host)
{
	struct mmc_cmd *cmd = host->cmd;
        volatile uint64_t *sd_base = host->ioaddr;
        assert(sd_base == sd_base_addr);

	LOGV (("lowrisc_sd_cmd_irq\n"));
	
	if (!host->cmd) {
		dev_warn(&host->pdev->dev, "Spurious CMD irq\n");
		return;
	}
	host->cmd = NULL;

        LOGV (("lowrisc_sd_cmd_irq IRQ line %d\n", __LINE__));
	if (cmd->resp_type & MMC_RSP_PRESENT && cmd->resp_type & MMC_RSP_136) {
	  int i;
	  LOGV (("lowrisc_sd_cmd_irq IRQ line %d\n", __LINE__));
		/* R2 */
	  for (i = 0;i < 4;i++)
	    {
	    cmd->response[i] = sd_base[resp0 + (3-i)] << 8;
	    if (i != 3)
	      cmd->response[i] |= sd_base[resp0 + (2-i)] >> 24;
	    } 
	} else if (cmd->resp_type & MMC_RSP_PRESENT) {
	  LOGV (("lowrisc_sd_cmd_irq IRQ line %d\n", __LINE__));
		/* R1, R1B, R3, R6, R7 */
	  cmd->response[0] = sd_base[resp0];
	}

LOGV (("Command IRQ complete %d %d %x\n", cmd->cmdidx, host->error, cmd->resp_type));

	/* If there is data to handle we will
	 * finish the request in the mmc_data_end_irq handler.*/
	if (host->data)
	  {
	    host->int_en |= SD_CARD_RW_END;
	  }
	else
	  lowrisc_sd_finish_request(host);
}

static void lowrisc_sd_data_end_irq(struct lowrisc_sd_host *host)
{
	struct mmc_data *data = host->data;
        volatile uint64_t *sd_base = host->ioaddr;
	unsigned long flags;
	size_t blksize;
	u8 *buf;
        assert(sd_base == sd_base_addr);
       
	LOGV (("lowrisc_sd_data_end_irq\n"));

	host->data = NULL;

	if (!data) {
		dev_warn(&host->pdev->dev, "Spurious data end IRQ\n");
		return;
	}

        if (data->flags & MMC_DATA_READ)
	  {
            u8 *buf = data->dest;
            sd_base += 0x1000;
	    blksize = data->blocksize;
            	  
	    while (blksize)
	      {
                u64 scratch64 = *sd_base++;
		memcpy(buf, &scratch64, sizeof(u64));
		buf+=8;
		blksize-=8;
	      }
	    
	  }

	LOGV (("Completed data request xfr=%d\n", data->blocks));

        //	iowrite16(0, host->ioaddr + SD_STOPINTERNAL);

	lowrisc_sd_finish_request(host);
}

static irqreturn_t lowrisc_sd_irq(int irq, void *dev_id)
{
	struct lowrisc_sd_host *host = dev_id;
        volatile uint64_t *sd_base = host->ioaddr;
	u32 int_reg, int_status;
	int error = 0, ret = IRQ_HANDLED;
        assert(sd_base == sd_base_addr);

	int_status = sd_base[irq_stat_resp];
	int_reg = int_status & host->int_en;

	LOGV (("lowrisc_sd IRQ status:%x enabled:%x\n", int_status, host->int_en));

	/* nothing to do: it's not our IRQ */
	if (!int_reg) {
		ret = IRQ_NONE;
		goto irq_end;
	}

	if (sd_base[wait_resp] >= sd_base[timeout_resp]) {
		error = -ETIMEDOUT;
		LOGV (("lowrisc_sd timeout %d clocks\n", sd_base[timeout_resp]));
	} else if (int_reg & 0) {
		error = -EILSEQ;
		dev_err(&host->pdev->dev, "BadCRC\n");
        }
        
        LOGV (("lowrisc_sd IRQ line %d\n", __LINE__));

	if (error) {
	  LOGV (("lowrisc_sd IRQ line %d\n", __LINE__));
		if (host->cmd)
			host->error = error;

		if (error == -ETIMEDOUT) {
		  LOGV (("lowrisc_sd IRQ line %d\n", __LINE__));
                  sd_cmd_start(host, 0);
                  sd_setting(host, 0);
		} else {
		  LOGV (("lowrisc_sd IRQ line %d\n", __LINE__));
			lowrisc_sd_init(host);
                        //			__lowrisc_sd_set_ios(host->mmc, &host->mmc->ios);
			goto irq_end;
		}
	}

        LOGV (("lowrisc_sd IRQ line %d\n", __LINE__));

        /* Card insert/remove. The mmc controlling code is stateless. */
	if (int_reg & SD_CARD_CARD_REMOVED_0)
	  {
	    int mask = (host->int_en & ~SD_CARD_CARD_REMOVED_0) | SD_CARD_CARD_INSERTED_0;
	    sd_irq_en(host, mask);
	    LOG (("Card removed, mask changed to %d\n", mask));
	  }
	
        LOGV (("lowrisc_sd IRQ line %d\n", __LINE__));
	if (int_reg & SD_CARD_CARD_INSERTED_0)
	  {
	    int mask = (host->int_en & ~SD_CARD_CARD_INSERTED_0) | SD_CARD_CARD_REMOVED_0 ;
	    sd_irq_en(host, mask);
	    LOG (("Card inserted, mask changed to %d\n", mask));
	    lowrisc_sd_init(host);
	  }

        LOGV (("lowrisc_sd IRQ line %d\n", __LINE__));
	/* Command completion */
	if (int_reg & SD_CARD_RESP_END) {
	  LOGV (("lowrisc_sd IRQ line %d\n", __LINE__));

		lowrisc_sd_cmd_irq(host);
		host->int_en &= ~SD_CARD_RESP_END;
	}

        LOGV (("lowrisc_sd IRQ line %d\n", __LINE__));
	/* Data transfer completion */
	if (int_reg & SD_CARD_RW_END) {
	  LOGV (("lowrisc_sd IRQ line %d\n", __LINE__));

		lowrisc_sd_data_end_irq(host);
		host->int_en &= ~SD_CARD_RW_END;
	}
irq_end:
        sd_irq_en(host, host->int_en);
	return ret;
}

static void lowrisc_sd_start_cmd(struct lowrisc_sd_host *host, struct mmc_cmd *cmd)
{
  int setting = 0;
  int timeout = 1000000;
  struct mmc_data *data = host->data;
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);

  LOGV (("Command opcode: %d\n", cmd->cmdidx));
/*
  if (cmd->opc == MMC_STOP_TRANSMISSION) {
    sd_cmd(host, SD_STOPINT_ISSUE_CMD12);

    cmd->response[0] = cmd->opc;
    cmd->response[1] = 0;
    cmd->response[2] = 0;
    cmd->response[3] = 0;
    
    lowrisc_sd_finish_request(host);
    return;
  }
*/
  if (!(cmd->resp_type & MMC_RSP_PRESENT))
    setting = 0;
  else if (cmd->resp_type & MMC_RSP_136)
    setting = 3;
  else if (cmd->resp_type & MMC_RSP_BUSY)
    setting = 1;
  else
    setting = 1;
  setting |= host->width_setting;
  
  host->cmd = cmd;
  
  if (cmd->cmdidx == R1_APP_CMD)
    {
      /* placeholder */
    }
  
  if (cmd->cmdidx == MMC_CMD_GO_IDLE_STATE)
    {
      /* placeholder */
    }

  LOGV (("testing resp flags %X\n", setting));
  if (data) {
    setting |= 0x4;
    if (data->flags & MMC_DATA_READ)
      {
      setting |= 0x10;
      LOGV(("data_read, blksz=%d\n", data->blocksize));
      }
    else
      {
      setting |= 0x8;
      LOGV(("data_write, blksz=%d\n", data->blocksize));
      }
  }

  LOGV (("writing registers\n"));
  /* Send the command */
  sd_reset(host, 0,1,0,1);
  sd_align(host, 0);
  sd_arg(host, cmd->cmdarg);
  sd_cmd(host, cmd->cmdidx);
  sd_setting(host, setting);
  sd_cmd_start(host, 0);
  sd_reset(host, 0,1,1,1);
  sd_timeout(host, timeout);
  /* start the transaction */ 
  sd_cmd_start(host, 1);
  LOGV (("enabling interrupt\n"));
  sd_irq_en(host, sd_base[irq_en_resp] | SD_CARD_RESP_END);
 LOGV (("leaving lowrisc_sd_start_cmd\n"));
}

static void lowrisc_sd_start_data(struct lowrisc_sd_host *host, struct mmc_data *data)
{
	unsigned int flags = 0;

	LOGV (("setup data transfer: blocksize %08x  nr_blocks %d, flags: %08x\n",
	      data->blocksize, data->blocks, data->flags));

	host->data = data;

	/* Set transfer length and blocksize */
	sd_blkcnt(host, data->blocks);
	sd_blksize(host, data->blocksize);

        if (!(data->flags & MMC_DATA_READ))
	  {
        volatile uint64_t *sd_base = host->ioaddr;
	struct mmc_data *data = host->data;

{
  size_t blksize, len, chunk;
  u32 scratch, i = 0;
  u8 *buf;
  LOGV (("count: %08x, flags %08x\n", data->blocksize, data->flags));

	blksize = data->blocksize;
	chunk = 0;
	scratch = 0;

	len = blksize;

	blksize -= len;
	buf = data->src;

	while (len) {
			scratch |= (u32)*buf << (chunk * 8);

			buf++;
			chunk++;
			len--;

			if ((chunk == 4) || ((len == 0) && (blksize == 0))) {
			  sd_base[0x2000 + i++] = __cpu_to_be32(scratch);
				chunk = 0;
				scratch = 0;
			}
	}

	  }
        }
}

static void lowrisc_sd_set_ios(struct mmc *mmc, struct mmc_ios *ios)
{
	struct lowrisc_sd_host *host = mmc_priv(mmc);
	unsigned long flags;

	__lowrisc_sd_set_ios(mmc, ios);
}

static int lowrisc_sd_get_ro(struct mmc *mmc)
{
	struct lowrisc_sd_host *host = mmc_priv(mmc);
        volatile uint64_t *sd_base = host->ioaddr;
	return sd_base[detect_resp];
}

static int lowrisc_sd_get_cd(struct mmc *mmc)
{
	struct lowrisc_sd_host *host = mmc_priv(mmc);
        volatile uint64_t *sd_base = host->ioaddr;

	return !sd_base[detect_resp];
}

static int lowrisc_sd_card_busy(struct mmc *mmc)
{
	struct lowrisc_sd_host *host = mmc_priv(mmc);
        volatile uint64_t *sd_base = host->ioaddr;
	return sd_base[resp0] >> 31;
}

static inline void lowrisc_writeq(struct lowrisc_sd_host *host, int reg, u64 val)
{
  debug("lowrisc_writeq(%p,%x,%x);\n", host, reg, val);
}

static inline u64 lowrisc_readq(struct lowrisc_sd_host *host, int reg)
{
  debug("lowrisc_readq(%p,%x,%x);\n", host, reg);
  return 0;
}

static inline void lowrisc_writew(struct lowrisc_sd_host *host, int reg, u16 val)
{
  debug("lowrisc_writew(%p,%x,%x);\n", host, reg, val);
}

static inline u16 lowrisc_readw(struct lowrisc_sd_host *host, int reg)
{
  debug("lowrisc_readw(%p,%x,%x);\n", host, reg);
  return 0;
}

static int lowrisc_wait_interrupt_flag(struct lowrisc_sd_host *host)
{
	int timeout = 10000000;

	while (1) {
		timeout--;
		if (timeout < 0) {
			debug(DRIVER_NAME": %s timeout\n", __func__);
			return 0;
		}

		if (!lowrisc_sd_irq(1, host))
			break;

		udelay(1);	/* 1 usec */
	}

	return 1; /* Return value: NOT 0 = complete waiting */
}

static int lowrisc_clock_control(struct lowrisc_sd_host *host, unsigned long clk)
{
	u32 clkdiv, i, timeout;

        return -EIO;
}

static int lowrisc_sync_reset(struct lowrisc_sd_host *host)
{
	sd_reset(host, 0,1,0,1);
	sd_cmd_start(host, 0);
	sd_reset(host, 0,1,1,1);
	lowrisc_sd_set_led(host, 0);
	return 0;
}

static int lowrisc_single_read(struct lowrisc_sd_host *host, struct mmc_data *data)
{
	long time;
	unsigned short blocksize, i;
	unsigned short *p = (unsigned short *)data->dest;
	u64 *q = (u64 *)data->dest;

	if ((unsigned long)p & 0x00000001) {
		debug(DRIVER_NAME": %s: The data pointer is unaligned.",
		      __func__);
		return -EIO;
	}

	host->wait_int = 0;
	host->wait_int = 0;
	return 0;
}

static int lowrisc_multi_read(struct lowrisc_sd_host *host, struct mmc_data *data)
{
	long time;
	unsigned short blocksize, sec;
	unsigned short *p = (unsigned short *)data->dest;
	u64 *q = (u64 *)data->dest;

	if ((unsigned long)p & 0x00000001) {
		debug(DRIVER_NAME": %s: The data pointer is unaligned.",
		      __func__);
		return -EIO;
	}

	debug("%s: blocks = %d, blocksize = %d\n",
	      __func__, data->blocks, data->blocksize);

	host->wait_int = 0;
	for (sec = 0; sec < data->blocks; sec++) {
	}

	return 0;
}

static int lowrisc_single_write(struct lowrisc_sd_host *host,
		struct mmc_data *data)
{
	long time;
	unsigned short blocksize, i;
	const unsigned short *p = (const unsigned short *)data->src;
	const u64 *q = (const u64 *)data->src;

	if ((unsigned long)p & 0x00000001) {
		debug(DRIVER_NAME": %s: The data pointer is unaligned.",
		      __func__);
		return -EIO;
	}

	debug("%s: blocks = %d, blocksize = %d\n",
	      __func__, data->blocks, data->blocksize);

	host->wait_int = 0;
	host->wait_int = 0;
	return 0;
}

static int lowrisc_multi_write(struct lowrisc_sd_host *host, struct mmc_data *data)
{
	long time;
	unsigned short i, sec, blocksize;
	const unsigned short *p = (const unsigned short *)data->src;
	const u64 *q = (const u64 *)data->src;

	debug("%s: blocks = %d, blocksize = %d\n",
	      __func__, data->blocks, data->blocksize);

	host->wait_int = 0;
	for (sec = 0; sec < data->blocks; sec++) {
	}

	return 0;
}

static unsigned short lowrisc_set_cmd(struct lowrisc_sd_host *host,
			struct mmc_data *data, unsigned short opc)
{
	if (host->app_cmd) {
		if (!data)
			host->app_cmd = 0;
		return opc | BIT(6);
	}

	switch (opc) {
	case MMC_CMD_SWITCH:
		return opc | (data ? 0x1c00 : 0x40);
	case MMC_CMD_SEND_EXT_CSD:
		return opc | (data ? 0x1c00 : 0);
	case MMC_CMD_SEND_OP_COND:
		return opc | 0x0700;
	case MMC_CMD_APP_CMD:
		host->app_cmd = 1;
	default:
		return opc;
	}
}

static unsigned short lowrisc_data_trans(struct lowrisc_sd_host *host,
			struct mmc_data *data, unsigned short opc)
{
	if (host->app_cmd) {
		host->app_cmd = 0;
		switch (opc) {
		case SD_CMD_APP_SEND_SCR:
		case SD_CMD_APP_SD_STATUS:
			return lowrisc_single_read(host, data);
		default:
			printf(DRIVER_NAME": SD: NOT SUPPORT APP CMD = d'%04d\n",
				opc);
			return -EINVAL;
		}
	} else {
		switch (opc) {
		case MMC_CMD_WRITE_MULTIPLE_BLOCK:
			return lowrisc_multi_write(host, data);
		case MMC_CMD_READ_MULTIPLE_BLOCK:
			return lowrisc_multi_read(host, data);
		case MMC_CMD_WRITE_SINGLE_BLOCK:
			return lowrisc_single_write(host, data);
		case MMC_CMD_READ_SINGLE_BLOCK:
		case MMC_CMD_SWITCH:
		case MMC_CMD_SEND_EXT_CSD:;
			return lowrisc_single_read(host, data);
		default:
			printf(DRIVER_NAME": SD: NOT SUPPORT CMD = d'%04d\n", opc);
			return -EINVAL;
		}
	}
}

static int lowrisc_start_cmd(struct lowrisc_sd_host *host,
			struct mmc_data *data, struct mmc_cmd *cmd)
{
	long time;
	unsigned short shcmd, opc = cmd->cmdidx;
	int ret = 0;
	unsigned long timeout;
        host->cmdidx = opc;
        host->data = data;
        
        memset(cmd->response, 0, sizeof(*(cmd->response)));
        
	LOGV(("opc = %d, arg = %x, resp_type = %x\n",
	      opc, cmd->cmdarg, cmd->resp_type));

	if (data)
		lowrisc_sd_start_data(host, data);
        
	lowrisc_sd_set_led(host, 1);

        lowrisc_sd_start_cmd(host, cmd);

        while (host->int_en)
          lowrisc_wait_interrupt_flag(host);

        switch(opc)
          {
          case 0:
          case 41:
          case 55:
            LOGV(("opc = %d, arg = %x, resp_type = %x, ",
	      opc, cmd->cmdarg, cmd->resp_type));
            LOGV(("resp = %08x, %08x, %08x, %08x\n",
                  cmd->response[0], cmd->response[1],
                  cmd->response[2], cmd->response[3]));
            break;
          default:
            LOGV(("opc = %d, arg = %x, resp_type = %x, ",
	      opc, cmd->cmdarg, cmd->resp_type));
            LOGV(("resp = %08x, %08x, %08x, %08x\n",
                  cmd->response[0], cmd->response[1],
                  cmd->response[2], cmd->response[3]));
            break;
          }
	return ret;
}

static int lowrisc_send_cmd_common(struct lowrisc_sd_host *host,
				   struct mmc_cmd *cmd, struct mmc_data *data)
{
	host->sd_error = 0;

	return lowrisc_start_cmd(host, data, cmd);
}

static int lowrisc_set_ios_common(struct lowrisc_sd_host *host, struct mmc *mmc)
{
	int ret;

	if (mmc->bus_width == 8)
          return -EIO;
	else if (mmc->bus_width == 4)
          host->width_setting = 0x20;
	else
          host->width_setting = 0;

	LOGV(("clock = %d, buswidth = %d\n", mmc->clock, mmc->bus_width));

	return 0;
}

static int lowrisc_initialize_common(struct lowrisc_sd_host *host)
{
	int ret = lowrisc_sync_reset(host);

	return ret;
}

static int lowrisc_send_cmd(struct mmc *mmc, struct mmc_cmd *cmd,
			    struct mmc_data *data)
{
	struct lowrisc_sd_host *host = mmc_priv(mmc);

	return lowrisc_send_cmd_common(host, cmd, data);
}

static int lowrisc_set_ios(struct mmc *mmc)
{
	struct lowrisc_sd_host *host = mmc_priv(mmc);

	return lowrisc_set_ios_common(host, mmc);
}

static int lowrisc_initialize(struct mmc *mmc)
{
	struct lowrisc_sd_host *host = mmc_priv(mmc);

	return lowrisc_initialize_common(host);
}

static const struct mmc_ops lowrisc_ops = {
	.send_cmd       = lowrisc_send_cmd,
	.set_ios        = lowrisc_set_ios,
	.init           = lowrisc_initialize,
};

static const struct mmc_config lowrisc_cfg = {
	.name           = DRIVER_NAME,
	.ops            = &lowrisc_ops,
	.f_min          = 5000000,
	.f_max          = 5000000,
	.voltages       = MMC_VDD_32_33 | MMC_VDD_33_34,
	.host_caps      = MMC_MODE_4BIT,
	.part_type      = PART_TYPE_DOS,
	.b_max          = CONFIG_SYS_MMC_MAX_BLK_COUNT,
};

int lowrisc_init(unsigned long addr, int ch, unsigned long quirks)
{
	int ret = 0;
	struct mmc *mmc;
	struct lowrisc_sd_host *host = NULL;

	if (ch >= CONFIG_SYS_SH_SDHI_NR_CHANNEL)
		return -ENODEV;

	host = malloc(sizeof(struct lowrisc_sd_host));
	if (!host)
		return -ENOMEM;

	mmc = mmc_create(&lowrisc_cfg, host);
        printf("mmc created at %x, host = %x\n", mmc, host);
	if (!mmc) {
		ret = -1;
		goto error;
	}

	host->ch = ch;
	host->ioaddr = (void __iomem *)SPIBase;
	host->quirks = quirks;

	if (host->quirks & SH_SDHI_QUIRK_64BIT_BUF)
		host->bus_shift = 2;
	else if (host->quirks & SH_SDHI_QUIRK_16BIT_BUF)
		host->bus_shift = 1;

	return ret;
error:
	if (host)
		free(host);
	return ret;
}

int board_mmc_init(bd_t *bis)
{
        return lowrisc_init(sd_base_addr, 0, SH_SDHI_QUIRK_64BIT_BUF);
}

// legacy function
uint32_t sd_resp(int sel)
{
  volatile uint64_t *sd_base = (volatile uint64_t *)sd_base_addr;
  uint32_t rslt = sd_base[sel];
  return rslt;
}

int board_mmc_getcd(struct mmc *mmc)                                                                                                                    
{
  struct lowrisc_sd_host *host = mmc_priv(mmc);
  volatile uint64_t *sd_base = host->ioaddr;
  assert(sd_base == sd_base_addr);
  return sd_base[detect_resp] ? 1 : -1;
}

void read_block(void *dst, int sect)
{
  int fat;
  struct mmc *mmc = find_mmc_device(0);
#if 0
  disk_partition_t info;
  struct blk_desc *dev_desc = &mmc->block_dev;
  part_get_info_whole_disk(dev_desc, &info);
  fat_set_blk_dev(dev_desc, &info);
#endif
  mmc_read_blocks(mmc, dst, sect, 1);
  return 0;
}

int init_mmc_standalone(int sd_base_addr)
{
  int i;
  struct mmc *mmc;
  char *bsect = malloc(512);
  char * const cmdargv[] = {"mmcinfo", 0};
  puts("MMC:   ");
  mmc_initialize(gd->bd);
  mmc = find_mmc_device(0);
  mmc_init(mmc);
  printf("Device: %s\n", mmc->cfg->name);
  printf("Manufacturer ID: %x\n", mmc->cid[0] >> 24);
  printf("OEM: %x\n", (mmc->cid[0] >> 8) & 0xffff);
  printf("Name: %c%c%c%c%c \n", mmc->cid[0] & 0xff,
         (mmc->cid[1] >> 24), (mmc->cid[1] >> 16) & 0xff,
         (mmc->cid[1] >> 8) & 0xff, mmc->cid[1] & 0xff);
  
  printf("Bus Speed: %d\n", mmc->clock);
  printf("High Capacity: %s\n", mmc->high_capacity ? "Yes" : "No");
  puts("Capacity: ");
  print_size(mmc->capacity, "\n");
  
  printf("Bus Width: %d-bit%s\n", mmc->bus_width,
         mmc->ddr_mode ? " DDR" : "");

  read_block(bsect, 0);
  for (i = 0; i < 512; i++)
    {
      if (i%32 == 0)
        printf("\n%x: ", i);
      printf(" %x%x", bsect[i]>>4, bsect[i]&0xf);
    }
  printf("\n");
  return 0;
}
