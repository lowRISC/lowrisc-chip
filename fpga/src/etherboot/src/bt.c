#include <stdio.h>
#include "ariane.h"
#include "hid.h"

static uint64_t old_status1, old_status2, old_status3;

void bt_main(int sw)
{
  int i, j;
  old_status1 = -1;
  old_status2 = -1;
  bt_base[0x800 + 0x400] = 2;
  for (i = 1000000; i--; )
    old_status3 += i;
  bt_base[0x800 + 0x400] = 1302;
  for (i = 0; i < 3; i++)
    {
      for (j = 1000000; j--; )
        old_status3 += j;
      bt_base[0x800 + 0] = '$';
    }
  while (1)
    {
      uint64_t status1 = bt_base[0];
      uint64_t status2 = bt_base[0x400];
      if ((status1 != old_status1) ||(status2 != old_status2))
        {
          printf("Status1 = %lX, Status2 = %lX\n", status1, status2);
          old_status1 = status1;
          old_status2 = status2;
        }
    }
}
