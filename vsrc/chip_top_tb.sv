// See LICENSE for license details.

module tb;

   logic clk, rst;

   chip_top
     DUT(
         .*,
         .clk_p(clk),
         .clk_n(!clk),
         .rst_top(rst), 
         .rxd(1'b1),
         .txd()
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
      forever clk = #2.5 !clk;
   end // initial begin

`ifdef FPGA
   // DDRAM3
   wire [63:0]  ddr3_dq;
   wire [7:0]   ddr3_dqs_n;
   wire [7:0]   ddr3_dqs_p;
   logic [13:0] ddr3_addr;
   logic [2:0]  ddr3_ba;
   logic        ddr3_ras_n;
   logic        ddr3_cas_n;
   logic        ddr3_we_n;
   logic        ddr3_reset_n;
   logic        ddr3_ck_p;
   logic        ddr3_ck_n;
   logic        ddr3_cke;
   logic        ddr3_cs_n;
   logic [7:0]  ddr3_dm;
   logic        ddr3_odt;

   // behavioural DDR3 RAM
   genvar       i;
   generate
      for (i = 0; i < 8; i = i + 1) begin: gen_mem
         ddr3_model u_comp_ddr3
               (
                .rst_n   ( ddr3_reset_n     ),
                .ck      ( ddr3_ck_p        ),
                .ck_n    ( ddr3_ck_n        ),
                .cke     ( ddr3_cke         ),
                .cs_n    ( ddr3_cs_n        ),
                .ras_n   ( ddr3_ras_n       ),
                .cas_n   ( ddr3_cas_n       ),
                .we_n    ( ddr3_we          ),
                .dm_tdqs ( ddr3_dm[i]       ),
                .ba      ( ddr3_ba          ),
                .addr    ( ddr3_addr        ),
                .dq      ( ddr3_dq[8*i +:8] ),
                .dqs     ( ddr3_dqs_p[i]    ),
                .dqs_n   ( ddr3_dqs_n[i]    ),
                .tdqs_n  (                  ),
                .odt     ( ddr3_odt         )
                );
      end
   endgenerate




`endif
   
endmodule // tb
