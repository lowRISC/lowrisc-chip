// See LICENSE for license details.

#ifdef VERILATOR_GCC
#include <verilated.h>
#endif

#include "globals.h"
#include "dpi_host_behav.h"
#include <cstdlib>
#include <iostream>

void host_req (unsigned int id, unsigned long long data) {
  if(data & 1) {
    // test pass/fail
    if(host_extract_payload(data) != 1)
      std::cerr << "Core " << id << " exit with error code " << (host_extract_payload(data) >> 1) << std::endl;
    
    exit_code = host_extract_payload(data) >> 1;
    exit_delay = 1;
  } else {
    std::cerr << "Core " << id << " get unsolved tohost code " << std::hex << data << std::endl;

    exit_code = 1;
    exit_delay = 1;
  }
}
