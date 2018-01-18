// See LICENSE.SiFive for license details.

module SimDTM(
  input clk,
  input reset,

  output        debug_req_valid,
  input         debug_req_ready,
  output [ 6:0] debug_req_bits_addr,
  output [ 1:0] debug_req_bits_op,
  output [31:0] debug_req_bits_data,

  input         debug_resp_valid,
  output        debug_resp_ready,
  input  [ 1:0] debug_resp_bits_resp,
  input  [31:0] debug_resp_bits_data,

  output [31:0] exit
);

  wire [10:0] io_jtag_mfr_id = 11'h2AA;

  wire  CAPTURE2;
  wire  DRCK2;
  wire  RESET2;
  wire  RUNTEST2;
  wire  SEL2;
  wire  SHIFT2;
  wire  TCK2;
  wire  TDI2;
  wire  TMS2;
  wire  UPDATE2;

// BSCANE2: Boundary-Scan User Instruction
//          Artix-7
// Xilinx HDL Language Template, version 2015.4

BSCANE2 #(
  .JTAG_CHAIN(2)  // Value for USER command.
)
BSCANE2_inst1 (
  .CAPTURE(CAPTURE2), // 1-bit output: CAPTURE output from TAP controller.
  .DRCK(DRCK2),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                     // SHIFT are asserted.

  .RESET(RESET2),     // 1-bit output: Reset output for TAP controller.
  .RUNTEST(RUNTEST2), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
  .SEL(SEL2),         // 1-bit output: USER instruction active output.
  .SHIFT(SHIFT2),     // 1-bit output: SHIFT output from TAP controller.
  .TCK(TCK2),         // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
  .TDI(TDI2),         // 1-bit output: Test Data Input (TDI) output from TAP controller.
  .TMS(TMS2),         // 1-bit output: Test Mode Select output. Fabric connection to TAP.
  .UPDATE(UPDATE2),   // 1-bit output: UPDATE output from TAP controller
  .TDO(TDI2)          // 1-bit input: Test Data Output (TDO) input for USER function.
);
   
  DebugTransportModuleJTAG dtm (
    .clock(TCK2),
    .reset(RESET2),
    .io_dmi_req_ready(debug_req_ready),
    .io_dmi_req_valid(debug_req_valid),
    .io_dmi_req_bits_addr(debug_req_bits_addr),
    .io_dmi_req_bits_data(debug_req_bits_data),
    .io_dmi_req_bits_op(debug_req_bits_op),
    .io_dmi_resp_ready(debug_resp_ready),
    .io_dmi_resp_valid(debug_resp_valid),
    .io_dmi_resp_bits_data(debug_resp_bits_data),
    .io_dmi_resp_bits_resp(debug_resp_bits_resp),
    .io_jtag_TMS(),
    .io_jtag_TDI(),
    .io_jtag_TDO_data(),
    .io_jtag_TDO_driven(),
    .io_jtag_reset(RESET2),
    .io_jtag_mfr_id(io_jtag_mfr_id),
    .io_fsmReset()
  );

endmodule
