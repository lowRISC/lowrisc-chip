// See LICENSE for license details.

#ifdef VERILATOR
#include <verilated.h>
#endif

#include "globals.h"
#include "dpi_host_behav.h"
#include <cstdlib>
#include <iostream>

void host_req (unsigned int id, unsigned long long data) {
  if(data & 1) {
    // test pass/fail
    if(data != 1)
      std::cerr << "Core " << id << " exit with error code " << (data >> 1) << std::endl;
    exit_code = (data >> 1);
    exit_delay = 1;
  } else {
    std::cerr << "Core " << id << " get unsolved tohost code " << std::hex << data << std::endl;
    exit_code = 1;
    exit_delay = 1;
  }
}

int check_exit() {
  if(exit_delay > 1) {
    exit_delay--;
    return -1;
  } else if(exit_delay == 1 || exit_code) {
    return exit_code;
  } else
    return -1;
}
