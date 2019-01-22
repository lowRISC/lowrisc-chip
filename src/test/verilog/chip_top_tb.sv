// See LICENSE for license details.
`timescale 1ns/1ps

`include "consts.vh"
`include "config.vh"
`define RANDOMIZE_MEM_INIT
`define RANDOMIZE_REG_INIT

module tb;

   logic clk, rst;

   chip_top
   DUT
     (
      .*,
      .clk_p        ( clk       ),
      .clk_n        ( !clk      ),
      .rst_top      ( !rst      )         // NEXYS4's cpu_reset is active low
      );

   initial begin
      rst = 1;
      #130;
      rst = 0;
   end

   initial begin
      clk = 0;
      forever clk = #2.5 !clk;
   end // initial begin

   // DDRAM3
   wire [31:0]  ddr_dq;
   wire [3:0]   ddr_dqs_n;
   wire [3:0]   ddr_dqs_p;
   logic [14:0] ddr_addr;
   logic [2:0]  ddr_ba;
   logic        ddr_ras_n;
   logic        ddr_cas_n;
   logic        ddr_we_n;
   logic        ddr_reset_n;
   logic        ddr_ck_p;
   logic        ddr_ck_n;
   logic        ddr_cke;
   logic        ddr_cs_n;
   wire [3:0]   ddr_dm;
   logic        ddr_odt;

   // behavioural DDR3 RAM
   genvar       i;
   generate
      for (i = 0; i < 1; i = i + 1) begin: gen_mem
         ddr3_model u_comp_ddr3
               (
                .rst_n   ( ddr_reset_n         ),
                .ck      ( ddr_ck_p            ),
                .ck_n    ( ddr_ck_n            ),
                .cke     ( ddr_cke             ),
                .cs_n    ( ddr_cs_n            ),
                .ras_n   ( ddr_ras_n           ),
                .cas_n   ( ddr_cas_n           ),
                .we_n    ( ddr_we_n            ),
                .dm_tdqs ( ddr_dm[2*i +: 2]    ),
                .ba      ( ddr_ba              ),
                .addr    ( ddr_addr            ),
                .dq      ( ddr_dq[16*i +:16]   ),
                .dqs     ( ddr_dqs_p[2*i +: 2] ),
                .dqs_n   ( ddr_dqs_n[2*i +: 2] ),
                .tdqs_n  (                     ),
                .odt     ( ddr_odt             )
                );
      end
   endgenerate

   wire         rxd;
   wire         txd;
   wire         rts;
   wire         cts;

   assign rxd = 'b1;
   assign cts = 'b1;

reg u_trans;
reg [15:0] u_baud;
wire received, recv_err, is_recv, is_trans, u_tx, u_rx;
wire [7:0] u_rx_byte;
reg  [7:0] u_tx_byte;

   assign u_trans = received;
   assign u_tx_byte = u_rx_byte;
   assign u_baud = 16'd52;
   assign u_rx = txd;
   
uart i_uart(
    .clk(clk), // The master clock for this module
    .rst(rst), // Synchronous reset.
    .rx(u_rx), // Incoming serial line
    .tx(u_tx), // Outgoing serial line
    .transmit(u_trans), // Signal to transmit
    .tx_byte(u_tx_byte), // Byte to transmit
    .received(received), // Indicated that a byte has been received.
    .rx_byte(u_rx_byte), // Byte received
    .is_receiving(is_recv), // Low when receive line is idle.
    .is_transmitting(is_trans), // Low when transmit line is idle.
    .recv_error(recv_err), // Indicates error in receiving packet.
    .baud(u_baud),
    .recv_ack(received)
    );

   // 4-bit full SD interface
   wire         sd_sclk;
   wire         sd_detect = 1'b0; // Simulate SD-card always there
   wire [3:0]   sd_dat_to_host;
   wire         sd_cmd_to_host;
   wire         sd_reset, oeCmd, oeDat;
   wand [3:0]   sd_dat = oeDat ? sd_dat_to_host : 4'b1111;
   wand         sd_cmd = oeCmd ? sd_cmd_to_host : 4'b1;

sd_verilator_model sdflash1 (
             .sdClk(sd_sclk),
             .cmd(sd_cmd),
             .cmdOut(sd_cmd_to_host),
             .dat(sd_dat),
             .datOut(sd_dat_to_host),
             .oeCmd(oeCmd),
             .oeDat(oeDat)
);

   // LED and DIP switch
   wire [7:0]   o_led;
   wire [7:0]   i_dip;

   assign i_dip = 16'h0;

   // push button array
   wire         GPIO_SW_C;
   wire         GPIO_SW_W;
   wire         GPIO_SW_E;
   wire         GPIO_SW_N;
   wire         GPIO_SW_S;

   assign GPIO_SW_C = 'b1;
   assign GPIO_SW_W = 'b1;
   assign GPIO_SW_E = 'b1;
   assign GPIO_SW_N = 'b1;
   assign GPIO_SW_S = 'b1;

   //keyboard
   wire         PS2_CLK;
   wire         PS2_DATA;

   assign PS2_CLK = 'bz;
   assign PS2_DATA = 'bz;

  // display
   wire        VGA_HS_O;
   wire        VGA_VS_O;
   wire [3:0]  VGA_RED_O;
   wire [3:0]  VGA_BLUE_O;
   wire [3:0]  VGA_GREEN_O;

   // handle all run-time arguments
   string     memfile = "";
   string     vcd_name = "";
   longint    unsigned max_cycle = 0;
   longint    unsigned cycle_cnt = 0;

   initial begin
      $value$plusargs("max-cycles=%d", max_cycle);
   end // initial begin

   // vcd
   initial begin
//      if($test$plusargs("vcd"))
        vcd_name = "test.vcd";

      $value$plusargs("vcd_name=%s", vcd_name);

      if(vcd_name != "") begin
         $dumpfile(vcd_name);
         $dumpvars(0, DUT);
         $dumpon;
      end
   end // initial begin

   always @(posedge clk) begin
      cycle_cnt = cycle_cnt + 1;
      if(max_cycle != 0 && max_cycle == cycle_cnt)
        $fatal(0, "maximal cycle of %d is reached...", cycle_cnt);
   end

   /*
    * Ethernet: 1000BASE-T RGMII
    */
   wire        phy_rx_clk;
   wire [3:0]  phy_rxd;
   wire        phy_rx_ctl;
   wire        phy_tx_clk;
   wire [3:0]  phy_txd;
   wire        phy_tx_ctl;
   wire        phy_reset_n;
   wire        phy_int_n;
   wire        phy_pme_n;
   wire        phy_mdio, phy_mdc;
   
   assign phy_int_n = 1'b1;
   assign phy_pme_n = 1'b1;
   assign phy_rxd = phy_txd;
   assign phy_rx_clk = phy_tx_clk;
   assign phy_rx_ctl = phy_tx_ctl;

   // JTAG
   reg         tck, tms, tdi, trst_n;
   wire        tdo;    

   initial
     begin
       tck = 1'b0;
       tms = 1'b0;
       tdi = 1'b0;
       trst_n = 1'b0;
       #50; 
       tck = 1'b1;
       #50; 
       tck = 1'b0;
       #50; 
       tck = 1'b1;
       #50; 
       tck = 1'b0;
       trst_n = 1'b1;
     end
   
endmodule // tb
