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

static int addr_int = 0;

void hid_console_putchar(unsigned char ch)
{
  enum {lines=30};
  int blank = ' '|0xFF80;
  uint16_t *hid_vga_ptr = 1280 + (uint16_t *)hid_fb_ptr;
  switch(ch)
    {
    case 8: case 127: if (addr_int & 127) hid_vga_ptr[--addr_int] = blank; break;
    case 13: addr_int = addr_int & -128; break;
    case 10:
      {
        int lmt = (addr_int|127)+1; while (addr_int < lmt) hid_vga_ptr[(addr_int++)] = blank;
        break;
      }
    default: hid_vga_ptr[addr_int++] = ch|0x1C00;
    }
  if (addr_int >= lines*128)
    {
      // this is where we scroll
      for (addr_int = 0; addr_int < LOWRISC_MEM; addr_int++)
        if (addr_int < (lines-1)*128)
          hid_vga_ptr[addr_int] = hid_vga_ptr[addr_int+128];
        else
          hid_vga_ptr[addr_int] = blank;
      addr_int = (lines-1)*128;
    }
  hid_vga_ptr[LOWRISC_REGS+LOWRISC_REGS_XCUR] = addr_int & 127;
  hid_vga_ptr[LOWRISC_REGS+LOWRISC_REGS_YCUR] = (addr_int >> 7) + 10;
}

void uart_console_putchar(unsigned char ch)
{
  write_serial(ch);
}  


void hid_init(uint32_t sw)
{
  int i;
  if (sw&16)
    {
      unsigned char *fb_ptr = (unsigned char *)hid_fb_ptr;
      for (i = 0; i < 512; i++)
        {
          hid_plt_ptr[i] = rand32();
        }

      for (i = 0; i < 16384; i++)
        {
          fb_ptr[i] = rand32();
        }

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
      hid_reg_ptr[LOWRISC_REGS_MODE] = 0x77;
      hid_reg_ptr[LOWRISC_REGS_HPIX ] = 5;
      hid_reg_ptr[LOWRISC_REGS_VPIX ] = 7;
    }
  else
    {
      for (i = ' '; i <= '~'; i++)
        {
          int j;
          uint64_t tmp[2];
          char *zptr = zifu + (i - ' ') * 8;
          memset(tmp, 0, sizeof(tmp));
          for (j = 0; j < 8; j++)
            {
              tmp[j/4] |= ((0xFC & *zptr++) >> 1) << (j&3)*8;
            }
          for (j = 0; j < 2; j++)
            hid_plt_ptr[2*i+j] = tmp[j];
        }

      hid_reg_ptr[LOWRISC_REGS_MODE] = 0x00;
      hid_reg_ptr[LOWRISC_REGS_HPIX ] = 6;
      hid_reg_ptr[LOWRISC_REGS_VPIX ] = 7;

#if 0
      for (i = 10; i < 40; i++) // if (i&1)
        {
          int j, colour = 0xBB00;
          uint16_t *fb_ptr = (uint16_t *)hid_fb_ptr;
          switch(i)
            {
            case 11: colour = 0xBB00; break;
            case 13: colour = 0xFF00; break;
            case 15: colour = 0xE000; break;
            case 17: colour = 0x1C00; break;
            case 19: colour = 0x0380; break;
            case 21: colour = 0xFC00; break;
            case 23: colour = 0x1F80; break;
            case 25: colour = 0xE380; break;
            case 27: colour = 0x7000; break;
            case 29: colour = 0x0E00; break;
            case 31: colour = 0x5500; break;
            case 33: colour = 0xAA00; break;
            case 35: colour = 0x3300; break;
            case 37: colour = 0x6600; break;
            case 39: colour = 0x7700; break;
            default: colour = 0xFF80; break;
            }
          for (j = ' '; j <= '~'; j++)
            {
              fb_ptr[i*128+j-' '] = 0xFF80 | j;
            }
          while (j < 128+' ')
            {
              fb_ptr[i*128+j-' '] = colour | '*';
              ++j;
            }
        }
#else
      for (char *ptr = "Hello, LowRISC"; *ptr; ptr++)
        hid_console_putchar(*ptr);
#endif
    }
  hid_reg_ptr[LOWRISC_REGS_CURSV] = 0;
  hid_reg_ptr[LOWRISC_REGS_XCUR] = 0;
  hid_reg_ptr[LOWRISC_REGS_YCUR] = 0;
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
  hid_console_putchar(data);
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

#ifdef BIGROM
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
#endif
