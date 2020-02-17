// See LICENSE for license details.

//#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <memory.h>
#include "encoding.h"
#include "mini-printf.h"
#include "diskio.h"
#include "ff.h"
#include "bits.h"
#include "uart.h"
#include "eth.h"
#include "elfriscv.h"
#include "ariane.h"
#include "lowrisc_pitonsd.h"

#define DUMP_REGS

volatile uint64_t *const sd_base = (volatile uint64_t *)SDBase;
volatile uint64_t *const sd_bram = (volatile uint64_t *)(SDBase + 0x8000);

FATFS FatFs;   // Work area (file system object) for logical drive

void just_jump (int64_t entry)
{
  extern uint8_t _dtb[];
  void (*fun_ptr)(uint64_t, void *) = (void*)entry;
  uint32_t hart = read_csr(mhartid);
  printf("Boot the loaded program at address $pc=%p $a0=%x $a1=%p...\n", fun_ptr, hart, _dtb);
  asm volatile ("fence.i");
  asm volatile ("fence");
  fun_ptr(hart, _dtb);
}

static int sd_len_err;
static FIL fil;                // File object
static uint32_t sd_seek;

void sd_elfn(void *dst, uint32_t off, uint32_t sz)
{
  FRESULT fr;             // FatFs return code
  // Read file into memory from DOS filing system
  uint32_t len;   // Read count
  if (off != sd_seek)
    {
      fr = f_lseek (&fil, off);
      if (fr)
        {
          sd_len_err = fr;
          return;
        }
    }
  else
    sd_seek = ~0;
  fr = f_read(&fil, dst, sz, &len);  // Read a chunk of source file
  if (fr) sd_len_err = fr;
  if (len < sz)
    {
      printf("len required = %X, actual = %x\n", sz, len);
      sd_len_err = 1; /* internal damaged */
    }
  else
    sd_seek = off+sz;
}

void sd_main(int sw)
{
  FRESULT fr;             // FatFs return code
  int64_t entry;
  // Register work area to the default drive
  if(f_mount(&FatFs, "", 1)) {
    printf("Fail to mount SD driver!\n");
    return;
  }

  // Open a file
  printf("Load boot.bin into memory\n");
  fr = f_open(&fil, "boot.bin", FA_READ);
  if (fr) {
    printf("Failed to open boot!\n");
    return;
  }

  // read elf
  printf("load elf to DDR memory\n");
  sd_len_err = 0;
  sd_seek = 0;
  entry = load_elf(sd_elfn);
  if ((entry < 0) || sd_len_err)
    {
    printf("elf read failed with code %ld", -entry);
    return;
    }
  
  // Close the file
  if(f_close(&fil)) {
    printf("fail to close file!");
    return;
  }
  if(f_mount(NULL, "", 1)) {         // unmount it
    printf("fail to umount disk!");
    return;
  }

#ifdef VERBOSE_MD5
  uint8_t *hashbuf;
  hashbuf = hash_buf(boot_file_buf, fsize);
  printf("hash = %s\n", hashbuf);
#endif 
  just_jump(entry);
  /* unreachable code to prevent warnings */
  LD_WORD(NULL);
  LD_DWORD(NULL);
  ST_WORD(NULL, 0);
  ST_DWORD(NULL, 0);
}

#define HELLO "Hello LowRISC! "__TIMESTAMP__": "

int lowrisc_init(unsigned long addr, int ch, unsigned long quirks);
void tohost_exit(long code)
{
  print_uart_int(UARTBase, code);
  for (;;)
    ;
}

unsigned long get_tbclk (void)
{
	unsigned long long tmp = 1000000;
	return tmp;
}

char *env_get(const char *name)
{
  return (char *)0;
}

void *malloc(size_t len)
{
  static unsigned long rused = 0;
  char *rd = rused + (char *)(DRAMBase+0x6800000);
  rused += ((len-1)|7)+1;
  return rd;
}

void *calloc(size_t nmemb, size_t size)
{
  size_t siz = nmemb*size;
  char *ptr = malloc(siz);
  if (ptr)
    {
      memset(ptr, 0, siz);
      return ptr;
    }
  else
    return (void*)0;
}

void free(void *ptr)
{

}

