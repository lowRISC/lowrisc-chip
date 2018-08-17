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
`ifdef FPGA_FULL
 `ifdef NEXYS4_COMMON
      .rst_top      ( !rst      )         // NEXYS4's cpu_reset is active low
 `else
      .rst_top      ( rst       )
 `endif
`else
      .rst_top      ( rst       )
`endif
      );

   initial begin
      rst = 1;
      #10000;
      rst = 0;
   end

  `ifdef KC705
   logic i_erx_clk, i_etx_clk;
   initial
     begin
        clk = 0;
        i_erx_clk = 0;
        i_etx_clk = 0;
     end
   
   always clk = #2.5 !clk;
   always i_erx_clk = #20.001 !i_erx_clk;
   always i_etx_clk = #19.999 !i_etx_clk;

  `else
   initial
     begin
        clk = 0;
        forever clk = #5 !clk;
     end // initial begin
  `endif

`ifdef ADD_PHY_DDR
 `ifdef KC705

   // DDRAM3
   wire [63:0]  ddr_dq;
   wire [7:0]   ddr_dqs_n;
   wire [7:0]   ddr_dqs_p;
   logic [13:0] ddr_addr;
   logic [2:0]  ddr_ba;
   logic        ddr_ras_n;
   logic        ddr_cas_n;
   logic        ddr_we_n;
   logic        ddr_reset_n;
   logic        ddr_ck_p;
   logic        ddr_ck_n;
   logic        ddr_cke;
   logic        ddr_cs_n;
   wire [7:0]   ddr_dm;
   logic        ddr_odt;

   // behavioural DDR3 RAM
   genvar       i;
   generate
      for (i = 0; i < 8; i = i + 1) begin: gen_mem
         ddr3_model u_comp_ddr3
               (
                .rst_n   ( ddr_reset_n     ),
                .ck      ( ddr_ck_p        ),
                .ck_n    ( ddr_ck_n        ),
                .cke     ( ddr_cke         ),
                .cs_n    ( ddr_cs_n        ),
                .ras_n   ( ddr_ras_n       ),
                .cas_n   ( ddr_cas_n       ),
                .we_n    ( ddr_we_n        ),
                .dm_tdqs ( ddr_dm[i]       ),
                .ba      ( ddr_ba          ),
                .addr    ( ddr_addr        ),
                .dq      ( ddr_dq[8*i +:8] ),
                .dqs     ( ddr_dqs_p[i]    ),
                .dqs_n   ( ddr_dqs_n[i]    ),
                .tdqs_n  (                 ),
                .odt     ( ddr_odt         )
                );
      end
   endgenerate

 `elsif NEXYS4_VIDEO

   // DDRAM3
   wire [15:0]  ddr_dq;
   wire [1:0]   ddr_dqs_n;
   wire [1:0]   ddr_dqs_p;
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
   wire [1:0]   ddr_dm;
   logic        ddr_odt;
   
   // behavioural DDR3 RAM
   genvar       i;
   generate
      for (i = 0; i < 2; i = i + 1) begin: gen_mem
         ddr3_model u_comp_ddr3
               (
                .rst_n   ( ddr_reset_n     ),
                .ck      ( ddr_ck_p        ),
                .ck_n    ( ddr_ck_n        ),
                .cke     ( ddr_cke         ),
                .cs_n    ( ddr_cs_n        ),
                .ras_n   ( ddr_ras_n       ),
                .cas_n   ( ddr_cas_n       ),
                .we_n    ( ddr_we_n        ),
                .dm_tdqs ( ddr_dm[i]       ),
                .ba      ( ddr_ba          ),
                .addr    ( ddr_addr        ),
                .dq      ( ddr_dq[8*i +:8] ),
                .dqs     ( ddr_dqs_p[i]    ),
                .dqs_n   ( ddr_dqs_n[i]    ),
                .tdqs_n  (                 ),
                .odt     ( ddr_odt         )
                );
      end
   endgenerate   

 `elsif NEXYS4

   wire [15:0]  ddr_dq;
   wire [1:0]   ddr_dqs_n;
   wire [1:0]   ddr_dqs_p;
   logic [12:0] ddr_addr;
   logic [2:0]  ddr_ba;
   logic        ddr_ras_n;
   logic        ddr_cas_n;
   logic        ddr_we_n;
   logic        ddr_ck_p;
   logic        ddr_ck_n;
   logic        ddr_cke;
   logic        ddr_cs_n;
   wire [1:0]   ddr_dm;
   logic        ddr_odt;

   // behavioural DDR2 RAM
   ddr2_model u_comp_ddr2
     (
      .ck      ( ddr_ck_p        ),
      .ck_n    ( ddr_ck_n        ),
      .cke     ( ddr_cke         ),
      .cs_n    ( ddr_cs_n        ),
      .ras_n   ( ddr_ras_n       ),
      .cas_n   ( ddr_cas_n       ),
      .we_n    ( ddr_we_n        ),
      .dm_rdqs ( ddr_dm          ),
      .ba      ( ddr_ba          ),
      .addr    ( ddr_addr        ),
      .dq      ( ddr_dq          ),
      .dqs     ( ddr_dqs_p       ),
      .dqs_n   ( ddr_dqs_n       ),
      .rdqs_n  (                 ),
      .odt     ( ddr_odt         )
      );
 `endif // !`elsif NEXYS4
