// Copyright 2019 janhoogerbrugge
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Jan Hooger Brugge
// Date: 11.03.2019
// Description: Ariane cache performance tester
// Modified for bare-metal use by Jonathan Kimmitt (for the LowRISC team)

#include <stdio.h>
#include <stdlib.h>

#define read_csr(reg) ({ unsigned long __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

void sweep(int stride)
{
  long instret_start = 0, cycle_start = 0;
  int max_j = 4 * 1024;
  int working_set = max_j * stride;
  char *buffer = (char *)0x80000000;

  for (int i = 0; i < 10; i++)
  {
    if (i == 1)
    {
      instret_start = read_csr(instret);
      cycle_start = read_csr(cycle);
    }

    for (int j = 0; j < max_j; j += 4)
    {
      buffer[(j + 0) * stride] = 0;
      buffer[(j + 1) * stride] = 0;
      buffer[(j + 2) * stride] = 0;
      buffer[(j + 3) * stride] = 0;
    }
  }

  long instrets = read_csr(instret) - instret_start;
  long cycles = read_csr(cycle) - cycle_start;
  long ratio_3fig = cycles * 1000 / instrets;
  long ratio_hi = ratio_3fig / 1000;
  long ratio_lo = ratio_3fig % 1000;

  printf("working_set = %dKB, %ld instructions, %ld cycles, CPI = %ld.%ld\n", 
         working_set / 1024, instrets, cycles, ratio_hi, ratio_lo);
}

int cache_main(int argc, char **argv)
{
  for (;;)
    {
      sweep(0);
      sweep(1);
      sweep(2);
      sweep(4);
      sweep(8);
      sweep(16);
    }

  return 0;
}
