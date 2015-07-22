// See LICENSE for license details.

`include "config.vh"
`include "consts.DefaultConfig.vh"

module chip_top
  (
   // clock
`ifdef FPGA
   input clk_p, clk_n,
`else
   input clk_top,
`endif

   // reset
   input rst_top,

   // UART
   input rxd,
   output txd
   );

   // get the clock and reset signal
   logic  clk, rst, rstn;

`ifdef FPGA
 `ifdef USE_PLL
   
   clk_wiz_0 mmcm
     (
      .clk_in1_p   ( clk_p   ),
      .clk_in1_n   ( clk_n   ),
      .clk_out1    ( clk_top ),
      .reset       ( rst_top ),
      .locked      ( rstn    )
      );
   assign rst = !rstn;
 
 `else // !`ifdef USE_PLL

   IBUFGDS clk_buf (.O(clk), .I(clk_p), .IB(clk_n));
   assign rst = rst_top;
   assign rstn = !rst;
   
 `endif
`else

   assign clk = clk_top;
   assign rst = rst_top;
   assign rstn = !rst;

`endif

   // the NASTI bus for cached memory
   nasti_aw mem_nasti_aw;
   nasti_w  mem_nasti_w;
   nasti_b  mem_nasti_b;
   nasti_ar mem_nasti_ar;
   nasti_r  mem_nasti_r;

   defparam mem_nasti_aw.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam mem_nasti_b.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam mem_nasti_ar.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam mem_nasti_r.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam mem_nasti_aw.ADDR_WIDTH = `PADDR_WIDTH;
   defparam mem_nasti_ar.ADDR_WIDTH = `PADDR_WIDTH;
   defparam mem_nasti_w.DATA_WIDTH = `MEM_DAT_WIDTH;
   defparam mem_nasti_r.DATA_WIDTH = `MEM_DAT_WIDTH;

   // the NASTI-Lite bus for IO space
   nasti_aw io_nasti_aw;
   nasti_w  io_nasti_w;
   nasti_b  io_nasti_b;
   nasti_ar io_nasti_ar;
   nasti_r  io_nasti_r;

   defparam io_nasti_aw.ADDR_WIDTH = 16;
   defparam io_nasti_ar.ADDR_WIDTH = 16;
   defparam io_nasti_w.DATA_WIDTH = `IO_DAT_WIDTH;
   defparam io_nasti_r.DATA_WIDTH = `IO_DAT_WIDTH;

   // the Rocket chip
   Top
     (
      .clk                           ( clk                 ),
      .reset                         ( rst                 ),

      .io_nasti_aw_valid             ( mem_nasti_aw.valid  ),
      .io_nasti_aw_ready             ( mem_nasti_aw.ready  ),
      .io_nasti_aw_bits_id           ( mem_nasti_aw.id     ),
      .io_nasti_aw_bits_addr         ( mem_nasti_aw.addr   ),
      .io_nasti_aw_bits_len          ( mem_nasti_aw.len    ),
      .io_nasti_aw_bits_size         ( mem_nasti_aw.size   ),
      .io_nasti_aw_bits_burst        ( mem_nasti_aw.burst  ),
      .io_nasti_aw_bits_lock         ( mem_nasti_aw.lock   ),
      .io_nasti_aw_bits_cache        ( mem_nasti_aw.cache  ),
      .io_nasti_aw_bits_prot         ( mem_nasti_aw.prot   ),
      .io_nasti_aw_bits_qos          ( mem_nasti_aw.qos    ),
      .io_nasti_aw_bits_region       ( mem_nasti_aw.region ),
      .io_nasti_aw_bits_user         ( mem_nasti_aw.user   ),

      .io_nasti_w_valid              ( mem_nasti_w.valid   ),
      .io_nasti_w_ready              ( mem_nasti_w.ready   ),
      .io_nasti_w_bits_data          ( mem_nasti_w.data    ),
      .io_nasti_w_bits_strb          ( mem_nasti_w.strb    ),
      .io_nasti_w_bits_last          ( mem_nasti_w.last    ),
      .io_nasti_w_bits_user          ( mem_nasti_w.user    ),

      .io_nasti_b_valid              ( mem_nasti_b.valid   ),
      .io_nasti_b_ready              ( mem_nasti_b.ready   ),
      .io_nasti_b_bits_id            ( mem_nasti_b.id      ),
      .io_nasti_b_bits_resp          ( mem_nasti_b.resp    ),
      .io_nasti_b_bits_user          ( mem_nasti_b.user    ),

      .io_nasti_ar_valid             ( mem_nasti_ar.valid  ),
      .io_nasti_ar_ready             ( mem_nasti_ar.ready  ),
      .io_nasti_ar_bits_id           ( mem_nasti_ar.id     ),
      .io_nasti_ar_bits_addr         ( mem_nasti_ar.addr   ),
      .io_nasti_ar_bits_len          ( mem_nasti_ar.len    ),
      .io_nasti_ar_bits_size         ( mem_nasti_ar.size   ),
      .io_nasti_ar_bits_burst        ( mem_nasti_ar.burst  ),
      .io_nasti_ar_bits_lock         ( mem_nasti_ar.lock   ),
      .io_nasti_ar_bits_cache        ( mem_nasti_ar.cache  ),
      .io_nasti_ar_bits_prot         ( mem_nasti_ar.prot   ),
      .io_nasti_ar_bits_qos          ( mem_nasti_ar.qos    ),
      .io_nasti_ar_bits_region       ( mem_nasti_ar.region ),
      .io_nasti_ar_bits_user         ( mem_nasti_ar.user   ),

      .io_nasti_r_valid              ( mem_nasti_r.valid   ),
      .io_nasti_r_ready              ( mem_nasti_r.ready   ),
      .io_nasti_r_bits_id            ( mem_nasti_r.id      ),
      .io_nasti_r_bits_data          ( mem_nasti_r.data    ),
      .io_nasti_r_bits_resp          ( mem_nasti_r.resp    ),
      .io_nasti_r_bits_last          ( mem_nasti_r.last    ),
      .io_nasti_r_bits_user          ( mem_nasti_r.user    ),

      .io_nasti_lite_aw_valid        ( io_nasti_aw.valid   ),
      .io_nasti_lite_aw_ready        ( io_nasti_aw.ready   ),
      .io_nasti_lite_aw_bits_id      ( io_nasti_aw.id      ),
      .io_nasti_lite_aw_bits_addr    ( io_nasti_aw.addr    ),
      .io_nasti_lite_aw_bits_prot    ( io_nasti_aw.prot    ),
      .io_nasti_lite_aw_bits_qos     ( io_nasti_aw.qos     ),
      .io_nasti_lite_aw_bits_region  ( io_nasti_aw.region  ),
      .io_nasti_lite_aw_bits_user    ( io_nasti_aw.user    ),

      .io_nasti_lite_w_valid         ( io_nasti_w.valid    ),
      .io_nasti_lite_w_ready         ( io_nasti_w.ready    ),
      .io_nasti_lite_w_bits_data     ( io_nasti_w.data     ),
      .io_nasti_lite_w_bits_strb     ( io_nasti_w.strb     ),
      .io_nasti_lite_w_bits_user     ( io_nasti_w.user     ),

      .io_nasti_lite_b_valid         ( io_nasti_b.valid    ),
      .io_nasti_lite_b_ready         ( io_nasti_b.ready    ),
      .io_nasti_lite_b_bits_id       ( io_nasti_b.id       ),
      .io_nasti_lite_b_bits_resp     ( io_nasti_b.resp     ),
      .io_nasti_lite_b_bits_user     ( io_nasti_b.user     ),

      .io_nasti_lite_ar_valid        ( io_nasti_ar.valid   ),
      .io_nasti_lite_ar_ready        ( io_nasti_ar.ready   ),
      .io_nasti_lite_ar_bits_id      ( io_nasti_ar.id      ),
      .io_nasti_lite_ar_bits_addr    ( io_nasti_ar.addr    ),
      .io_nasti_lite_ar_bits_prot    ( io_nasti_ar.prot    ),
      .io_nasti_lite_ar_bits_qos     ( io_nasti_ar.qos     ),
      .io_nasti_lite_ar_bits_region  ( io_nasti_ar.region  ),
      .io_nasti_lite_ar_bits_user    ( io_nasti_ar.user    ),

      .io_nasti_lite_r_valid         ( io_nasti_r.valid    ),
      .io_nasti_lite_r_ready         ( io_nasti_r.ready    ),
      .io_nasti_lite_r_bits_id       ( io_nasti_r.id       ),
      .io_nasti_lite_r_bits_data     ( io_nasti_r.data     ),
      .io_nasti_lite_r_bits_resp     ( io_nasti_r.resp     ),
      .io_nasti_lite_r_bits_user     ( io_nasti_r.user     )
      );

   // the memory contoller
`ifdef FPGA
   
   axi_bram_ctrl_0 BramCtl
     (
      .s_axi_aclk      ( clk           ),
      .s_axi_aresetn   ( lrstn         ),
      .s_axi_awid      ( axi_awid      ),
      .s_axi_awaddr    ( axi_awaddr    ),
      .s_axi_awlen     ( 8'h7          ), // 8 burst
      .s_axi_awsize    ( 3'b011        ), // 4 byts per beat
      .s_axi_awburst   ( 2'b01         ), // INCR burst
      .s_axi_awlock    ( 1'b0          ), // no lock, AXI3 std.
      .s_axi_awcache   ( 4'b0011       ), // nornal un-cacheable bufferable
      .s_axi_awprot    ( 3'h0          ),
      .s_axi_awvalid   ( axi_awvalid   ),
      .s_axi_awready   ( axi_awready   ),
      .s_axi_wdata     ( axi_wdata     ),
      .s_axi_wstrb     ( 8'hff         ),
      .s_axi_wlast     ( axi_wlast     ),
      .s_axi_wvalid    ( axi_wvalid    ),
      .s_axi_wready    ( axi_wready    ),
      .s_axi_bid       ( axi_bid       ),
      .s_axi_bresp     ( axi_bresp     ),
      .s_axi_bvalid    ( axi_bvalid    ),
      .s_axi_bready    ( axi_bready    ),
      .s_axi_arid      ( axi_arid      ),
      .s_axi_araddr    ( axi_araddr    ),
      .s_axi_arlen     ( 8'h7          ),
      .s_axi_arsize    ( 3'b011        ),
      .s_axi_arburst   ( 2'b01         ),
      .s_axi_arlock    ( 1'b0          ),
      .s_axi_arcache   ( 4'b0011       ),
      .s_axi_arprot    ( 3'h0          ),
      .s_axi_arvalid   ( axi_arvalid   ),
      .s_axi_arready   ( axi_arready   ),
      .s_axi_rid       ( axi_rid       ),
      .s_axi_rdata     ( axi_rdata     ),
      .s_axi_rresp     ( axi_rresp     ),
      .s_axi_rlast     ( axi_rlast     ),
      .s_axi_rvalid    ( axi_rvalid    ),
      .s_axi_rready    ( axi_rready    ),
      .bram_rst_a      ( ram_rst       ),
      .bram_clk_a      ( ram_clk       ),
      .bram_en_a       ( ram_en        ),
      .bram_we_a       ( ram_we        ),
      .bram_addr_a     ( ram_addr      ),
      .bram_wrdata_a   ( ram_wrdata    ),
      .bram_rddata_a   ( ram_rddata    )
      );

   reg [63:0] ram [0 : 13'h1FFF];
   reg [12:0] ram_addr_dly;
   
   always_ff @(posedge ram_clk)
     if(ram_en) begin
        ram_addr_dly <= ram_addr[15:3];
        foreach (ram_we[i])
          if(ram_we[i]) ram[ram_addr[15:3]][i*8 +:8] <= ram_wrdata[i*8 +: 8];
     end

   assign ram_rddata = ram[ram_addr_dly];
   
   initial $readmemh("/local/scratch/ws327/proj/untethered/lowrisc_printf/mem/uart.mem", ram);

uart uart_i
       (.S_AXI_araddr(S_AXI_araddr),
        .S_AXI_arready(S_AXI_arready),
        .S_AXI_arvalid(S_AXI_arvalid),
        .S_AXI_awaddr(S_AXI_awaddr),
        .S_AXI_awready(S_AXI_awready),
        .S_AXI_awvalid(S_AXI_awvalid),
        .S_AXI_bready(S_AXI_bready),
        .S_AXI_bresp(S_AXI_bresp),
        .S_AXI_bvalid(S_AXI_bvalid),
        .S_AXI_rdata(S_AXI_rdata),
        .S_AXI_rready(S_AXI_rready),
        .S_AXI_rresp(S_AXI_rresp),
        .S_AXI_rvalid(S_AXI_rvalid),
        .S_AXI_wdata(S_AXI_wdata),
        .S_AXI_wready(S_AXI_wready),
        .S_AXI_wstrb(S_AXI_wstrb),
        .S_AXI_wvalid(S_AXI_wvalid),
        .freeze(freeze),
        .rs232_uart_rxd(rs232_uart_rxd),
        .rs232_uart_txd(rs232_uart_txd),
        .rs232_uart_cts(rs232_uart_cts),
        .rs232_uart_rts(rs232_uart_rts),
        .s_axi_aclk(s_axi_aclk),
        .s_axi_aresetn(s_axi_aresetn));

endmodule // chip_top
