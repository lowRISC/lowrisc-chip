// See LICENSE for license details.

//-------------------------------------------------
// Define the features in simulatio/fpga/asic
//-------------------------------------------------

`ifndef CHIP_CONFIG_VH
 `define CHIP_CONFIG_VH

// whether this is for simulation
// Should be enabled by command line
// `define SIMULATION

// whether this is for FPGA
// Should be enabled by command line
// `define FPGA

// whether this is for ASIC
// Should be enabled by command line
// `define ASIC

// Whether to use PLL
// Require: FPGA
 `define USE_PLL

// Whether to use Xilinx UART IP
 `define USE_XIL_UART

`endif