#ifdef DUMP_REGS
static void pitonsd_dump_regs(void)
{
  static char init_state_num[10], tran_state_num[10];
  const char *init_state = init_state_num, *tran_state = tran_state_num;
  char status[99];
  int stat = sd_base[_piton_sd_STATUS];
  *status = 0;
  if (stat&1) strcat(status," REQ_RD");
  if (stat&2) strcat(status," REQ_WR");
  if (stat&4) strcat(status," IRQ_EN");
  if (stat&8) strcat(status," SD_IRQ");
  if (stat&16) strcat(status," REQ_RDY");
  if (stat&32) strcat(status," INIT_DONE");
  if (stat&64) strcat(status," HCXC");
  if (stat&128) strcat(status," DETECT");
#ifdef DUMP_REGS_VERBOSE
  switch(sd_base[_piton_sd_INIT_STATE])
    {
    case 0x0: init_state = "ST_CI_EN_SW_RST"; break;
    case 0x1: init_state = "ST_CI_DAT_TIMEOUT"; break;
    case 0x2: init_state = "ST_CI_BUS_WIDTH"; break;
    case 0x3: init_state = "ST_CI_CMD_TIMEOUT"; break;
    case 0x4: init_state = "ST_CI_CMD_ISER"; break;
    case 0x5: init_state = "ST_CI_DAT_ISER"; break;
    case 0x6: init_state = "ST_CI_BLK_SIZE"; break;
    case 0x7: init_state = "ST_CI_BLK_COUNT"; break;
    case 0x8: init_state = "ST_CI_CLOCK_DIV"; break;
    case 0x9: init_state = "ST_CI_DE_SW_RST"; break;
    case 0xa: init_state = "ST_CI_WAIT_POWER"; break;

    case 0x10: init_state = "ST_CMD0_CLR_CMD_ISR"; break;
    case 0x11: init_state = "ST_CMD0_WAIT_CLR"; break;
    case 0x12: init_state = "ST_CMD0_CMD"; break;
    case 0x13: init_state = "ST_CMD0_ARG"; break;
    case 0x14: init_state = "ST_CMD0_WAIT_INT"; break;
    case 0x15: init_state = "ST_CMD0_RD_CMD_ISR"; break;

    case 0x20: init_state = "ST_CMD8_CLR_CMD_ISR"; break;
    case 0x21: init_state = "ST_CMD8_WAIT_CLR"; break;
    case 0x22: init_state = "ST_CMD8_CMD"; break;
    case 0x23: init_state = "ST_CMD8_ARG"; break;
    case 0x24: init_state = "ST_CMD8_WAIT_INT"; break;
    case 0x25: init_state = "ST_CMD8_RD_CMD_ISR"; break;
    case 0x26: init_state = "ST_CMD8_RD_RESP0"; break;

    case 0x30: init_state = "ST_ACMD41_CMD55_CLR_CMD_ISR"; break;
    case 0x31: init_state = "ST_ACMD41_CMD55_WAIT_CLR"; break;
    case 0x32: init_state = "ST_ACMD41_CMD55_CMD"; break;
    case 0x33: init_state = "ST_ACMD41_CMD55_ARG"; break;
    case 0x34: init_state = "ST_ACMD41_CMD55_WAIT_INT"; break;
    case 0x35: init_state = "ST_ACMD41_CMD55_RD_CMD_ISR"; break;
    case 0x36: init_state = "ST_ACMD41_CMD55_RD_RESP0"; break;

    case 0x40: init_state = "ST_ACMD41_CLR_CMD_ISR"; break;
    case 0x41: init_state = "ST_ACMD41_WAIT_CLR"; break;
    case 0x42: init_state = "ST_ACMD41_CMD"; break;
    case 0x43: init_state = "ST_ACMD41_ARG"; break;
    case 0x44: init_state = "ST_ACMD41_WAIT_INT"; break;
    case 0x45: init_state = "ST_ACMD41_RD_CMD_ISR"; break;
    case 0x46: init_state = "ST_ACMD41_RD_RESP0"; break;
    case 0x47: init_state = "ST_ACMD41_WAIT_INTERVAL"; break;

    case 0x50: init_state = "ST_CMD2_CLR_CMD_ISR"; break;
    case 0x51: init_state = "ST_CMD2_WAIT_CLR"; break;
    case 0x52: init_state = "ST_CMD2_CMD"; break;
    case 0x53: init_state = "ST_CMD2_ARG"; break;
    case 0x54: init_state = "ST_CMD2_WAIT_INT"; break;
    case 0x55: init_state = "ST_CMD2_RD_CMD_ISR"; break;

    case 0x60: init_state = "ST_CMD3_CLR_CMD_ISR"; break;
    case 0x61: init_state = "ST_CMD3_WAIT_CLR"; break;
    case 0x62: init_state = "ST_CMD3_CMD"; break;
    case 0x63: init_state = "ST_CMD3_ARG"; break;
    case 0x64: init_state = "ST_CMD3_WAIT_INT"; break;
    case 0x65: init_state = "ST_CMD3_RD_CMD_ISR"; break;
    case 0x66: init_state = "ST_CMD3_RD_RESP0"; break;

    case 0x70: init_state = "ST_HS_EN_SW_RST"; break;
    case 0x71: init_state = "ST_HS_CLOCK_DIV"; break;
    case 0x72: init_state = "ST_HS_DE_SW_RST"; break;

    case 0x80: init_state = "ST_CMD7_CLR_CMD_ISR"; break;
    case 0x81: init_state = "ST_CMD7_WAIT_CLR"; break;
    case 0x82: init_state = "ST_CMD7_CMD"; break;
    case 0x83: init_state = "ST_CMD7_ARG"; break;
    case 0x84: init_state = "ST_CMD7_WAIT_INT"; break;
    case 0x85: init_state = "ST_CMD7_RD_CMD_ISR"; break;
    case 0x86: init_state = "ST_CMD7_RD_RESP0"; break;

    case 0x90: init_state = "ST_ACMD6_CMD55_CLR_CMD_ISR"; break;
    case 0x91: init_state = "ST_ACMD6_CMD55_WAIT_CLR"; break;
    case 0x92: init_state = "ST_ACMD6_CMD55_CMD"; break;
    case 0x93: init_state = "ST_ACMD6_CMD55_ARG"; break;
    case 0x94: init_state = "ST_ACMD6_CMD55_WAIT_INT"; break;
    case 0x95: init_state = "ST_ACMD6_CMD55_RD_CMD_ISR"; break;
    case 0x96: init_state = "ST_ACMD6_CMD55_RD_RESP0"; break;

    case 0xa0: init_state = "ST_ACMD6_CLR_CMD_ISR"; break;
    case 0xa1: init_state = "ST_ACMD6_WAIT_CLR"; break;
    case 0xa2: init_state = "ST_ACMD6_CMD"; break;
    case 0xa3: init_state = "ST_ACMD6_ARG"; break;
    case 0xa4: init_state = "ST_ACMD6_WAIT_INT"; break;
    case 0xa5: init_state = "ST_ACMD6_RD_CMD_ISR"; break;
    case 0xa6: init_state = "ST_ACMD6_RD_RESP0"; break;

    case 0xb0: init_state = "ST_FIN_CLR_CMD_ISR"; break;
    case 0xb1: init_state = "ST_FIN_CLR_DAT_ISR"; break;

    case 0xf0: init_state = "ST_INIT_DONE"; break;
    case 0xff: init_state = "ST_INIT_ERR"; break;
    default: init_state = "UNKNOWN";
    }
#else
  sprintf(init_state_num, "0x%x", sd_base[_piton_sd_INIT_STATE]);
#endif  
#ifdef DUMP_REGS_VERBOSE
  switch(sd_base[_piton_sd_TRAN_STATE])
    {
    case 0x3f: tran_state = "ST_RST"; break;

    case 0x00: tran_state = "ST_IDLE"; break;
    case 0x01: tran_state = "ST_OK_RESP_PENDING"; break;
    case 0x02: tran_state = "ST_ERR_RESP_PENDING"; break;
    case 0x03: tran_state = "ST_CLR_CMD_ISR"; break;
    case 0x04: tran_state = "ST_CLR_DAT_ISR"; break;

    case 0x10: tran_state = "ST_CMD17_DMA"; break;
    case 0x11: tran_state = "ST_CMD17_CMD"; break;
    case 0x12: tran_state = "ST_CMD17_WAIT_CLR"; break;
    case 0x13: tran_state = "ST_CMD17_ARG"; break;
    case 0x14: tran_state = "ST_CMD17_WAIT_CMD_INT"; break;
    case 0x15: tran_state = "ST_CMD17_RD_CMD_ISR"; break;
    case 0x16: tran_state = "ST_CMD17_RD_RESP0"; break;
    case 0x17: tran_state = "ST_CMD17_WAIT_DATA_INT"; break;
    case 0x18: tran_state = "ST_CMD17_RD_DATA_ISR"; break;

    case 0x20: tran_state = "ST_CMD24_DMA"; break;
    case 0x21: tran_state = "ST_CMD24_CMD"; break;
    case 0x22: tran_state = "ST_CMD24_WAIT_CLR"; break;
    case 0x23: tran_state = "ST_CMD24_ARG"; break;
    case 0x24: tran_state = "ST_CMD24_WAIT_CMD_INT"; break;
    case 0x25: tran_state = "ST_CMD24_RD_CMD_ISR"; break;
    case 0x26: tran_state = "ST_CMD24_RD_RESP0"; break;
    case 0x27: tran_state = "ST_CMD24_WAIT_DATA_INT"; break;
    case 0x28: tran_state = "ST_CMD24_RD_DATA_ISR"; break;
    default: tran_state = "UNKNOWN";
    }
#else
  sprintf(tran_state_num, "0x%x", sd_base[_piton_sd_TRAN_STATE]);
#endif  
  printf(
        "    sd_f:  0x%lx  dma_f: 0x%lx status: %s\n"
        "    resp_vec: 0x%lx  init_state: %s  counter: 0x%lx\n"
        "    init_fsm: 0x%lx  tran_state: %s  tran_fsm: 0x%lx\n",
        sd_base[_piton_sd_ADDR_SD_F],
        sd_base[_piton_sd_ADDR_DMA_F],
        status,
        sd_base[_piton_sd_ERROR],
        init_state,
        sd_base[_piton_sd_COUNTER],
        sd_base[_piton_sd_INIT_FSM],
        tran_state,
        sd_base[_piton_sd_TRAN_FSM]);
}
#endif

