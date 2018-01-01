// See LICENSE.SiFive for license details.

module SimDTM(
  input clk,
  input reset,

  output reg      debug_req_valid,
  input         debug_req_ready,
  output reg [ 6:0] debug_req_bits_addr,
  output reg [ 1:0] debug_req_bits_op,
  output reg [31:0] debug_req_bits_data,

  input         debug_resp_valid,
  output reg       debug_resp_ready,
  input  [ 1:0] debug_resp_bits_resp,
  input  [31:0] debug_resp_bits_data,

  output [31:0] exit
);

assign exit = 32'b0;

    BSCANE2 #(
     .JTAG_CHAIN(1)  // Value for USER command. (INSTR=2)
  )
  BSCANE2_inst10 (
     .CAPTURE(dtmInfoChain_io_chainIn_capture), // 1-bit output: CAPTURE output from TAP controller.
     .DRCK(dtmInfoChain_clock),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                        // SHIFT are asserted.

     .RESET(dtmInfoChain_reset),     // 1-bit output: Reset output for TAP controller.
     .RUNTEST(io_jtag_RUNTEST10), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
     .SEL(JtagTapController_io_output_instructioneqh10),         // 1-bit output: USER instruction active output.
     .SHIFT(dtmInfoChain_io_chainIn_shift),     // 1-bit output: SHIFT output from TAP controller.
     .TCK(io_jtag_TCK10),         // 1-bit output: Test clk output. Fabric connection to TAP clk pin.
     .TDI(dtmInfoChain_io_chainIn_data),         // 1-bit output: Test Data Input (TDI) output from TAP controller.
     .TMS(io_jtag_TMS10),         // 1-bit output: Test Mode Select output. Fabric connection to TAP.
     .UPDATE(dtmInfoChain_io_chainIn_update),   // 1-bit output: UPDATE output from TAP controller
     .TDO(dtmInfoChain_io_chainOut_data)          // 1-bit input: Test Data Output (TDO) input for USER function.
  );

  logic [31:0] dtmreg;
  logic [40:0] dmireg;
  logic dmireset, 
  always @(posedge dtmInfoChain_clock)
    begin
        if (dtmInfoChain_io_chainIn_shift)
            begin
                dtmreg = {dmireg[39:0],dtmInfoChain_io_chainIn_data};
            end
        else if (dtmInfoChain_io_chainIn_capture)
            begin
                dtmreg = { 14'b0, dmihardreset, dmireset, 1'b0, 16'h5071};
            end
        else if (dtmInfoChain_io_chainIn_update)
            begin
                {dtmInfoChain_io_update_bits_addr,dtmInfoChain_io_update_bits_data,dtmInfoChain_io_update_bits_op} <= dtmreg;
                debug_req_valid <= 1'b1;               
            end
    end
 
 assign dtmInfoChain_io_chainOut_data = dmireg[31];
 
     BSCANE2 #(
     .JTAG_CHAIN(2)  // Value for USER command. (INSTR=3)
  )
  BSCANE2_inst11 (
     .CAPTURE(dmiAccessChain_io_chainIn_capture), // 1-bit output: CAPTURE output from TAP controller.
     .DRCK(dmiAccessChain_clock),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                        // SHIFT are asserted.

     .RESET(dmiAccessChain_reset),     // 1-bit output: Reset output for TAP controller.
     .RUNTEST(io_jtag_RUNTEST11), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
     .SEL(JtagTapController_io_output_instructioneqh11),         // 1-bit output: USER instruction active output.
     .SHIFT(dmiAccessChain_io_chainIn_shift),     // 1-bit output: SHIFT output from TAP controller.
     .TCK(io_jtag_TCK11),         // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
     .TDI(dmiAccessChain_io_chainIn_data),         // 1-bit output: Test Data Input (TDI) output from TAP controller.
     .TMS(io_jtag_TMS11),         // 1-bit output: Test Mode Select output. Fabric connection to TAP.
     .UPDATE(dmiAccessChain_io_chainIn_update),   // 1-bit output: UPDATE output from TAP controller
     .TDO(dmiAccessChain_io_chainOut_data)          // 1-bit input: Test Data Output (TDO) input for USER function.
  );

  always @(posedge dmiAccessChain_clock)
    begin
        if (debug_req_ready)
            debug_req_valid <= 1'b0;
        if (dmiAccessChain_io_chainIn_shift)
            begin
                dmireg = {dmireg[39:0],dmiAccessChain_io_chainIn_data};
            end
        else if (dmiAccessChain_io_chainIn_capture)
            begin
                if (debug_resp_valid)
                    begin
                    debug_resp_ready <= 1'b1;
                    dmireg[33:0] = {debug_resp_bits_data,debug_resp_bits_resp};
                    end
            end
        else if (dmiAccessChain_io_chainIn_update)
            begin
                {debug_req_bits_addr,debug_req_bits_data,debug_req_bits_op} <= dmireg;
                debug_req_valid <= 1'b1;               
            end
    end
 
 assign dmiAccessChain_io_chainOut_data = dmireg[40];
  
endmodule
