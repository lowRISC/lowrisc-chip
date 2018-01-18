// $Header: /devl/xcs/repo/env/Databases/CAEInterfaces/verunilibs/data/glbl.v,v 1.14 2010/10/28 20:44:00 fphillip Exp $
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl (   // LED and DIP switch
 input        tms_pad_i, // JTAG test mode select pad
input         tck_pad_i, // JTAG test clock pad
input         trstn_pad_i, // JTAG test reset pad
input         tdi_pad_i, // JTAG test data input pad
output        tdo_pad_o, // JTAG test data output pad
output        tdo_padoe_o, // Output enable for JTAG test data output pad
output [5:0]  latched_jtag_ir,                
 output [7:0] o_led,
 input        clk_p,
 input        rst_top
  );

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
  
// TAP states
wire  test_logic_reset_o;
wire  run_test_idle_o;
wire  shift_dr_o;
wire  pause_dr_o;
wire  update_dr_o;
wire  capture_dr_o;

// Select signals for boundary scan or mbist
wire  extest_select_o;
wire  sample_preload_select_o;
wire  user1_select_o;
wire  user2_select_o;
wire  user3_select_o;
wire  user4_select_o;

// TDO signal that is connected to TDI of sub-modules.
wire  tdi_o;

// TDI signals from sub-modules
wire   debug_tdo_i;    // from debug module
wire   bs_chain_tdo_i; // from Boundary Scan Chain
wire   user1_tdo_i;    // from BSCANE2 Chain
wire   user2_tdo_i;    // from BSCANE2 Chain
wire   user3_tdo_i;    // from BSCANE2 Chain
wire   user4_tdo_i;    // from BSCANE2 Chain

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TCK_GLBL = tck_pad_i;
    wire JTAG_TDI_GLBL = tdi_pad_i;
    wire JTAG_TMS_GLBL = tms_pad_i;
    wire JTAG_TRST_GLBL = !trstn_pad_i;

    wire  JTAG_CAPTURE_GLBL = capture_dr_o;
    wire  JTAG_RESET_GLBL = test_logic_reset_o;
    wire  JTAG_SHIFT_GLBL = shift_dr_o;
    wire  JTAG_UPDATE_GLBL = update_dr_o;
    wire  JTAG_RUNTEST_GLBL = run_test_idle_o;

    wire   JTAG_SEL1_GLBL = user1_select_o;
    wire   JTAG_SEL2_GLBL = user2_select_o;
    wire   JTAG_SEL3_GLBL = user3_select_o;
    wire   JTAG_SEL4_GLBL = user4_select_o;

    wire JTAG_TDO_GLBL;
    assign tdo_pad_o = JTAG_TDO_GLBL;
   
    bit JTAG_USER_TDO1_GLBL;
    bit JTAG_USER_TDO2_GLBL;
    bit JTAG_USER_TDO3_GLBL;
    bit JTAG_USER_TDO4_GLBL;

   assign user1_tdo_i = JTAG_USER_TDO1_GLBL;
   assign user2_tdo_i = JTAG_USER_TDO2_GLBL;
   assign user3_tdo_i = JTAG_USER_TDO3_GLBL;
   assign user4_tdo_i = JTAG_USER_TDO4_GLBL;
   
    assign GSR = GSR_int;
    assign GTS = GTS_int;
    assign PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	GTS_int = 1'b0;
    end

  JTAGDummy dummy1(
   // LED and DIP switch
  .o_led(o_led),
  .clk_p(clk_p),
  .rst_top(rst_top)
  );

`ifdef TAP1   
 tap_top tap1 (
                // JTAG pads
                .tms_pad_i(tms_pad_i), 
                .tck_pad_i(tck_pad_i), 
                .trstn_pad_i(trstn_pad_i), 
                .tdi_pad_i(tdi_pad_i), 
                .tdo_pad_o(tdo_pad_o), 
                .tdo_padoe_o(tdo_padoe_o),

                // TAP states
		.test_logic_reset_o(test_logic_reset_o),
		.run_test_idle_o(run_test_idle_o),
                .shift_dr_o(shift_dr_o),
                .pause_dr_o(pause_dr_o), 
                .update_dr_o(update_dr_o),
                .capture_dr_o(capture_dr_o),
                
                // Select signals for boundary scan or mbist
                .extest_select_o(extest_select_o), 
                .user1_select_o(user1_select_o), 
                .user2_select_o(user2_select_o), 
                .user3_select_o(user3_select_o), 
                .user4_select_o(user4_select_o), 
                .sample_preload_select_o(sample_preload_select_o),
                
                // TDO signal that is connected to TDI of sub-modules.
                .tdi_o(tdi_o), 
                
                // TDI signals from sub-modules
                .user1_tdo_i(user1_tdo_i),    // from BSCANE2 module
                .user2_tdo_i(user2_tdo_i),    // from BSCANE2 module
                .user3_tdo_i(user3_tdo_i),    // from BSCANE2 module
                .user4_tdo_i(user4_tdo_i),    // from BSCANE2 module
                .bs_chain_tdo_i(bs_chain_tdo_i), // from Boundary Scan Chain

                .latched_jtag_ir(latched_jtag_ir)
              );
`endif
   
endmodule
`endif