DSTATUS disk_initialize (uint8_t pdrv)
{
        int old_init_state = -1;
        /* SD sector address */
        sd_base[ _piton_sd_ADDR_SD ] = 0;
        /* always start at beginning of DMA buffer */
        sd_base[ _piton_sd_ADDR_DMA ] = 0;
        /* set sector count */
        sd_base[ _piton_sd_BLKCNT ] = 0;
        sd_base[ _piton_sd_REQ_RD ] = 0;
        sd_base[ _piton_sd_REQ_WR ] = 0;
        sd_base[ _piton_sd_IRQ_EN ] = 0;
        sd_base[ _piton_sd_SYS_RST ] = 0;

        /* reset HW state machine */
        sd_base[ _piton_sd_SYS_RST ] = 1;
        fence_io();
        do
          {
            int init_state = sd_base[_piton_sd_INIT_STATE];
#ifdef DUMP_REGS_VERBOSE
            printf("init_state = 0x%x\n", init_state);
#endif
#ifdef DUMP_REGS
            if (old_init_state != init_state)
              pitonsd_dump_regs();
#endif
            old_init_state = init_state;
          }
          while (old_init_state != 0xf0);
#ifdef DUMP_REGS
        pitonsd_dump_regs();
#endif
        return 0;
}

int ctrlc(void)
{
	return 0;
}

