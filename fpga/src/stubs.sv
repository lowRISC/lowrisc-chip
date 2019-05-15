`default_nettype none

module clock_buffer_generic(input wire ing, output wire outg);

`ifdef FPGA
   
BUFH buf1(.I(ing), .O(outg));

`else

   assign outg = ing;
   
`endif
   
endmodule // clock_buffer_generic

module io_buffer_generic(inout wire inoutg, output wire outg, input wire ing, input wire ctrl);

`ifdef FPGA
   
   IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_inst (
      .O(outg),     // Buffer output
      .IO(inoutg),   // Buffer inout port (connect directly to top-level port)
      .I(ing),     // Buffer input
      .T(ctrl)      // 3-state enable input, high=input, low=output
   );

`else

   assign outg = inoutg;
   assign inoutg = ctrl ? 1'bz : ing;
   
`endif
   
endmodule // io_buffer_generic

module io_buffer_fast(inout wire inoutg, output wire outg, input wire ing, input wire ctrl);

`ifdef FPGA
   
   IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("FALSE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("LVTTL"), // Specify the I/O standard
      .SLEW("FAST") // Specify the output slew rate
   ) IOBUF_inst (
      .O(outg),     // Buffer output
      .IO(inoutg),   // Buffer inout port (connect directly to top-level port)
      .I(ing),     // Buffer input
      .T(ctrl)      // 3-state enable input, high=input, low=output
   );

`else

   assign outg = inoutg;
   assign inoutg = ctrl ? 1'bz : ing;
   
`endif
   
endmodule // io_buffer_fast

module oddr_buffer_generic(output wire outg, input wire ing);

`ifdef FPGA
   
  ODDR #(
    .DDR_CLK_EDGE("OPPOSITE_EDGE"),
    .INIT(1'b0),
    .IS_C_INVERTED(1'b0),
    .IS_D1_INVERTED(1'b0),
    .IS_D2_INVERTED(1'b0),
    .SRTYPE("SYNC")) 
    refclk_inst
       (.C(ing),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .Q(outg),
        .R(1'b0),
        .S( ));

`else

   assign outg = ing;
   
`endif
   
endmodule // oddr_buffer_generic

module bscan_generic #(
    parameter integer JTAG_CHAIN = 1
 )
(output wire CAPTURE, DRCK, RESET, RUNTEST, SEL, SHIFT, TCK, TDI, TMS, UPDATE, input wire TDO);

`ifdef FPGA
   
   BSCANE2 #(
      .JTAG_CHAIN(JTAG_CHAIN)  // Value for USER command.
   )
   BSCANE2_inst (
      .CAPTURE(CAPTURE), // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DRCK),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                         // SHIFT are asserted.
      .RESET(RESET),     // 1-bit output: Reset output for TAP controller.
      .RUNTEST(RUNTEST), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(SEL),         // 1-bit output: USER instruction active output.
      .SHIFT(SHIFT),     // 1-bit output: SHIFT output from TAP controller.
      .TCK(TCK),         // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(TDI),         // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(TMS),         // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(UPDATE),   // 1-bit output: UPDATE output from TAP controller
      .TDO(TDO)          // 1-bit input: Test Data Output (TDO) input for USER function.
   );

`else // !`ifdef FPGA

assign {CAPTURE, DRCK, RESET, RUNTEST, SEL, SHIFT, TCK, TDI, TMS, UPDATE} = 'b0;
   
`endif //  `ifdef FPGA

endmodule // bscan_generic
