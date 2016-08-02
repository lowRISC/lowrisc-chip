// See LICENSE for license details.

`include "consts.vh"

module tb;

   logic clk, rst;

   chip_top
     DUT(
         .*,
`ifdef FPGA
         .rxd(1'b1),
         .txd(),
`endif
         .clk_p(clk),
         .clk_n(!clk),
`ifdef FPGA_FULL
 `ifdef NEXYS4_COMMON
         .rst_top(!rst)         // NEXYS4's cpu_reset is active low
 `else
         .rst_top(rst)
 `endif
`else
         .rst_top(rst)
`endif
         );

   initial begin
      rst = 0;
      #3;
      rst = 1;
      #130;
      rst = 0;
   end

   initial begin
      clk = 0;
  `ifdef KC705
      forever clk = #2.5 !clk;
  `else
      forever clk = #5 !clk;
  `endif
   end // initial begin

`ifdef FPGA
 `ifdef FPGA_FULL
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
  `endif
 `endif //  `ifdef FPGA_FULL

   // spi
   wire spi_cs, spi_sclk, spi_mosi, spi_miso;
   wire sd_reset;
   assign spi_cs = 1'bz;
   assign spi_sclk = 1'bz;
   assign spi_mosi = 1'bz;
   assign spi_miso = !spi_cs ? spi_mosi : 1'bz;

   assign spi_sclk = 1'bz;

   // flash
   wire flash_ss;
   wire [3:0] flash_io;

   assign flash_ss = 1'bz;
   assign flash_io = 4'bzzzz;

`endif

endmodule // tb
