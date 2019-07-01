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
  size_t __ip = 0;
  size_t __il = image_width*image_height;
  const unsigned char *image_ptr = logo;
  unsigned char *fb_ptr = (unsigned char *)hid_fb_ptr;
  size_t hlimit = ghlimit*8;
  while (__ip < __il)
    {
      unsigned int __l = *(image_ptr++);
      unsigned int cnt = __l & 127;
      do {
          fb_ptr[i*hlimit + j] = *image_ptr;
          if (++j >= image_width)
            {
	      if (j < hlimit)
		memset(fb_ptr+i*hlimit + j, 0, hlimit - j);
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
  for (i = 0; i < sizeof(palette_logo2)/sizeof(*palette_logo2); i++)
    hid_reg_ptr[LOWRISC_REGS_PALETTE + i] = ((palette_logo2[i] & 0xFF) << 16) | ((palette_logo2[i] & 0xFF00)) | ((palette_logo2[i] & 0xFF0000) >> 16);
}
