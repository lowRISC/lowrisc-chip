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

FATFS FatFs;   // Work area (file system object) for logical drive

// max size of file image is 16M
#define MAX_FILE_SIZE 0x1000000

// 4K size read burst
#define SD_READ_SIZE 4096

//char md5buf[SD_READ_SIZE];

void just_jump (int64_t entry)
{
  extern uint8_t _dtb[];
  void (*fun_ptr)(uint64_t, void *) = (void*)entry;
  printf("Boot the loaded program at address %p...\n", fun_ptr);
  asm volatile ("fence.i");
  asm volatile ("fence");
  fun_ptr(read_csr(mhartid), _dtb);
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
  else
      {
        int cnt = off / SD_READ_SIZE;
	write_serial('\b');
	write_serial("|/-\\"[cnt&3]);
        gpio_leds(cnt);
      }
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
  print_uart_int(code);
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

int init_mmc_standalone(int sd_base_addr);

DSTATUS disk_initialize (uint8_t pdrv)
{
  printf("\nu-boot based first stage boot loader\n");
  init_mmc_standalone(SPIBase);
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

int do_load(void *cmdtp, int flag, int argc, char * const argv[], int fstype)
{
  return 1;
}

int do_ls(void *cmdtp, int flag, int argc, char * const argv[], int fstype)
{
  return 1;
}

int do_size(void *cmdtp, int flag, int argc, char * const argv[], int fstype)
{
                return 1;
}

DRESULT disk_read (uint8_t pdrv, uint8_t *buff, uint32_t sector, uint32_t count)
{
  while (count--)
    {
      read_block(buff, sector++);
      buff += 512;
    }
  return FR_OK;
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

void part_init(void *bdesc)
{

}

void part_print(void *desc)
{

}

void dev_print(void *bdesc)
{

}

unsigned long mmc_berase(void *dev, int start, int blkcnt)
{
        return 0;
}

unsigned long mmc_bwrite(void *dev, int start, int blkcnt, const void *src)
{
        return 0;
}

void puts(const char *str)
{
  print_uart(str);
}

const char version_string[] = "LowRISC minimised u-boot for SD-Card";