`endif //  `ifdef ADD_PHY_DDR

`ifdef ADD_HID
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

`endif

`ifdef ADD_FLASH
   wire         flash_ss;
   wire [3:0]   flash_io;

   assign flash_ss = 'bz;
   assign flash_io = 'bzzzz;
`endif

`ifdef ADD_SPI
   wire         spi_cs;
   wire         spi_sclk;
   wire         spi_mosi;
   wire         spi_miso;
   wire         sd_reset;

   assign spi_cs = 'bz;
   assign spi_sclk = 'bz;
   assign spi_mosi = 'bz;
   assign spi_miso = 'bz;
`endif //  `ifdef ADD_SPI

`ifdef ADD_HID

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
`ifdef KC705   
   wire [3:0]   i_dip = 4'hE;
`else   
   wire [15:0]   i_dip = 16'hE;
`endif

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

`endif //  `ifdef FPGA

`ifndef VERILATOR
   // handle all run-time arguments
   string     memfile = "";
   string     vcd_name = "";
   longint    unsigned max_cycle = 0;
   longint    unsigned cycle_cnt = 0;

`ifndef ADD_PHY_DDR
   initial begin
      #1.1;
      if($value$plusargs("load=%s", memfile))
        DUT.ram_behav.memory_load_mem(memfile);
   end // initial begin
`endif

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
`endif

`ifdef ADD_HOST
   int rv;
   always @(posedge clk) begin
      rv = DUT.host.check_exit();
      if(rv > 0)
        $fatal(rv);
      else if(rv == 0)
        $finish();
   end
`endif

`ifdef ADD_HID
  wire         o_erefclk; // RMII clock out
`ifdef KC705   
  wire [3:0]   i_erxd ;
  wire [7:0]   o_etxd ;
`else   
  wire [1:0]   i_erxd ;
  wire [1:0]   o_etxd ;
`endif   
  wire         i_erx_dv ;
  wire         i_erx_er ;
  wire         i_emdint ;
  wire         o_etx_en ;
  wire         o_etx_er ;
  wire         o_emdc ;
  wire         io_emdio ;
  wire         o_erstn ;
  wire         i_gmiiclk_p, i_gmiiclk_n;
               
   assign i_emdint = 1'b1;
   assign i_erx_dv = o_etx_en;
   assign i_erxd = o_etxd;
   assign i_erx_er = 1'b0;
`endif //  `ifdef ADD_HID

   initial
     begin
       force tb.DUT.Rocket.debug_systemjtag_jtag_TCK = 1'b0;
       force tb.DUT.Rocket.debug_systemjtag_jtag_TMS = 1'b0;
       force tb.DUT.Rocket.debug_systemjtag_jtag_TDI = 1'b0;
       force tb.DUT.Rocket.debug_systemjtag_reset = 1'b1;
       #130; 
       force tb.DUT.Rocket.debug_systemjtag_reset = 1'b0;
     end
   
endmodule // tb
