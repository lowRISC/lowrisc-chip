// See LICENSE.Cambridge for license details.

#include <stddef.h>
#include <string.h>
#include "uart.h"
#include "hid.h"
#include "qspi.h"
#include "mini-printf.h"

const struct { char scan,lwr,upr; } scancode[] = {
#include "scancode.h"
  };

// VGA tuning registers
volatile uint64_t *const hid_reg_ptr = (volatile uint64_t *)(VgaBase+16384);
volatile uint64_t *const hid_plt_ptr = (volatile uint64_t *)(VgaBase+16384+8192);
// VGA frame buffer
volatile uint64_t *const hid_fb_ptr = (volatile uint64_t *)(FbBase);
// HID keyboard
volatile uint32_t *const keyb_base = (volatile uint32_t *)KeybBase;
// HID mouse
volatile uint64_t *const mouse_base = (volatile uint64_t *)MouseBase;

uint32_t def_palette[] = {
  0x0,
  0xffffff,
0x550000,
0xaa0000,
0xff0000,
0x5500,
0x555500,
0xaa5500,
0xff5500,
0xaa00,
0x55aa00,
0xaaaa00,
0xffaa00,
0xff00,
0x55ff00,
0xaaff00,
0xffff00,
0x55,
0x550055,
0xaa0055,
0xff0055,
0x5555,
0x555555,
0xaa5555,
0xff5555,
0xaa55,
0x55aa55,
0xaaaa55,
0xffaa55,
0xff55,
0x55ff55,
0xaaff55,
0xffff55,
0xaa,
0x5500aa,
0xaa00aa,
0xff00aa,
0x55aa,
0x5555aa,
0xaa55aa,
0xff55aa,
0xaaaa,
0x55aaaa,
0xaaaaaa,
0xffaaaa,
0xffaa,
0x55ffaa,
0xaaffaa,
0xffffaa,
0xff,
0x5500ff,
0xaa00ff,
0xff00ff,
0x55ff,
0x5555ff,
0xaa55ff,
0xff55ff,
0xaaff,
0x55aaff,
0xaaaaff,
0xffaaff,
0xffff,
0x55ffff,
0xaaffff,
0x151515,
0x2a2a2a,
0x404040,
0x6a6a6a,
0x808080,
0x959595,
0xbfbfbf,
0xd5d5d5,
0xeaeaea,
0x908070,
0x99aa22,
0xd9d9d9,
0xb3b3b3,
0x53ff,
0x5eff,
0x48ff,
0x42ff,
0x40ff,
0x4bff,
0x52ff,
0x54ff,
0x35ff,
0x51ff,
0x5cff,
0x30ff,
0x45ff,
0x20ff,
0x3ff,
0x16ff,
0x5dff,
0x38ff,
0x2ff,
0x9ff,
0x2bff,
0x33ff,
0x1aff,
0x13ff,
0x12ff,
0x57ff,
0xba7745,
0x784e87,
0x777588,
0x777e88,
0x777988,
0x785087,
0xa96c56,
0xa1705e,
0x774e88,
0x777688,
0x835b7c,
0x865679,
0xfe8d00,
0xf31200,
0xf20b00,
0xfe8f00,
0xfa6c00,
0xf10000,
0xf10100,
0xf42000,
0xf64000,
0xf05909,
0xe85811,
0xe85911,
0xf95800,
0xf41d00,
0xf42300,
0xfa5b00,
0xfa6000,
0xeb580e,
0xf35106,
0xf53300,
0xf20e00,
0xfa6e00,
0xff9200,
0xf41f00,
0xf20f00,
0xec510c,
0xc96a32,
0x83657a,
0x3462ca,
0x35ffc,
0x58ff,
0x8ff,
0xb06f4,
0xfb7c00,
0xf31300,
0xfb7e00,
0x18ff,
0xc59f3,
0x5261ab,
0xad4e4f,
0xe45c17,
0xf53600,
0xf42200,
0xfd9500,
0xfd8400,
0xf10400,
0xf85100,
0xc75a34,
0x1915e6,
0x59ff,
0x46ff,
0x1ff,
0xb96e44,
0xf63400,
0xf53200,
0x22ff,
0xfa6f00,
0xf52d00,
0xfd8600,
0xf74600,
0xf31500,
0xfc7600,
0x4ff,
0x23ff,
0x29ff,
0x613e9e,
0xf63900,
0x2aff,
0x43ff,
0xfb7100,
0xf95e00,
0xf74d00,
0xfe8c00,
0xf20800,
0xf31d00,
0xfb7d00,
0x41ff,
0x5bff,
0x5c42a3,
0x664c99,
0x11ff,
0xfb7200,
0xf20a00,
0xfc6e00,
0xf31700,
0xfb7f00,
0x6ff,
0x56ff,
0x5a6aa5,
0x5a3ba5,
0x4fff,
0xfb7600,
0xfa7600,
0xff9300,
0xfc7d00,
0x1cff,
0x5a76a5,
0x5a5da5,
0xfb6f00,
0xf52c00,
0xfd8a00,
0xf96b00,
0x3aff,
0x50ff,
0xfb7b00,
0xfd8b00,
0x5a75a5,
0x65559a,
0x5b3aa4,
0x4dff,
0x7f5080,
0xfff,
0x85547a,
0x5a55a5,
0xaff,
0x5a3da5,
0x5b51a4,
0x5a68a5,
0x5a73a5,
0x7ff,
0x2eff,
0x15ff,
0x5c70a3,
0x5ff,
0x65499a,
0xeff,
0x3bff,
0x2dff,
0x5e3ca1,
0x4cff,
0x9d6462,
0xbff,
0x47ff,
0x1dff,
0x5a6da5,
0x2cff,
0x5b46a4,
0x14ff,
0x613ea0,
0x31ff,
0x1bff
};

void uart_console_putchar(unsigned char ch)
{
  write_serial(ch);
}  

void hid_init(void)
{
  int i;
  unsigned char *fb_ptr = (unsigned char *)hid_fb_ptr;
  for (i = 0; i < 255; i++)
    hid_plt_ptr[i] = def_palette[i];

  for (i = 0; i < 255; i++)
    memset(fb_ptr+i*ghlimit, i, ghlimit);
  
  for (i = 0; i < gvlimit; i++)
    {
      fb_ptr[i*ghlimit + i] = 3;
    }
  
  for (i = 0; i < gvlimit; i++)
    {
      int j;
      for (j = 0; j < ghlimit; j += 100)
        {
        fb_ptr[i*ghlimit + j] = 1;
        }
      fb_ptr[(i+1)*ghlimit - 1] = 1;
    }

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
  hid_reg_ptr[LOWRISC_REGS_HPIXSTART ] = xpixoff;
  hid_reg_ptr[LOWRISC_REGS_HPIXSTOP ] = xpixels + xpixoff;
  hid_reg_ptr[LOWRISC_REGS_HDIV ] = 1;
  hid_reg_ptr[LOWRISC_REGS_HPIX ] = 5;
  hid_reg_ptr[LOWRISC_REGS_VPIX ] = 11; // squashed vertical display uses 10
  hid_reg_ptr[LOWRISC_REGS_GHLIMIT] = ghwords;
  
#ifdef BIGROM
  draw_logo(ghwords);
#endif
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
