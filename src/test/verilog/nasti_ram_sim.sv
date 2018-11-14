// See LICENSE for license details.

module nasti_ram_sim
  #(
    ID_WIDTH = 8,
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128,
    USER_WIDTH = 1
    )
   (
    input clk, rstn,
    nasti_channel.slave nasti
    );

  parameter base = 32'h80200000;

  integer i, fd, first, last;

  reg [7:0] mem[32'h0:32'h1000000];

  // Read input arguments and initialize

`ifdef NOTDEF   
  initial
    begin
    // JRRK hacks
        $readmemh("cnvmem.mem", mem);
        for (i = base; (i < base+32'h1000000) && (1'bx === ^mem[i-base]); i=i+8)
          ;
        first = i;
        for (i = base+32'h1000000; (i >= base) && (1'bx === ^mem[i-base]); i=i-8)
          ;
        last = (i+16);
        for (i = i+1; i < last; i=i+1)
          mem[i-base] = 0;
        $display("First = %X, Last = %X", first, last-1);
        for (i = first; i < last; i=i+1)
          if (1'bx === ^mem[i-base]) mem[i-base] = 0;
        #1
        for (i = first-base; i < last-base; i=i+8)
          begin
             SimAXIMem.AXI4RAM.mem.mem_ext.ram[(i+base-32'h80000000)/8] =
                 {mem[i+7],mem[i+6],mem[i+5],mem[i+4],mem[i+3],mem[i+2],mem[i+1],mem[i+0]};
          end
    end // initial begin
`endif
   
   function bit memory_load_mem (input string filename);

     begin
     end

   endfunction // memory_load_mem

   logic ram_clk, ram_rst, ram_en;
   logic [3:0] ram_we;
   logic [15:0] ram_addr;
   logic [31:0]   ram_wrdata, ram_rddata = 'HDEADBEEF;
   
   axi_bram_ctrl_dummy BehavCtrl
     (
      .s_axi_aclk      ( clk                       ),
      .s_axi_aresetn   ( rstn                      ),
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
      .s_axi_bvalid    ( nasti.b_valid  ),
      .bram_rst_a      ( ram_rst                   ),
      .bram_clk_a      ( ram_clk                   ),
      .bram_en_a       ( ram_en                    ),
      .bram_we_a       ( ram_we                    ),
      .bram_addr_a     ( ram_addr                  ),
      .bram_wrdata_a   ( ram_wrdata                ),
      .bram_rddata_a   ( ram_rddata                )
      );
   
endmodule // nasti_ram_sim
