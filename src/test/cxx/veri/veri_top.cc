// See LICENSE for license details.

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vchip_top.h"
#include "globals.h"
#include "dpi_ram_behav.h"
#include "dpi_host_behav.h"
#include <string>
#include <vector>
#include <iostream>

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

  vector<string> args(argv + 1, argv + argc);
  for(vector<string>::iterator it = args.begin(); it != args.end(); ++it) {
    if(*it == "+vcd")
      vcd_enable = true;
    else if(it->find("+load=") == 0) {
      string filename = it->substr(strlen("+load="));
      if(!memory_controller->load_mem(filename)) {
        std::cout << "fail to load memory file " << filename << endl;
        return 0;
      }
    }
    else if(it->find("+max-cycles=") == 0) {
      max_time = 10 * strtoul(it->substr(strlen("+max-cycles=")).c_str(), NULL, 10);
    }
    else if(it->find("+vcd_name=") == 0) {
      vcd_name = it->substr(strlen("+vcd_name="));
    }
  }

  top = new Vchip_top;
  top->rst_top = 1;

  // VCD dump
  VerilatedVcdC* vcd = new VerilatedVcdC;
  if(vcd_enable) {
    Verilated::traceEverOn(true);
    top->trace(vcd, 99);
    vcd->open(vcd_name.c_str());
  }
  
  while(!Verilated::gotFinish() && (!exit_code || exit_delay > 1) &&
        (max_time == 0 || main_time < max_time) &&
        (exit_delay != 1)
        ) {
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
    if(vcd_enable) vcd->dump(main_time);       // do the dump

    if(main_time < 140)
      main_time++;
    else
      main_time += 5;

    if((main_time % 10) == 0 && exit_delay > 1)
      exit_delay--;             // postponed delay to allow VCD recording
  }

  top->final();
  if(vcd_enable) vcd->close();

  delete top;
  memory_model_close();

  return exit_code;
}
