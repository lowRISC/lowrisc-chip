// See LICENSE for license details.

//-------------------------------------------------
// Define the features in simulatio/fpga/asic
//-------------------------------------------------

`ifndef CHIP_CONFIG_VH
 `define CHIP_CONFIG_VH

// For some known cases
 `ifdef VERILATOR
  // when verilator is used for behavioural simulation
  `define SIMULATION
 `endif

 `ifdef VCS
  // when Synopsys VCS is used for behavioural simulation
  `define SIMULATION
 `endif

 `ifdef INCA
  // when Cadence NCSIM is used for behavioural simulation
  `define SIMULATION
 `endif

 `ifdef MODEL_TECH
  // when Mentor Graphic Modelsom is used for behavioural simulation
  `define SIMULATION
 `endif

 `ifdef XILINX_SIMULATOR
  // when Mentor Graphic Modelsom is used for behavioural simulation
  `define SIMULATION
  //`define FPGA_FULLSIM
 `endif

// decide the relationship
 `ifdef FPGA_FULLSIM
  `define FPGA
 `endif


// The following should be indicated but can be directly enabled
// SIMULATION            : simulation
// FPGA                  : FPGA implementation
// ASIC                  : ASIC implementation

// FPGA_FULLSIM          : simulation very ip of FPGA

`endif
