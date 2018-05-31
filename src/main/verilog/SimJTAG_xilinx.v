// See LICENSE.SiFive for license details.

module SimJTAG #(
                 parameter TICK_DELAY = 50
                 )(

                   input         clock,
                   input         reset,
                   
                   input         enable,
                   input         init_done,

                   output        jtag_TCK,
                   output        jtag_TMS,
                   output        jtag_TDI,
                   output        jtag_TRSTn,
 
                   input         jtag_TDO_data,
                   input         jtag_TDO_driven,
                          
                   output [31:0] exit
                   );

   wire CAPTURE, DRCK, RESET, RUNTEST, SEL, SHIFT, TCK, TDI, TMS, UPDATE, TDO;

   /* This block is just used to feed the JTAG clock into the parts of Rocket that need it */
      
   BSCANE2 #(
      .JTAG_CHAIN(2)  // Value for USER command.
   )
   BSCANE2_inst1 (
      .CAPTURE(CAPTURE), // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DRCK),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                         // SHIFT are asserted.

      .RESET(RESET),     // 1-bit output: Reset output for TAP controller.
      .RUNTEST(RUNTEST), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(SEL),         // 1-bit output: USER instruction active output.
      .SHIFT(SHIFT),     // 1-bit output: SHIFT output from TAP controller.
      .TCK(jtag_TCK),         // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(jtag_TDI),         // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(jtag_TMS),         // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(UPDATE),   // 1-bit output: UPDATE output from TAP controller
      .TDO(jtag_TDO_data)          // 1-bit input: Test Data Output (TDO) input for USER function.
   );

assign jtag_TRSTn = ~RESET;
assign exit = 32'b0;

endmodule
