// See LICENSE for license details.

// a wrapper to handle width mismatching issues in mixed-language simulations (Vivado iSim at least)

module axi_bram_ctrl_top
  #(
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128
    )
   (
    input clk, rstn,
    nasti_aw.slave aw,
    nasti_w.slave w,
    nasti_b.slave b,
    nasti_ar.slave ar,
    nasti_r.slave r,
    output ram_rst, ram_clk, ram_en,
    output [ADDR_WIDTH-1:0] ram_addr,
    output [DATA_WIDTH-1:0] ram_wrdata,
    output [DATA_WIDTH/8-1:0] ram_we,
    input  [DATA_WIDTH-1:0] ram_rddata
    );

   // patchy as Vivado iSim mistakes last/len/size as functions.
   
   logic [ADDR_WIDTH-1:0]   s_axi_awaddr, s_axi_araddr;
   assign s_axi_awaddr = aw.addr;
   assign s_axi_araddr = ar.addr;
   
   logic [7:0]              s_axi_awlen, s_axi_arlen;
   assign s_axi_awlen = aw.len;
   assign s_axi_arlen = ar.len;
   
   logic [2:0]              s_axi_awsize, s_axi_arsize;
   assign s_axi_awsize = aw.size;
   assign s_axi_arsize = ar.size;
   
   logic                    s_axi_wlast, s_axi_rlast;
   assign s_axi_wlast = w.last;
   assign r.last = s_axi_rlast;
   
   
   axi_bram_ctrl_0 BramCtl
     (
      .s_axi_aclk      ( clk                     ),
      .s_axi_aresetn   ( rstn                    ),
      .s_axi_awid      ( aw.id                   ),
      .s_axi_awaddr    ( s_axi_awaddr            ),
      .s_axi_awlen     ( s_axi_awlen             ),
      .s_axi_awsize    ( s_axi_awsize            ),
      .s_axi_awburst   ( aw.burst                ),
      .s_axi_awlock    ( aw.lock                 ),
      .s_axi_awcache   ( aw.cache                ),
      .s_axi_awprot    ( aw.prot                 ),
      .s_axi_awvalid   ( aw.valid                ),
      .s_axi_awready   ( aw.ready                ),
      .s_axi_wdata     ( w.data                  ),
      .s_axi_wstrb     ( w.strb                  ),
      .s_axi_wlast     ( s_axi_wlast             ),
      .s_axi_wvalid    ( w.valid                 ),
      .s_axi_wready    ( w.ready                 ),
      .s_axi_bid       ( b.id                    ),
      .s_axi_bresp     ( b.resp                  ),
      .s_axi_bvalid    ( b.valid                 ),
      .s_axi_bready    ( b.ready                 ),
      .s_axi_arid      ( ar.id                   ),
      .s_axi_araddr    ( s_axi_araddr            ),
      .s_axi_arlen     ( s_axi_arlen             ),
      .s_axi_arsize    ( s_axi_arsize            ),
      .s_axi_arburst   ( ar.burst                ),
      .s_axi_arlock    ( ar.lock                 ),
      .s_axi_arcache   ( ar.cache                ),
      .s_axi_arprot    ( ar.prot                 ),
      .s_axi_arvalid   ( ar.valid                ),
      .s_axi_arready   ( ar.ready                ),
      .s_axi_rid       ( r.id                    ),
      .s_axi_rdata     ( r.data                  ),
      .s_axi_rresp     ( r.resp                  ),
      .s_axi_rlast     ( s_axi_rlast             ),
      .s_axi_rvalid    ( r.valid                 ),
      .s_axi_rready    ( r.ready                 ),
      .bram_rst_a      ( ram_rst                 ),
      .bram_clk_a      ( ram_clk                 ),
      .bram_en_a       ( ram_en                  ),
      .bram_we_a       ( ram_we                  ),
      .bram_addr_a     ( ram_addr                ),
      .bram_wrdata_a   ( ram_wrdata              ),
      .bram_rddata_a   ( ram_rddata              )
      );

endmodule // axi_bram_ctrl_top
