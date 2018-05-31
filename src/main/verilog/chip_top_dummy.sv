module chip_top_dummy( // @[:freechips.rocketchip.system.DefaultFPGAConfig.fir@257214.2]
  input   clk_p, // @[:freechips.rocketchip.system.DefaultFPGAConfig.fir@257215.4]
  input   clk_n, // @[:freechips.rocketchip.system.DefaultFPGAConfig.fir@257215.4]
  input   rst_top, // @[:freechips.rocketchip.system.DefaultFPGAConfig.fir@257216.4]
  output GPIO_LED_0_LS
);

   logic clock, clk_locked, clk_locked_wiz;

TestHarness dut( // @[:freechips.rocketchip.system.DefaultFPGAConfig.fir@257214.2]
  .clock(clock), // @[:freechips.rocketchip.system.DefaultFPGAConfig.fir@257215.4]
  .reset(~clk_locked), // @[:freechips.rocketchip.system.DefaultFPGAConfig.fir@257216.4]
  .io_success(GPIO_LED_0_LS) // @[:freechips.rocketchip.system.DefaultFPGAConfig.fir@257217.4]
);

  clk_wiz_dummy clk_gen
     (
   // Clock in ports
    .clk_in1_p(clk_p),    // input clk_in1_p
    .clk_in1_n(clk_n),    // input clk_in1_n
    // Clock out ports
    .clk_out1(clock),     // output clk_out1
    // Status and control signals
    .resetn(~rst_top), // input resetn
    .locked(clk_locked_wiz));      // output locked

   assign clk_locked = clk_locked_wiz & ~rst_top;

endmodule
