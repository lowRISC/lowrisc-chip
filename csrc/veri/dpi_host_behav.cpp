// See LICENSE for license details.

#include <verilated.h>
#include "veri_top.h"
#include "dpi_host_behav.h"
#include <iostream>

void host_req (unsigned int id, unsigned long long data) {
  if(data & 1) {
    // test pass/fail
    if(host_extract_payload(data) != 1)
      std::cerr << "Core " << id << " exit with error code " << (host_extract_payload(data) >> 1) << std::endl;
    
    exit_code = host_extract_payload(data) >> 1;
    Verilated::gotFinish(true);
  } else {
    std::cerr << "Core " << id << " get unsolved tohost code " << std::hex << data << std::endl;
    exit_code = 1;
    Verilated::gotFinish(true);
  }
}