void *find_cmd_tbl(const char *cmd, void *table, int table_len)
{
  return (void *)0;
}

unsigned long timer_read_counter(void)
{
  return read_csr(0xb00) / 10;
}

void __assert_fail (const char *__assertion, const char *__file,
                           unsigned int __line, const char *__function)
{
  printf("assertion %s failed, file %s, line %d, function %s\n", __assertion, __file,  __line, __function);
  tohost_exit(1);
}

void *memalign(size_t alignment, size_t size)
{
  char *ptr = malloc(size+alignment);
  return (void*)((-alignment) & (size_t)(ptr+alignment));
}

DRESULT disk_read (uint8_t pdrv, uint8_t *buff, uint32_t sector, uint32_t count)
{
  uint64_t vec;
#ifdef DUMP_REGS_VERBOSE
  uint64_t stat2;
#endif
  uint64_t stat = 0xDEADBEEF;
  uint64_t mask = (1 << count) - 1;
  /* SD sector address */
  sd_base[ _piton_sd_ADDR_SD ] = sector;
  /* always start at beginning of DMA buffer */
  sd_base[ _piton_sd_ADDR_DMA ] = 0;
  /* set sector count */
  sd_base[ _piton_sd_BLKCNT ] = count;
  sd_base[ _piton_sd_REQ_RD ] = 1;
  fence_io();
#ifdef DUMP_REGS_VERBOSE
  printf("disk_read(0x%x, 0x%x, 0x%x, 0x%x);\n", pdrv, buff, sector, count);
#endif
  do
    {
#ifdef ISSUE_356
      fence(); /* This is needed for a suspected Ariane bug */
#endif      
      stat = sd_base[_piton_sd_STATUS];
#ifdef DUMP_REGS_VERBOSE
      stat2 = sd_base[_piton_sd_STATUS+32];
      printf("stat = 0x%x, stat2 = 0x%x\n", stat, stat2);
#endif
    }
  while (_piton_sd_STATUS_REQ_RDY & ~stat);
  sd_base[ _piton_sd_REQ_RD ] = 0;
  vec = sd_base[ _piton_sd_ERROR ] & mask;
  memcpy(buff, (void *)sd_bram, count*512);
  if (vec==mask)
    return FR_OK;
#ifdef DUMP_REGS
  pitonsd_dump_regs();
#endif  
  return FR_INT_ERR;
}

DRESULT disk_write (uint8_t pdrv, const uint8_t *buff, uint32_t sector, uint32_t count)
{
  return FR_INT_ERR;
}

DRESULT disk_ioctl (uint8_t pdrv, uint8_t cmd, void *buff)
{
  return FR_INT_ERR;
}

DSTATUS disk_status (uint8_t pdrv)
{
  return FR_INT_ERR;
}

void puts(const char *str)
{
  print_uart(UARTBase, str);
}
