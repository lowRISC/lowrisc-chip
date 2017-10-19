// See LICENSE for license details.

#include <verilated.h>
#ifdef TRACE_VCD
 #include <verilated_vcd_c.h>
#endif
#include "Vchip_top.h"
#include "globals.h"
#include "dpi_ram_behav.h"
#include <string>
#include <vector>
#include <iostream>

//#include "GlipTcp.h"

using std::string;
using std::vector;

Vchip_top *top;
uint64_t max_time = 0;

double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  // initialize memory model
  memory_model_init();

  // handle arguements
  bool vcd_enable = false;
  string vcd_name = "verilated.vcd";
  bool wait_debug = false;

  vector<string> args(argv + 1, argv + argc);
  for(vector<string>::iterator it = args.begin(); it != args.end(); ++it) {
    if(*it == "+vcd")
      vcd_enable = true;
    else if(it->find("+load=") == 0) {
      string filename = it->substr(strlen("+load="));
      memory_controller->load_mem(filename);
    }
    else if(it->find("+max-cycles=") == 0) {
      max_time = 10 * strtoul(it->substr(strlen("+max-cycles=")).c_str(), NULL, 10);
    }
    else if(it->find("+vcd_name=") == 0) {
      vcd_name = it->substr(strlen("+vcd_name="));
    }
    else if(it->find("+waitdebug") == 0) {
      wait_debug = true;
    }
  }

  top = new Vchip_top;
  top->rst_top = 1;

  // VCD dump
#ifdef TRACE_VCD
  VerilatedVcdC* vcd = new VerilatedVcdC;
  if(vcd_enable) {
    Verilated::traceEverOn(true);
    top->trace(vcd, 99);
    vcd->open(vcd_name.c_str());
  }
#endif

  top->eval();
  
//  GlipTcp &glip = GlipTcp::instance();
  while(!Verilated::gotFinish() && (!exit_code || exit_delay > 1) &&
        (max_time == 0 || main_time < max_time) &&
        (exit_delay != 1)
        ) {
//    if (!glip.connected() && wait_debug) {
//      continue;
//    }
    if(main_time > 133) {
      top->rst_top = 0;
    }
    if((main_time % 10) == 0) { // 10ns clk
      top->clk_p = 1;
      top->clk_n = 0;
    }
    if((main_time % 10) == 5) {
      top->clk_p = 0;
      top->clk_n = 1;
    }

    top->eval();
    if((main_time % 10) == 0) memory_controller->step();
#ifdef TRACE_VCD
    if(vcd_enable) vcd->dump(main_time);       // do the dump
#endif

    if(main_time < 140)
      main_time++;
    else
      main_time += 5;

    if((main_time % 10) == 0 && exit_delay > 1)
      exit_delay--;             // postponed delay to allow VCD recording

    if((main_time % 10000000) == 0)
      std::cerr << "simulation has run for " << main_time/10 << " cycles..." << std::endl;
  }

  top->final();
#ifdef TRACE_VCD
  if(vcd_enable) vcd->close();
#endif

  delete top;
  memory_model_close();

  if(max_time == 0 || main_time < max_time)
    return exit_code;
  else
    return -1;                  // timeout
}
