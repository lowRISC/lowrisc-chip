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

 // The following should be indicated but can be directly enabled
 // SIMULATION            : simulation
 // FPGA                  : FPGA implementation
 // ASIC                  : ASIC implementation

 // FPGA_FULL             : simulation/implement very ip of FPGA

 //----------- Detailed configuration -------------//
 `ifdef FPGA

  `ifndef ENABLE_DEBUG
   `define ADD_UART
  `endif
  `define ADD_UART_IO

  `define ADD_SPI
  `define ADD_SPI_IO

  `define ADD_BOOT_MEM

  `ifdef FPGA_FULL
   `define ADD_DDR
   `define ADD_DDR_IO
  `else
   `define ADD_DDR_SIM
   `define ADD_HOST_IF
  `endif

 `elsif SIMULATION

  `define ADD_DDR_SIM
  `define ADD_HOST_IF

 `endif

function int NUM_OF_IO_DEVICE();
   NUM_OF_IO_DEVICE = 0;

 `ifdef ENABLE_DEBUG
   // debug equiv UART
   NUM_OF_IO_DEVICE++;
 `elsif ADD_UART
   // actual UART
   NUM_OF_IO_DEVICE++;
 `endif

 `ifdef ADD_SPI
   // have a SPI (SD card)
   NUM_OF_IO_DEVICE++;
 `endif

endfunction

function int NUM_OF_MEM();
   // either hebavioural memory or DDR memory
   NUM_OF_MEM = 1;

 `ifdef ADD_BOOT_MEM
   // have a on-chip boot-ram
   NUM_OF_MEM++;
 `endif
endfunction


`endif
