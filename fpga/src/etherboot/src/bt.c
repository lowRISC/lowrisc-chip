#include <stdio.h>
#include "ariane.h"
#include "uart.h"
#include "hid.h"

#ifdef BIGROM
static uint64_t old_status1, old_status2, old_status3;

void bt_main(int sw)
{
  int i, j;
  old_status1 = -1;
  old_status2 = -1;
  init_uart(BTBase, 27); /* 115200 baud */
  while (1)
    {
      int ch = get_uart_byte(UARTBase);
      if (ch >= 0)
        {
          hid_send(ch);
          write_serial(BTBase, ch);
        }
      ch = get_uart_byte(BTBase);
      if (ch >= 0)
        {
          hid_send(ch);
        }
    }
  for (i = 1000000; i--; )
    old_status3 += i;
  for (i = 0; i < 3; i++)
    {
      for (j = 1000000; j--; )
        old_status3 += j;
      write_serial(BTBase, '$');
    }
  while (1)
    {
      uint64_t status1 = uart_line_status(BTBase);
      if (status1 != old_status1)
        {
          printf("Status1 = %lX\n", status1);
          old_status1 = status1;
        }
    }
}
#endif
