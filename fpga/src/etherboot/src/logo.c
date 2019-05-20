#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <memory.h>
#include "hid.h"
#include "logo.h"

void draw_logo(int ghlimit)
{
  size_t i = 0;
  size_t j = 0;
  uint64_t cline = 0;

  size_t __ip = 0;
  size_t __il = image_width*image_height;
  const unsigned char *image_ptr = logo;

  while (__ip < __il)
    {
      unsigned int __l = *(image_ptr++);
      unsigned int cnt = __l & 127;
      do {
          uint64_t k = 0;
          k = *image_ptr;
          cline |= k << ((j&15)*4);
          if ((j&15)==15)
            {
              if ((j < ghlimit*16) && (i*ghlimit < 24576))
                hid_fb_ptr[i*ghlimit+((j-15)>>4)] = cline;
              cline = 0;
            }
          if (++j >= image_width)
            {
              j |= 15;
              while (j < ghlimit*16)
                {
                  if ((j&15)==15)
                    {
                      hid_fb_ptr[i*ghlimit+((j-15)>>4)] = cline;
                      cline = 0;
                    }
                  ++j;
                }
              j = 0;
              ++i;
            }
          __ip++;
          if (~__l & 128)
            image_ptr++;
        }
        while (--cnt);
        if (__l & 128)
          image_ptr++;
    }
  while (i*ghlimit < 24576)
    {
      for (j = 0; j < ghlimit; j++)
        hid_fb_ptr[i*ghlimit+j] = 0;
      ++i;
    }
  for (i = 0; i < sizeof(palette_logo2)/sizeof(*palette_logo2); i++)
    hid_reg_ptr[LOWRISC_REGS_PALETTE + i] = palette_logo2[i];
}
