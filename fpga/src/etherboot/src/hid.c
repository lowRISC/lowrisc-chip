// See LICENSE.Cambridge for license details.

#include <stddef.h>
#include <string.h>
#include "uart.h"
#include "hid.h"
#include "mini-printf.h"

const struct { char scan,lwr,upr; } scancode[] = {
#include "scancode.h"
  };

// VGA tuning registers
volatile uint64_t *const hid_reg_ptr = (volatile uint64_t *)(VgaBase+16384);
volatile uint64_t *const hid_plt_ptr = (volatile uint64_t *)(VgaBase+16384+2048);
// VGA frame buffer
volatile uint64_t *const hid_fb_ptr = (volatile uint64_t *)(FbBase);
// HID keyboard
volatile uint32_t *const keyb_base = (volatile uint32_t *)KeybBase;
// HID mouse
volatile uint64_t *const mouse_base = (volatile uint64_t *)MouseBase;

void uart_console_putchar(unsigned char ch)
{
  write_serial(ch);
}  

void hid_init(void)
{
  enum {width=1024, height=768, xpixels=768, ypixels=682};
  int i, ghlimit = xpixels/8;
  unsigned char *fb_ptr = (unsigned char *)hid_fb_ptr;
  for (i = 0; i < 256; i++)
    hid_plt_ptr[i] = rand32();

  for (i = 0; i < ghlimit*8; i++)
    fb_ptr[i*ghlimit*8 + i] = i;
  
  hid_reg_ptr[LOWRISC_REGS_CURSV] = 10;
  hid_reg_ptr[LOWRISC_REGS_XCUR] = 0;
  hid_reg_ptr[LOWRISC_REGS_YCUR] = 32;
  hid_reg_ptr[LOWRISC_REGS_HSTART] = width*2;
  hid_reg_ptr[LOWRISC_REGS_HSYN] = width*2+20;
  hid_reg_ptr[LOWRISC_REGS_HSTOP] = width*2+51;
  hid_reg_ptr[LOWRISC_REGS_VSTART] = height;
  hid_reg_ptr[LOWRISC_REGS_VSTOP] = height+19;
  hid_reg_ptr[LOWRISC_REGS_VPIXSTART ] = 16;
  hid_reg_ptr[LOWRISC_REGS_VPIXSTOP ] = ypixels+16;
  hid_reg_ptr[LOWRISC_REGS_HPIXSTART ] = 378;
  hid_reg_ptr[LOWRISC_REGS_HPIXSTOP ] = xpixels*2 + 378;
  hid_reg_ptr[LOWRISC_REGS_HPIX ] = 5;
  hid_reg_ptr[LOWRISC_REGS_VPIX ] = 11; // squashed vertical display uses 10
  hid_reg_ptr[LOWRISC_REGS_GHLIMIT] = ghlimit / 2;
  
  draw_logo(ghlimit);
  /*  
  for (i = 0; i < ypixels; i++)
    {
      int j;
      for (j = 0; j < xpixels; j += 100)
        {
        fb_ptr[i*ghlimit*8 + j + 4] = 15;
        fb_ptr[i*ghlimit*8 + j] = 15;
        }
      fb_ptr[i*ghlimit*8 + xpixels-1] = 15;
    }
  */
}

void hid_send_irq(uint8_t data)
{

}

void hid_send(uint8_t data)
{
  uart_console_putchar(data);
}

void hid_send_string(const char *str) {
  while (*str) hid_send(*str++);
}

void hid_send_buf(const char *buf, const int32_t len)
{
  int32_t i;
  for (i=0; i<len; i++) hid_send(buf[i]);
}

uint8_t hid_recv()
{
  return -1;
}

// IRQ triggered read
uint8_t hid_read_irq() {
  return -1;
}

// check hid IRQ for read
uint8_t hid_check_read_irq() {
  return 0;
}

// enable hid read IRQ
void hid_enable_read_irq() {

}

// disable hid read IRQ
void hid_disable_read_irq() {

}

int hid_putc(int c, ...) {
  hid_send(c);
  return c;
}

int hid_puts(const char *str) {
  while (*str) hid_send(*str++);
  hid_send('\n');
  return 0;
}

void keyb_main(void)
{
  int i;
  int height = 11;
  int width = 5;
  for (;;)
    {
      uint64_t mouse_ev;
      int scan, ascii, event = *keyb_base;
      if (0x200 & ~event)
        {
          *keyb_base = 0; // pop FIFO
          event = *keyb_base & ~0x200;
          scan = scancode[event&~0x100].scan;
          ascii = scancode[event&~0x100].lwr;
          printf("Keyboard event = %X, scancode = %X, ascii = '%c'\n", event, scan, ascii);
          if (0x100 & ~event) switch(scan)
            {
            case 0x50: hid_reg_ptr[LOWRISC_REGS_VPIX] = ++height; printf(" %d,%d", height, width); break;
            case 0x48: hid_reg_ptr[LOWRISC_REGS_VPIX] = --height; printf(" %d,%d", height, width); break;
            case 0x4D: hid_reg_ptr[LOWRISC_REGS_HPIX] = ++width; printf(" %d,%d", height, width); break;
            case 0x4B: hid_reg_ptr[LOWRISC_REGS_HPIX] = --width; printf(" %d,%d", height, width); break;
            case 0xE0: break;
            case 0x39: for (i = 33; i < 47; i++) hid_reg_ptr[i] = rand32(); break;
            default: printf("?%x", scan); break;
            }
        }
      mouse_ev = *mouse_base;
      if (0x100000000ULL & ~mouse_ev)
        {
          *mouse_base = 0; // pop FIFO
          mouse_ev = *mouse_base;
          {
            int X = mouse_ev & 1023;
            int Y = (mouse_ev>>12) & 1023;
            int Z = (mouse_ev>>24) & 15;
            int ev = (mouse_ev>>28) & 1;
            int right = (mouse_ev>>29) & 1;
            int middle = (mouse_ev>>30) & 1;
            int left = (mouse_ev>>31) & 1;
            printf("Mouse event %X: X=%d, Y=%d, Z=%d, ev=%d, left=%d, middle=%d, right=%d\n",
                   (uint32_t)mouse_ev, X, Y, Z, ev, left, middle, right);
          }
        }
    }
}
