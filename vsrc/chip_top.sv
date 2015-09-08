// See LICENSE for license details.

`include "config.vh"
`include "consts.DefaultConfig.vh"

module chip_top
  (
   // clock and reset
   input clk_p, clk_n,
   input rst_top,

`ifdef FPGA
   // DDRAM3
   inout [63:0]  ddr3_dq,
   inout [7:0]   ddr3_dqs_n,
   inout [7:0]   ddr3_dqs_p,
   output [13:0] ddr3_addr,
   output [2:0]  ddr3_ba,
   output        ddr3_ras_n,
   output        ddr3_cas_n,
   output        ddr3_we_n,
   output        ddr3_reset_n,
   output        ddr3_ck_p,
   output        ddr3_ck_n,
   output        ddr3_cke,
   output        ddr3_cs_n,
   output [7:0]  ddr3_dm,
   output        ddr3_odt,
`endif
   
   // UART
   input rxd,
   output txd
   );

   // internal clock and reset signals
   logic  clk, rst, rstn;

   // the NASTI bus for cached memory
   nasti_aw mem_nasti_aw();
   nasti_w  mem_nasti_w();
   nasti_b  mem_nasti_b();
   nasti_ar mem_nasti_ar();
   nasti_r  mem_nasti_r();

   defparam mem_nasti_aw.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam mem_nasti_b.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam mem_nasti_ar.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam mem_nasti_r.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam mem_nasti_aw.ADDR_WIDTH = `PADDR_WIDTH;
   defparam mem_nasti_ar.ADDR_WIDTH = `PADDR_WIDTH;
   defparam mem_nasti_w.DATA_WIDTH = `MEM_DAT_WIDTH;
   defparam mem_nasti_r.DATA_WIDTH = `MEM_DAT_WIDTH;
   
   // the NASTI-Lite bus for IO space
   nasti_aw io_nasti_aw();
   nasti_w  io_nasti_w();
   nasti_b  io_nasti_b();
   nasti_ar io_nasti_ar();
   nasti_r  io_nasti_r();

   defparam io_nasti_aw.ADDR_WIDTH = 16;
   defparam io_nasti_ar.ADDR_WIDTH = 16;
   defparam io_nasti_w.DATA_WIDTH = `IO_DAT_WIDTH;
   defparam io_nasti_r.DATA_WIDTH = `IO_DAT_WIDTH;
   
   // the Rocket chip
   Top Rocket
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
   
   localparam MEM_DATA_WIDTH = 128;
   localparam BRAM_ADDR_WIDTH = 14;     // 16 KB
   localparam BRAM_LINE = 2 ** BRAM_ADDR_WIDTH  * 8 / MEM_DATA_WIDTH;
   localparam BRAM_LINE_OFFSET = $clog2(MEM_DATA_WIDTH/8);
   localparam DRAM_ADDR_WIDTH = 30;     // 1 GB
   
   // the NASTI bus for on-FPGA block memory
   nasti_aw bram_nasti_aw();
   nasti_w  bram_nasti_w();
   nasti_b  bram_nasti_b();
   nasti_ar bram_nasti_ar();
   nasti_r  bram_nasti_r();

   defparam bram_nasti_aw.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam bram_nasti_b.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam bram_nasti_ar.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam bram_nasti_r.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam bram_nasti_aw.ADDR_WIDTH = BRAM_ADDR_WIDTH;
   defparam bram_nasti_ar.ADDR_WIDTH = BRAM_ADDR_WIDTH;
   defparam bram_nasti_w.DATA_WIDTH = `MEM_DAT_WIDTH;
   defparam bram_nasti_r.DATA_WIDTH = `MEM_DAT_WIDTH;


   // the NASTI bus for off-FPGA DRAM
   nasti_aw dram_nasti_aw();
   nasti_w  dram_nasti_w();
   nasti_b  dram_nasti_b();
   nasti_ar dram_nasti_ar();
   nasti_r  dram_nasti_r();

   defparam dram_nasti_aw.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam dram_nasti_b.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam dram_nasti_ar.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam dram_nasti_r.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam dram_nasti_aw.ADDR_WIDTH = DRAM_ADDR_WIDTH;
   defparam dram_nasti_ar.ADDR_WIDTH = DRAM_ADDR_WIDTH;
   defparam dram_nasti_w.DATA_WIDTH = `MEM_DAT_WIDTH;
   defparam dram_nasti_r.DATA_WIDTH = `MEM_DAT_WIDTH;
   
   // the AXI crossbar for BRAM and DRAM controllers
   axi_crossbar_1x2_top
     #(
       .ADDR_WIDTH   ( `PADDR_WIDTH   ),
       .DATA_WIDTH   ( `MEM_DAT_WIDTH ),
       .ID_WIDTH     ( `MEM_TAG_WIDTH )
       )
   axi_cb
     (
      .clk     ( clk            ),
      .rstn    ( rstn           ),
      .aw_i    ( mem_nasti_aw   ),
      .w_i     ( mem_nasti_w    ),
      .b_i     ( mem_nasti_b    ),
      .ar_i    ( mem_nasti_ar   ),
      .r_i     ( mem_nasti_r    ),
      .aw_o_0  ( bram_nasti_aw  ),
      .w_o_0   ( bram_nasti_w   ),
      .b_o_0   ( bram_nasti_b   ),
      .ar_o_0  ( bram_nasti_ar  ),
      .r_o_0   ( bram_nasti_r   ),
      .aw_o_1  ( dram_nasti_aw  ),
      .w_o_1   ( dram_nasti_w   ),
      .b_o_1   ( dram_nasti_b   ),
      .ar_o_1  ( dram_nasti_ar  ),
      .r_o_1   ( dram_nasti_r   )
      );

   // BRAM controller
   logic ram_clk, ram_rst, ram_en;
   logic [MEM_DATA_WIDTH/8-1:0] ram_we;
   logic [BRAM_ADDR_WIDTH-1:0] ram_addr;
   logic [MEM_DATA_WIDTH-1:0] ram_wrdata, ram_rddata;

   axi_bram_ctrl_top #(.ADDR_WIDTH(BRAM_ADDR_WIDTH), .DATA_WIDTH(MEM_DATA_WIDTH)) 
   BramCtl
     (
      .clk          ( clk           ),
      .rstn         ( rstn          ),
      .aw           ( bram_nasti_aw ),
      .w            ( bram_nasti_w  ),
      .b            ( bram_nasti_b  ),
      .ar           ( bram_nasti_ar ),
      .r            ( bram_nasti_r  ),
      .ram_rst      ( ram_rst       ), 
      .ram_clk      ( ram_clk       ), 
      .ram_en       ( ram_en        ),
      .ram_addr     ( ram_addr      ),
      .ram_wrdata   ( ram_wrdata    ),
      .ram_we       ( ram_we        ),
      .ram_rddata   ( ram_rddata    )
      );

   // the inferred BRAMs
   reg [MEM_DATA_WIDTH-1:0] ram [0 : BRAM_LINE-1];
   reg [BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET] ram_addr_dly;
   
   always_ff @(posedge ram_clk)
     if(ram_en) begin
        ram_addr_dly <= ram_addr[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET];
        foreach (ram_we[i])
          if(ram_we[i]) ram[ram_addr[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][i*8 +:8] <= ram_wrdata[i*8 +: 8];
     end

   assign ram_rddata = ram[ram_addr_dly];

   initial $readmemh("boot.mem", ram);

   // the NASTI bus for off-FPGA DRAM, converted to High frequency
   nasti_aw mig_nasti_aw();
   nasti_w  mig_nasti_w();
   nasti_b  mig_nasti_b();
   nasti_ar mig_nasti_ar();
   nasti_r  mig_nasti_r();

   defparam mig_nasti_aw.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam mig_nasti_b.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam mig_nasti_ar.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam mig_nasti_r.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam mig_nasti_aw.ADDR_WIDTH = DRAM_ADDR_WIDTH;
   defparam mig_nasti_ar.ADDR_WIDTH = DRAM_ADDR_WIDTH;
   defparam mig_nasti_w.DATA_WIDTH = `MEM_DAT_WIDTH;
   defparam mig_nasti_r.DATA_WIDTH = `MEM_DAT_WIDTH;

   // MIG clock
   logic mig_clk, mig_rst, mig_rstn;
   always_ff @(posedge mig_clk)
     mig_rstn <= !mig_rst;

   // clock converter
   axi_clock_converter_0 clk_conv
     (
      .s_axi_aclk           ( clk                   ),
      .s_axi_aresetn        ( rstn                  ),
      .s_axi_awid           ( dram_nasti_aw.id      ),
      .s_axi_awaddr         ( dram_nasti_aw.addr    ),
      .s_axi_awlen          ( dram_nasti_aw.len     ),
      .s_axi_awsize         ( dram_nasti_aw.size    ),
      .s_axi_awburst        ( dram_nasti_aw.burst   ),
      .s_axi_awlock         ( 1'b0                  ), // not supported in AXI4
      .s_axi_awcache        ( dram_nasti_aw.cache   ),
      .s_axi_awprot         ( dram_nasti_aw.prot    ),
      .s_axi_awqos          ( dram_nasti_aw.qos     ),
      .s_axi_awregion       ( dram_nasti_aw.region  ),
      .s_axi_awvalid        ( dram_nasti_aw.valid   ),
      .s_axi_awready        ( dram_nasti_aw.ready   ),
      .s_axi_wdata          ( dram_nasti_w.data     ),
      .s_axi_wstrb          ( dram_nasti_w.strb     ),
      .s_axi_wlast          ( dram_nasti_w.last     ),
      .s_axi_wvalid         ( dram_nasti_w.valid    ),
      .s_axi_wready         ( dram_nasti_w.ready    ),
      .s_axi_bid            ( dram_nasti_b.id       ),
      .s_axi_bresp          ( dram_nasti_b.resp     ),
      .s_axi_bvalid         ( dram_nasti_b.valid    ),
      .s_axi_bready         ( dram_nasti_b.ready    ),
      .s_axi_arid           ( dram_nasti_ar.id      ),
      .s_axi_araddr         ( dram_nasti_ar.addr    ),
      .s_axi_arlen          ( dram_nasti_ar.len     ),
      .s_axi_arsize         ( dram_nasti_ar.size    ),
      .s_axi_arburst        ( dram_nasti_ar.burst   ),
      .s_axi_arlock         ( 1'b0                  ), // not supported in AXI4
      .s_axi_arcache        ( dram_nasti_ar.cache   ),
      .s_axi_arprot         ( dram_nasti_ar.prot    ),
      .s_axi_arqos          ( dram_nasti_ar.qos     ),
      .s_axi_arregion       ( dram_nasti_ar.region  ),
      .s_axi_arvalid        ( dram_nasti_ar.valid   ),
      .s_axi_arready        ( dram_nasti_ar.ready   ),
      .s_axi_rid            ( dram_nasti_r.id       ),
      .s_axi_rdata          ( dram_nasti_r.data     ),
      .s_axi_rresp          ( dram_nasti_r.resp     ),
      .s_axi_rlast          ( dram_nasti_r.last     ),
      .s_axi_rvalid         ( dram_nasti_r.valid    ),
      .s_axi_rready         ( dram_nasti_r.ready    ),
      .m_axi_aclk           ( mig_clk               ),
      .m_axi_aresetn        ( mig_rstn              ),
      .m_axi_awid           ( mig_nasti_aw.id       ),
      .m_axi_awaddr         ( mig_nasti_aw.addr     ),
      .m_axi_awlen          ( mig_nasti_aw.len      ),
      .m_axi_awsize         ( mig_nasti_aw.size     ),
      .m_axi_awburst        ( mig_nasti_aw.burst    ),
      .m_axi_awlock         (                       ), // not supported in AXI4
      .m_axi_awcache        ( mig_nasti_aw.cache    ),
      .m_axi_awprot         ( mig_nasti_aw.prot     ),
      .m_axi_awqos          ( mig_nasti_aw.qos      ),
      .m_axi_awregion       ( mig_nasti_aw.region   ),
      .m_axi_awvalid        ( mig_nasti_aw.valid    ),
      .m_axi_awready        ( mig_nasti_aw.ready    ),
      .m_axi_wdata          ( mig_nasti_w.data      ),
      .m_axi_wstrb          ( mig_nasti_w.strb      ),
      .m_axi_wlast          ( mig_nasti_w.last      ),
      .m_axi_wvalid         ( mig_nasti_w.valid     ),
      .m_axi_wready         ( mig_nasti_w.ready     ),
      .m_axi_bid            ( mig_nasti_b.id        ),
      .m_axi_bresp          ( mig_nasti_b.resp      ),
      .m_axi_bvalid         ( mig_nasti_b.valid     ),
      .m_axi_bready         ( mig_nasti_b.ready     ),
      .m_axi_arid           ( mig_nasti_ar.id       ),
      .m_axi_araddr         ( mig_nasti_ar.addr     ),
      .m_axi_arlen          ( mig_nasti_ar.len      ),
      .m_axi_arsize         ( mig_nasti_ar.size     ),
      .m_axi_arburst        ( mig_nasti_ar.burst    ),
      .m_axi_arlock         (                       ), // not supported in AXI4
      .m_axi_arcache        ( mig_nasti_ar.cache    ),
      .m_axi_arprot         ( mig_nasti_ar.prot     ),
      .m_axi_arqos          ( mig_nasti_ar.qos      ),
      .m_axi_arregion       ( mig_nasti_ar.region   ),
      .m_axi_arvalid        ( mig_nasti_ar.valid    ),
      .m_axi_arready        ( mig_nasti_ar.ready    ),
      .m_axi_rid            ( mig_nasti_r.id        ),
      .m_axi_rdata          ( mig_nasti_r.data      ),
      .m_axi_rresp          ( mig_nasti_r.resp      ),
      .m_axi_rlast          ( mig_nasti_r.last      ),
      .m_axi_rvalid         ( mig_nasti_r.valid     ),
      .m_axi_rready         ( mig_nasti_r.ready     )
      );

   // DRAM controller
   mig_7series_0 dram_ctl
     (
      .sys_clk_p            ( clk_p                 ),
      .sys_clk_n            ( clk_n                 ),
      .sys_rst              ( rst_top               ),
      .ddr3_dq              ( ddr3_dq               ),
      .ddr3_dqs_n           ( ddr3_dqs_n            ),
      .ddr3_dqs_p           ( ddr3_dqs_p            ),
      .ddr3_addr            ( ddr3_addr             ),
      .ddr3_ba              ( ddr3_ba               ),
      .ddr3_ras_n           ( ddr3_ras_n            ),
      .ddr3_cas_n           ( ddr3_cas_n            ),
      .ddr3_we_n            ( ddr3_we_n             ),
      .ddr3_reset_n         ( ddr3_reset_n          ),
      .ddr3_ck_p            ( ddr3_ck_p             ),
      .ddr3_ck_n            ( ddr3_ck_n             ),
      .ddr3_cke             ( ddr3_cke              ),
      .ddr3_cs_n            ( ddr3_cs_n             ),
      .ddr3_dm              ( ddr3_dm               ),
      .ddr3_odt             ( ddr3_odt              ),
      .ui_clk               ( mig_clk               ),
      .ui_clk_sync_rst      ( mig_rst               ),
      .ui_addn_clk_0        ( clk                   ),
      .mmcm_locked          ( rstn                  ),
      .aresetn              ( rstn                  ), // AXI reset
      .app_sr_req           ( 1'b0                  ),
      .app_ref_req          ( 1'b0                  ),
      .app_zq_req           ( 1'b0                  ),
      .s_axi_awid           ( mig_nasti_aw.id       ),
      .s_axi_awaddr         ( mig_nasti_aw.addr     ),
      .s_axi_awlen          ( mig_nasti_aw.len      ),
      .s_axi_awsize         ( mig_nasti_aw.size     ),
      .s_axi_awburst        ( mig_nasti_aw.burst    ),
      .s_axi_awlock         ( 1'b0                  ), // not supported in AXI4
      .s_axi_awcache        ( mig_nasti_aw.cache    ),
      .s_axi_awprot         ( mig_nasti_aw.prot     ),
      .s_axi_awqos          ( mig_nasti_aw.qos      ),
      .s_axi_awvalid        ( mig_nasti_aw.valid    ),
      .s_axi_awready        ( mig_nasti_aw.ready    ),
      .s_axi_wdata          ( mig_nasti_w.data      ),
      .s_axi_wstrb          ( mig_nasti_w.strb      ),
      .s_axi_wlast          ( mig_nasti_w.last      ),
      .s_axi_wvalid         ( mig_nasti_w.valid     ),
      .s_axi_wready         ( mig_nasti_w.ready     ),
      .s_axi_bid            ( mig_nasti_b.id        ),
      .s_axi_bresp          ( mig_nasti_b.resp      ),
      .s_axi_bvalid         ( mig_nasti_b.valid     ),
      .s_axi_bready         ( mig_nasti_b.ready     ),
      .s_axi_arid           ( mig_nasti_ar.id       ),
      .s_axi_araddr         ( mig_nasti_ar.addr     ),
      .s_axi_arlen          ( mig_nasti_ar.len      ),
      .s_axi_arsize         ( mig_nasti_ar.size     ),
      .s_axi_arburst        ( mig_nasti_ar.burst    ),
      .s_axi_arlock         ( 1'b0                  ), // not supported in AXI4
      .s_axi_arcache        ( mig_nasti_ar.cache    ),
      .s_axi_arprot         ( mig_nasti_ar.prot     ),
      .s_axi_arqos          ( mig_nasti_ar.qos      ),
      .s_axi_arvalid        ( mig_nasti_ar.valid    ),
      .s_axi_arready        ( mig_nasti_ar.ready    ),
      .s_axi_rid            ( mig_nasti_r.id        ),
      .s_axi_rdata          ( mig_nasti_r.data      ),
      .s_axi_rresp          ( mig_nasti_r.resp      ),
      .s_axi_rlast          ( mig_nasti_r.last      ),
      .s_axi_rvalid         ( mig_nasti_r.valid     ),
      .s_axi_rready         ( mig_nasti_r.ready     )
      );

   assign rst = !rstn;
   
   // Xilinx UART IP
   axi_uart16550_0 uart_i
     (
      .s_axi_aclk      ( clk                ),
      .s_axi_aresetn   ( rstn               ),
      .s_axi_araddr    ( io_nasti_ar.addr   ),
      .s_axi_arready   ( io_nasti_ar.ready  ),
      .s_axi_arvalid   ( io_nasti_ar.valid  ),
      .s_axi_awaddr    ( io_nasti_aw.addr   ),
      .s_axi_awready   ( io_nasti_aw.ready  ),
      .s_axi_awvalid   ( io_nasti_aw.valid  ),
      .s_axi_bready    ( io_nasti_b.ready   ),
      .s_axi_bresp     ( io_nasti_b.resp    ),
      .s_axi_bvalid    ( io_nasti_b.valid   ),
      .s_axi_rdata     ( io_nasti_r.data    ),
      .s_axi_rready    ( io_nasti_r.ready   ),
      .s_axi_rresp     ( io_nasti_r.resp    ),
      .s_axi_rvalid    ( io_nasti_r.valid   ),
      .s_axi_wdata     ( io_nasti_w.data    ),
      .s_axi_wready    ( io_nasti_w.ready   ),
      .s_axi_wstrb     ( io_nasti_w.strb    ),
      .s_axi_wvalid    ( io_nasti_w.valid   ),
      .freeze          ( 1'b0               ),
      .rin             ( 1'b1               ),
      .dcdn            ( 1'b1               ),
      .dsrn            ( 1'b1               ),
      .sin             ( rxd                ),
      .sout            ( txd                ),
      .ctsn            ( 1'b1               ),
      .rtsn            (                    )
      );

`elsif SIMULATION

   assign clk = clk_p;
   assign rst = rst_top;
   assign rstn = !rst_top;

   axi_ram_behav
     #(
       .ID_WIDTH     ( `MEM_TAG_WIDTH   ),
       .ADDR_WIDTH   ( `PADDR_WIDTH     ),
       .DATA_WIDTH   ( `MEM_DAT_WIDTH   ),
       .USER_WIDTH   ( 1                )
       )
   ram_behav
     (
      .clk           ( clk              ),
      .rstn          ( rstn             ),
      .aw            ( mem_nasti_aw     ),
      .w             ( mem_nasti_w      ),
      .b             ( mem_nasti_b      ),
      .ar            ( mem_nasti_ar     ),
      .r             ( mem_nasti_r      )
      );

`endif

endmodule // chip_top
