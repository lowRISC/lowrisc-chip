#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vchip_top.h"
#include "dpi_ram_behav.h"
#include <string>
#include <vector>
#include <iostream>

using std::string;
using std::vector;

MemoryController *memory_controller;
AXIMemWriter* axi_mem_writer;
AXIMemReader *axi_mem_reader;
Vchip_top *top;

vluint64_t main_time = 0;

double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  memory_controller = new MemoryController(4);
  axi_mem_writer = new AXIMemWriter;
  axi_mem_reader = new AXIMemReader;

  // handle arguements
  bool vcd_enable = false;
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
  }

  top = new Vchip_top;
  top->rst_top = 1;

  // VCD dump
  VerilatedVcdC* vcd = new VerilatedVcdC;
  if(vcd_enable) {
    Verilated::traceEverOn(true);
    top->trace(vcd, 99);
    vcd->open("verilated.vcd");
  }
  
  while(!Verilated::gotFinish()) {
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
    memory_controller->step();
    if(vcd_enable) vcd->dump(main_time);       // do the dump

    if(main_time < 140)
      main_time++;
    else
      main_time += 5;
  }

  top->final();
  if(vcd_enable) vcd->close();

  delete top;
  delete memory_controller;
  delete axi_mem_writer;
  delete axi_mem_reader;

  return 0;
}
