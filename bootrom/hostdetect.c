
#include <stdint.h>

typedef __attribute__ ((__noreturn__)) void (*fptr_t)(void);

__attribute__ ((__noreturn__)) void hostdetect(void)
{
  register fptr_t ddr = (fptr_t)0x80000000;
  register fptr_t bram = (fptr_t)0x40000000;
  register char *config = (char *)0x10000;
  for (register int i = 128; i < 4096; i++)
    {
      register char ch = config[i] & 0x7f; 
      if (ch == '@')
        {
          register int j = i-1;
          while ((config[j] >= 'a' && config[j] <= 'z') || config[j] == '-')
            j--;
          if (++j < i)
            {
              if (config[j] == 'h')
                ddr();
            }
        }
    }
  bram();
}
