// See LICENSE for license details.
`define NASTI_RAM_DUMMY

module nasti_ram_behav
  #(
    ID_WIDTH = 1,
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128,
    USER_WIDTH = 1
    )
   (
    input clk, rstn,
    nasti_channel.slave nasti
    );

axi_bram_ctrl_3 BramCtl
     (
      .s_axi_aclk      ( clk            ),
      .s_axi_aresetn   ( rstn           ),
      .s_axi_arid      ( nasti.ar_id    ),
      .s_axi_araddr    ( nasti.ar_addr  ),
      .s_axi_arlen     ( nasti.ar_len   ),
      .s_axi_arsize    ( nasti.ar_size  ),
      .s_axi_arburst   ( nasti.ar_burst ),
      .s_axi_arlock    ( nasti.ar_lock  ),
      .s_axi_arcache   ( nasti.ar_cache ),
      .s_axi_arprot    ( nasti.ar_prot  ),
      .s_axi_arready   ( nasti.ar_ready ),
      .s_axi_arvalid   ( nasti.ar_valid ),
      .s_axi_rid       ( nasti.r_id     ),
      .s_axi_rdata     ( nasti.r_data   ),
      .s_axi_rresp     ( nasti.r_resp   ),
      .s_axi_rlast     ( nasti.r_last   ),
      .s_axi_rready    ( nasti.r_ready  ),
      .s_axi_rvalid    ( nasti.r_valid  ),
      .s_axi_awid      ( nasti.aw_id    ),
      .s_axi_awaddr    ( nasti.aw_addr  ),
      .s_axi_awlen     ( nasti.aw_len   ),
      .s_axi_awsize    ( nasti.aw_size  ),
      .s_axi_awburst   ( nasti.aw_burst ),
      .s_axi_awlock    ( nasti.aw_lock  ),
      .s_axi_awcache   ( nasti.aw_cache ),
      .s_axi_awprot    ( nasti.aw_prot  ),
      .s_axi_awready   ( nasti.aw_ready ),
      .s_axi_awvalid   ( nasti.aw_valid ),
      .s_axi_wdata     ( nasti.w_data   ),
      .s_axi_wstrb     ( nasti.w_strb   ),
      .s_axi_wlast     ( nasti.w_last   ),
      .s_axi_wready    ( nasti.w_ready  ),
      .s_axi_wvalid    ( nasti.w_valid  ),
      .s_axi_bid       ( nasti.b_id     ),
      .s_axi_bresp     ( nasti.b_resp   ),
      .s_axi_bready    ( nasti.b_ready  ),
      .s_axi_bvalid    ( nasti.b_valid  )
      );

endmodule // spi_wrapper
