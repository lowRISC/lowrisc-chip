module JtagTapController(
  input        clock,
  input        reset,
  input        io_jtag_TMS,
  input        io_jtag_TDI,
  output       io_jtag_TDO_data,
  output       io_jtag_TDO_driven,
  input        io_control_jtag_reset,
  output [4:0] io_output_instruction,
  output       io_output_reset,
  output       io_dataChainOut_shift,
  output       io_dataChainOut_data,
  output       io_dataChainOut_capture,
  output       io_dataChainOut_update,
  input        io_dataChainIn_data
);

wire  CAPTURE1;
wire  CAPTURE3;
wire  CAPTURE4;
wire  DRCK1;
wire  DRCK3;
wire  DRCK4;
wire  RESET1;
wire  RESET3;
wire  RESET4;
wire  RUNTEST1;
wire  RUNTEST3;
wire  RUNTEST4;
wire  SEL1;
wire  SEL3;
wire  SEL4;
wire  SHIFT1;
wire  SHIFT3;
wire  SHIFT4;
wire  TCK1;
wire  TCK3;
wire  TCK4;
wire  TDI1;
wire  TDI3;
wire  TDI4;
wire  TMS1;
wire  TMS3;
wire  TMS4;
wire  UPDATE1;
wire  UPDATE3;
wire  UPDATE4;

   // BSCANE2: Boundary-Scan User Instruction
   //          Artix-7
   // Xilinx HDL Language Template, version 2015.4

   BSCANE2 #(
      .JTAG_CHAIN(1)  // Value for USER command.
   )
   BSCANE2_inst1 (
      .CAPTURE(CAPTURE1), // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DRCK1),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                         // SHIFT are asserted.

      .RESET(RESET1),     // 1-bit output: Reset output for TAP controller.
      .RUNTEST(RUNTEST1), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(SEL1),         // 1-bit output: USER instruction active output.
      .SHIFT(SHIFT1),     // 1-bit output: SHIFT output from TAP controller.
      .TCK(TCK1),         // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(TDI1),         // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(TMS1),         // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(UPDATE1),   // 1-bit output: UPDATE output from TAP controller
      .TDO(io_dataChainIn_data)          // 1-bit input: Test Data Output (TDO) input for USER function.
   );


   // BSCANE2: Boundary-Scan User Instruction
   //          Artix-7
   // Xilinx HDL Language Template, version 2015.4

   BSCANE2 #(
      .JTAG_CHAIN(3)  // Value for USER command.
   )
   BSCANE2_inst3 (
      .CAPTURE(CAPTURE3), // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DRCK3),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                         // SHIFT are asserted.

      .RESET(RESET3),     // 1-bit output: Reset output for TAP controller.
      .RUNTEST(RUNTEST3), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(SEL3),         // 1-bit output: USER instruction active output.
      .SHIFT(SHIFT3),     // 1-bit output: SHIFT output from TAP controller.
      .TCK(TCK3),         // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(TDI3),         // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(TMS3),         // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(UPDATE3),   // 1-bit output: UPDATE output from TAP controller
      .TDO(io_dataChainIn_data)          // 1-bit input: Test Data Output (TDO) input for USER function.
   );


   // BSCANE2: Boundary-Scan User Instruction
   //          Artix-7
   // Xilinx HDL Language Template, version 2015.4

   BSCANE2 #(
      .JTAG_CHAIN(4)  // Value for USER command.
   )
   BSCANE2_inst4 (
      .CAPTURE(CAPTURE4), // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DRCK4),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                         // SHIFT are asserted.

      .RESET(RESET4),     // 1-bit output: Reset output for TAP controller.
      .RUNTEST(RUNTEST4), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(SEL4),         // 1-bit output: USER instruction active output.
      .SHIFT(SHIFT4),     // 1-bit output: SHIFT output from TAP controller.
      .TCK(TCK4),         // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(TDI4),         // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(TMS4),         // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(UPDATE4),   // 1-bit output: UPDATE output from TAP controller
      .TDO(io_dataChainIn_data)          // 1-bit input: Test Data Output (TDO) input for USER function.
   );

assign io_dataChainOut_data = SHIFT1 ? TDI1 : SHIFT3 ? TDI3 : SHIFT4 ? TDI4 : 1'b0;
assign io_jtag_TDO_driven = 1'b1;
assign io_output_instruction = SEL1 ? 5'h1 : SEL3 ? 5'h10 : SEL4 ? 5'h11 : 5'b0;
assign io_output_reset = RESET1|RESET3|RESET4;
assign io_dataChainOut_shift = SHIFT1|SHIFT3|SHIFT4;
assign io_jtag_TDO_data = io_dataChainOut_data;
assign io_dataChainOut_capture = CAPTURE1|CAPTURE3|CAPTURE4;
assign io_dataChainOut_update = UPDATE1|UPDATE3|UPDATE4;

endmodule
