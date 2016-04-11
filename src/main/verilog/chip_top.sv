// See LICENSE for license details.

import dii_package::dii_flit;

`include "config.vh"
`include "consts.vh"

module chip_top
  (
`ifdef ADD_DDR_IO
 `ifdef KC705
   // DDR3 RAM
   inout [63:0]  ddr_dq,
   inout [7:0]   ddr_dqs_n,
   inout [7:0]   ddr_dqs_p,
   output [13:0] ddr_addr,
   output [2:0]  ddr_ba,
   output        ddr_ras_n,
   output        ddr_cas_n,
   output        ddr_we_n,
   output        ddr_reset_n,
   output        ddr_ck_n,
   output        ddr_ck_p,
   output        ddr_cke,
   output        ddr_cs_n,
   output [7:0]  ddr_dm,
   output        ddr_odt,
 `elsif NEXYS4
   // DDR2 RAM
   inout [15:0]  ddr_dq,
   inout [1:0]   ddr_dqs_n,
   inout [1:0]   ddr_dqs_p,
   output [12:0] ddr_addr,
   output [2:0]  ddr_ba,
   output        ddr_ras_n,
   output        ddr_cas_n,
   output        ddr_we_n,
   output        ddr_ck_n,
   output        ddr_ck_p,
   output        ddr_cke,
   output        ddr_cs_n,
   output [1:0]  ddr_dm,
   output        ddr_odt,
 `endif
`endif //  `ifdef ADD_DDR_IO

`ifdef ADD_UART_IO
   input         rxd,
   output        txd,
`endif

`ifdef ADD_SPI_IO
   inout         spi_cs,
   inout         spi_sclk,
   inout         spi_mosi,
   inout         spi_miso,
`endif

   // clock and reset
   input         clk_p,
   input         clk_n,
   input         rst_top
   );

   // internal clock and reset signals
   logic  clk, rst, rstn;
   assign rst = !rstn;

   // Debug controlled reset of the Rocket system
   logic  sys_rst, cpu_rst;

   // interrupt line
   logic [63:0]                interrupt;

   /////////////////////////////////////////////////////////////
   // NASTI/Lite on-chip interconnects

   // Rocket memory nasti bus
   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_nasti();
   logic [`MEM_TAG_WIDTH - 1 : 0] mem_nasti_aw_id, mem_nasti_ar_id;
   assign mem_nasti.aw_id = {1'b0, mem_nasti_aw_id};  // differentiate Memory from IO
   assign mem_nasti.ar_id = {1'b0, mem_nasti_ar_id};

   // Rocket IO nasti-lite bus
   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `IO_DAT_WIDTH      ))
   io_lite();
   logic [`MEM_TAG_WIDTH - 1 : 0] io_lite_aw_id, io_lite_ar_id;
   assign io_lite.aw_id = {1'b1, io_lite_aw_id};  // differentiate Memory from IO
   assign io_lite.ar_id = {1'b1, io_lite_ar_id};


   /////////////////////////////////////////////////////////////
   // Memory System

   localparam MEM_DATA_WIDTH = 128;
   localparam BRAM_ADDR_WIDTH = 16;     // 64 KB
   localparam BRAM_LINE = 2 ** BRAM_ADDR_WIDTH  * 8 / MEM_DATA_WIDTH;
   localparam BRAM_LINE_OFFSET = $clog2(MEM_DATA_WIDTH/8);
   localparam DRAM_ADDR_WIDTH = 30;     // 1 GB

   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( BRAM_ADDR_WIDTH    ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_bram_nasti();

`ifdef ADD_BOOT_MEM
   // BRAM controller
   logic ram_clk, ram_rst, ram_en;
   logic [MEM_DATA_WIDTH/8-1:0] ram_we;
   logic [BRAM_ADDR_WIDTH-1:0] ram_addr;
   logic [MEM_DATA_WIDTH-1:0] ram_wrdata, ram_rddata;

   axi_bram_ctrl_0 BramCtl
     (
      .s_axi_aclk      ( clk                     ),
      .s_axi_aresetn   ( rstn                    ),
      .s_axi_awid      ( mem_bram_nasti.aw_id    ),
      .s_axi_awaddr    ( mem_bram_nasti.aw_addr  ),
      .s_axi_awlen     ( mem_bram_nasti.aw_len   ),
      .s_axi_awsize    ( mem_bram_nasti.aw_size  ),
      .s_axi_awburst   ( mem_bram_nasti.aw_burst ),
      .s_axi_awlock    ( mem_bram_nasti.aw_lock  ),
      .s_axi_awcache   ( mem_bram_nasti.aw_cache ),
      .s_axi_awprot    ( mem_bram_nasti.aw_prot  ),
      .s_axi_awvalid   ( mem_bram_nasti.aw_valid ),
      .s_axi_awready   ( mem_bram_nasti.aw_ready ),
      .s_axi_wdata     ( mem_bram_nasti.w_data   ),
      .s_axi_wstrb     ( mem_bram_nasti.w_strb   ),
      .s_axi_wlast     ( mem_bram_nasti.w_last   ),
      .s_axi_wvalid    ( mem_bram_nasti.w_valid  ),
      .s_axi_wready    ( mem_bram_nasti.w_ready  ),
      .s_axi_bid       ( mem_bram_nasti.b_id     ),
      .s_axi_bresp     ( mem_bram_nasti.b_resp   ),
      .s_axi_bvalid    ( mem_bram_nasti.b_valid  ),
      .s_axi_bready    ( mem_bram_nasti.b_ready  ),
      .s_axi_arid      ( mem_bram_nasti.ar_id    ),
      .s_axi_araddr    ( mem_bram_nasti.ar_addr  ),
      .s_axi_arlen     ( mem_bram_nasti.ar_len   ),
      .s_axi_arsize    ( mem_bram_nasti.ar_size  ),
      .s_axi_arburst   ( mem_bram_nasti.ar_burst ),
      .s_axi_arlock    ( mem_bram_nasti.ar_lock  ),
      .s_axi_arcache   ( mem_bram_nasti.ar_cache ),
      .s_axi_arprot    ( mem_bram_nasti.ar_prot  ),
      .s_axi_arvalid   ( mem_bram_nasti.ar_valid ),
      .s_axi_arready   ( mem_bram_nasti.ar_ready ),
      .s_axi_rid       ( mem_bram_nasti.r_id     ),
      .s_axi_rdata     ( mem_bram_nasti.r_data   ),
      .s_axi_rresp     ( mem_bram_nasti.r_resp   ),
      .s_axi_rlast     ( mem_bram_nasti.r_last   ),
      .s_axi_rvalid    ( mem_bram_nasti.r_valid  ),
      .s_axi_rready    ( mem_bram_nasti.r_ready  ),
      .bram_rst_a      ( ram_rst                 ),
      .bram_clk_a      ( ram_clk                 ),
      .bram_en_a       ( ram_en                  ),
      .bram_we_a       ( ram_we                  ),
      .bram_addr_a     ( ram_addr                ),
      .bram_wrdata_a   ( ram_wrdata              ),
      .bram_rddata_a   ( ram_rddata              )
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
`endif //  `ifdef ADD_BOOT_MEM

   // channel for BRAM and DRAM
   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( DRAM_ADDR_WIDTH    ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_dram_nasti();

`ifdef ADD_DDR

   // the NASTI bus for off-FPGA DRAM, converted to High frequency
   nasti_channel   
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( DRAM_ADDR_WIDTH    ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_mig_nasti();

   // MIG clock
   logic mig_ui_clk, mig_ui_rst, mig_ui_rstn;
   assign mig_ui_rstn = !mig_ui_rst;

   // clock converter
   axi_clock_converter_0 clk_conv
     (
      .s_axi_aclk           ( clk                      ),
      .s_axi_aresetn        ( rstn                     ),
      .s_axi_awid           ( mem_dram_nasti.aw_id     ),
      .s_axi_awaddr         ( mem_dram_nasti.aw_addr   ),
      .s_axi_awlen          ( mem_dram_nasti.aw_len    ),
      .s_axi_awsize         ( mem_dram_nasti.aw_size   ),
      .s_axi_awburst        ( mem_dram_nasti.aw_burst  ),
      .s_axi_awlock         ( 1'b0                     ), // not supported in AXI4
      .s_axi_awcache        ( mem_dram_nasti.aw_cache  ),
      .s_axi_awprot         ( mem_dram_nasti.aw_prot   ),
      .s_axi_awqos          ( mem_dram_nasti.aw_qos    ),
      .s_axi_awregion       ( mem_dram_nasti.aw_region ),
      .s_axi_awvalid        ( mem_dram_nasti.aw_valid  ),
      .s_axi_awready        ( mem_dram_nasti.aw_ready  ),
      .s_axi_wdata          ( mem_dram_nasti.w_data    ),
      .s_axi_wstrb          ( mem_dram_nasti.w_strb    ),
      .s_axi_wlast          ( mem_dram_nasti.w_last    ),
      .s_axi_wvalid         ( mem_dram_nasti.w_valid   ),
      .s_axi_wready         ( mem_dram_nasti.w_ready   ),
      .s_axi_bid            ( mem_dram_nasti.b_id      ),
      .s_axi_bresp          ( mem_dram_nasti.b_resp    ),
      .s_axi_bvalid         ( mem_dram_nasti.b_valid   ),
      .s_axi_bready         ( mem_dram_nasti.b_ready   ),
      .s_axi_arid           ( mem_dram_nasti.ar_id     ),
      .s_axi_araddr         ( mem_dram_nasti.ar_addr   ),
      .s_axi_arlen          ( mem_dram_nasti.ar_len    ),
      .s_axi_arsize         ( mem_dram_nasti.ar_size   ),
      .s_axi_arburst        ( mem_dram_nasti.ar_burst  ),
      .s_axi_arlock         ( 1'b0                     ), // not supported in AXI4
      .s_axi_arcache        ( mem_dram_nasti.ar_cache  ),
      .s_axi_arprot         ( mem_dram_nasti.ar_prot   ),
      .s_axi_arqos          ( mem_dram_nasti.ar_qos    ),
      .s_axi_arregion       ( mem_dram_nasti.ar_region ),
      .s_axi_arvalid        ( mem_dram_nasti.ar_valid  ),
      .s_axi_arready        ( mem_dram_nasti.ar_ready  ),
      .s_axi_rid            ( mem_dram_nasti.r_id      ),
      .s_axi_rdata          ( mem_dram_nasti.r_data    ),
      .s_axi_rresp          ( mem_dram_nasti.r_resp    ),
      .s_axi_rlast          ( mem_dram_nasti.r_last    ),
      .s_axi_rvalid         ( mem_dram_nasti.r_valid   ),
      .s_axi_rready         ( mem_dram_nasti.r_ready   ),
      .m_axi_aclk           ( mig_ui_clk               ),
      .m_axi_aresetn        ( mig_ui_rstn              ),
      .m_axi_awid           ( mem_mig_nasti.aw_id      ),
      .m_axi_awaddr         ( mem_mig_nasti.aw_addr    ),
      .m_axi_awlen          ( mem_mig_nasti.aw_len     ),
      .m_axi_awsize         ( mem_mig_nasti.aw_size    ),
      .m_axi_awburst        ( mem_mig_nasti.aw_burst   ),
      .m_axi_awlock         (                          ), // not supported in AXI4
      .m_axi_awcache        ( mem_mig_nasti.aw_cache   ),
      .m_axi_awprot         ( mem_mig_nasti.aw_prot    ),
      .m_axi_awqos          ( mem_mig_nasti.aw_qos     ),
      .m_axi_awregion       ( mem_mig_nasti.aw_region  ),
      .m_axi_awvalid        ( mem_mig_nasti.aw_valid   ),
      .m_axi_awready        ( mem_mig_nasti.aw_ready   ),
      .m_axi_wdata          ( mem_mig_nasti.w_data     ),
      .m_axi_wstrb          ( mem_mig_nasti.w_strb     ),
      .m_axi_wlast          ( mem_mig_nasti.w_last     ),
      .m_axi_wvalid         ( mem_mig_nasti.w_valid    ),
      .m_axi_wready         ( mem_mig_nasti.w_ready    ),
      .m_axi_bid            ( mem_mig_nasti.b_id       ),
      .m_axi_bresp          ( mem_mig_nasti.b_resp     ),
      .m_axi_bvalid         ( mem_mig_nasti.b_valid    ),
      .m_axi_bready         ( mem_mig_nasti.b_ready    ),
      .m_axi_arid           ( mem_mig_nasti.ar_id      ),
      .m_axi_araddr         ( mem_mig_nasti.ar_addr    ),
      .m_axi_arlen          ( mem_mig_nasti.ar_len     ),
      .m_axi_arsize         ( mem_mig_nasti.ar_size    ),
      .m_axi_arburst        ( mem_mig_nasti.ar_burst   ),
      .m_axi_arlock         (                          ), // not supported in AXI4
      .m_axi_arcache        ( mem_mig_nasti.ar_cache   ),
      .m_axi_arprot         ( mem_mig_nasti.ar_prot    ),
      .m_axi_arqos          ( mem_mig_nasti.ar_qos     ),
      .m_axi_arregion       ( mem_mig_nasti.ar_region  ),
      .m_axi_arvalid        ( mem_mig_nasti.ar_valid   ),
      .m_axi_arready        ( mem_mig_nasti.ar_ready   ),
      .m_axi_rid            ( mem_mig_nasti.r_id       ),
      .m_axi_rdata          ( mem_mig_nasti.r_data     ),
      .m_axi_rresp          ( mem_mig_nasti.r_resp     ),
      .m_axi_rlast          ( mem_mig_nasti.r_last     ),
      .m_axi_rvalid         ( mem_mig_nasti.r_valid    ),
      .m_axi_rready         ( mem_mig_nasti.r_ready    )
      );

  `ifdef NEXYS4
   //clock generator
   logic mig_sys_clk, clk_locked;
   clk_wiz_0 clk_gen
     (
      .clk_in1     ( clk_p         ), // 100 MHz onboard
      .clk_out1    ( mig_sys_clk   ), // 200 MHz
      .resetn      ( rst_top       ),
      .locked      ( clk_locked    )
      );
  `endif //  `ifdef NEXYS4

   // DRAM controller
   mig_7series_0 dram_ctl
     (
   `ifdef KC705
      .sys_clk_p            ( clk_p                  ),
      .sys_clk_n            ( clk_n                  ),
      .sys_rst              ( rst_top                ),
      .ui_addn_clk_0        ( clk                    ),
      .ddr3_dq              ( ddr_dq                 ),
      .ddr3_dqs_n           ( ddr_dqs_n              ),
      .ddr3_dqs_p           ( ddr_dqs_p              ),
      .ddr3_addr            ( ddr_addr               ),
      .ddr3_ba              ( ddr_ba                 ),
      .ddr3_ras_n           ( ddr_ras_n              ),
      .ddr3_cas_n           ( ddr_cas_n              ),
      .ddr3_we_n            ( ddr_we_n               ),
      .ddr3_reset_n         ( ddr_reset_n            ),
      .ddr3_ck_p            ( ddr_ck_p               ),
      .ddr3_ck_n            ( ddr_ck_n               ),
      .ddr3_cke             ( ddr_cke                ),
      .ddr3_cs_n            ( ddr_cs_n               ),
      .ddr3_dm              ( ddr_dm                 ),
      .ddr3_odt             ( ddr_odt                ),
   `elsif NEXYS4
      .sys_clk_i            ( mig_sys_clk            ),
      .sys_rst              ( clk_locked             ),
      .ui_addn_clk_0        ( clk                    ),
      .device_temp_i        ( 0                      ),
      .ddr2_dq              ( ddr_dq                 ),
      .ddr2_dqs_n           ( ddr_dqs_n              ),
      .ddr2_dqs_p           ( ddr_dqs_p              ),
      .ddr2_addr            ( ddr_addr               ),
      .ddr2_ba              ( ddr_ba                 ),
      .ddr2_ras_n           ( ddr_ras_n              ),
      .ddr2_cas_n           ( ddr_cas_n              ),
      .ddr2_we_n            ( ddr_we_n               ),
      .ddr2_ck_p            ( ddr_ck_p               ),
      .ddr2_ck_n            ( ddr_ck_n               ),
      .ddr2_cke             ( ddr_cke                ),
      .ddr2_cs_n            ( ddr_cs_n               ),
      .ddr2_dm              ( ddr_dm                 ),
      .ddr2_odt             ( ddr_odt                ),
   `endif // !`elsif NEXYS4
      .ui_clk               ( mig_ui_clk             ),
      .ui_clk_sync_rst      ( mig_ui_rst             ),
      .mmcm_locked          ( rstn                   ),
      .aresetn              ( rstn                   ), // AXI reset
      .app_sr_req           ( 1'b0                   ),
      .app_ref_req          ( 1'b0                   ),
      .app_zq_req           ( 1'b0                   ),
      .s_axi_awid           ( mem_mig_nasti.aw_id    ),
      .s_axi_awaddr         ( mem_mig_nasti.aw_addr  ),
      .s_axi_awlen          ( mem_mig_nasti.aw_len   ),
      .s_axi_awsize         ( mem_mig_nasti.aw_size  ),
      .s_axi_awburst        ( mem_mig_nasti.aw_burst ),
      .s_axi_awlock         ( 1'b0                   ), // not supported in AXI4
      .s_axi_awcache        ( mem_mig_nasti.aw_cache ),
      .s_axi_awprot         ( mem_mig_nasti.aw_prot  ),
      .s_axi_awqos          ( mem_mig_nasti.aw_qos   ),
      .s_axi_awvalid        ( mem_mig_nasti.aw_valid ),
      .s_axi_awready        ( mem_mig_nasti.aw_ready ),
      .s_axi_wdata          ( mem_mig_nasti.w_data   ),
      .s_axi_wstrb          ( mem_mig_nasti.w_strb   ),
      .s_axi_wlast          ( mem_mig_nasti.w_last   ),
      .s_axi_wvalid         ( mem_mig_nasti.w_valid  ),
      .s_axi_wready         ( mem_mig_nasti.w_ready  ),
      .s_axi_bid            ( mem_mig_nasti.b_id     ),
      .s_axi_bresp          ( mem_mig_nasti.b_resp   ),
      .s_axi_bvalid         ( mem_mig_nasti.b_valid  ),
      .s_axi_bready         ( mem_mig_nasti.b_ready  ),
      .s_axi_arid           ( mem_mig_nasti.ar_id    ),
      .s_axi_araddr         ( mem_mig_nasti.ar_addr  ),
      .s_axi_arlen          ( mem_mig_nasti.ar_len   ),
      .s_axi_arsize         ( mem_mig_nasti.ar_size  ),
      .s_axi_arburst        ( mem_mig_nasti.ar_burst ),
      .s_axi_arlock         ( 1'b0                   ), // not supported in AXI4
      .s_axi_arcache        ( mem_mig_nasti.ar_cache ),
      .s_axi_arprot         ( mem_mig_nasti.ar_prot  ),
      .s_axi_arqos          ( mem_mig_nasti.ar_qos   ),
      .s_axi_arvalid        ( mem_mig_nasti.ar_valid ),
      .s_axi_arready        ( mem_mig_nasti.ar_ready ),
      .s_axi_rid            ( mem_mig_nasti.r_id     ),
      .s_axi_rdata          ( mem_mig_nasti.r_data   ),
      .s_axi_rresp          ( mem_mig_nasti.r_resp   ),
      .s_axi_rlast          ( mem_mig_nasti.r_last   ),
      .s_axi_rvalid         ( mem_mig_nasti.r_valid  ),
      .s_axi_rready         ( mem_mig_nasti.r_ready  )
      );

  `elsif ADD_DDR_SIM

   assign clk = clk_p;
   assign rstn = !rst_top;

   nasti_ram_behav
     #(
       .ID_WIDTH     ( `MEM_TAG_WIDTH+1 ),
       .ADDR_WIDTH   ( `PADDR_WIDTH     ),
       .DATA_WIDTH   ( `MEM_DAT_WIDTH   ),
       .USER_WIDTH   ( 1                )
       )
   ram_behav
     (
      .clk           ( clk              ),
      .rstn          ( rstn             ),
      .nasti         ( mem_dram_nasti   )
      );
  `endif // !`elsif ADD_DDR_SIM

   /////////////////////////////////////////////////////////////
   // Host interface, legacy due to regression tests

   logic  host_req_valid, host_req_ready, host_resp_valid, host_resp_ready;
   logic [$clog2(`NTILES)-1:0] host_req_id, host_resp_id;
   logic [63:0]                host_req_data, host_resp_data;

  `ifdef ADD_HOST_IF
   host_behav #(.nCores(`NTILES))
   host
     (
      .*,
      .req_valid    ( host_req_valid   ),
      .req_ready    ( host_req_ready   ),
      .req_id       ( host_req_id      ),
      .req          ( host_req_data    ),
      .resp_valid   ( host_resp_valid  ),
      .resp_ready   ( host_resp_ready  ),
      .resp_id      ( host_resp_id     ),
      .resp         ( host_resp_data   )
      );
  `else
   assign host_req_ready = 1'b0;
   assign host_resp_id = 0;
   assign host_resp_data = 0;
   assign host_resp_valid = 1'b0;
  `endif // !`ifdef ADD_HOST_IF

   /////////////////////////////////////////////////////////////
   // UART
   nasti_channel
     #(
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `IO_DAT_WIDTH      ))
   io_uart_lite();
   logic                       uart_irq;

  `ifdef ADD_UART
   axi_uart16550_0 uart_i
     (
      .s_axi_aclk      ( clk                    ),
      .s_axi_aresetn   ( rstn                   ),
      .s_axi_araddr    ( io_uart_lite.ar_addr  ),
      .s_axi_arready   ( io_uart_lite.ar_ready ),
      .s_axi_arvalid   ( io_uart_lite.ar_valid ),
      .s_axi_awaddr    ( io_uart_lite.aw_addr  ),
      .s_axi_awready   ( io_uart_lite.aw_ready ),
      .s_axi_awvalid   ( io_uart_lite.aw_valid ),
      .s_axi_bready    ( io_uart_lite.b_ready  ),
      .s_axi_bresp     ( io_uart_lite.b_resp   ),
      .s_axi_bvalid    ( io_uart_lite.b_valid  ),
      .s_axi_rdata     ( io_uart_lite.r_data   ),
      .s_axi_rready    ( io_uart_lite.r_ready  ),
      .s_axi_rresp     ( io_uart_lite.r_resp   ),
      .s_axi_rvalid    ( io_uart_lite.r_valid  ),
      .s_axi_wdata     ( io_uart_lite.w_data   ),
      .s_axi_wready    ( io_uart_lite.w_ready  ),
      .s_axi_wstrb     ( io_uart_lite.w_strb   ),
      .s_axi_wvalid    ( io_uart_lite.w_valid  ),
      .ip2intc_irpt    ( uart_irq               ),
      .freeze          ( 1'b0                   ),
      .rin             ( 1'b1                   ),
      .dcdn            ( 1'b1                   ),
      .dsrn            ( 1'b1                   ),
      .sin             ( rxd                    ),
      .sout            ( txd                    ),
      .ctsn            ( 1'b1                   ),
      .rtsn            (                        )
      );

  `else // !`ifdef ADD_UART

   assign uart_irq = 1'b0;

  `endif // !`ifdef ADD_UART

   /////////////////////////////////////////////////////////////
   // SPI
   nasti_channel
     #(
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `IO_DAT_WIDTH      ))
   io_spi_lite();
   logic                       spi_irq;

  `ifdef ADD_SPI
    axi_quad_spi_0 spi_i
     (
      .ext_spi_clk     ( clk                   ),
      .s_axi_aclk      ( clk                   ),
      .s_axi_aresetn   ( rstn                  ),
      .s_axi_araddr    ( io_spi_lite.ar_addr   ),
      .s_axi_arready   ( io_spi_lite.ar_ready  ),
      .s_axi_arvalid   ( io_spi_lite.ar_valid  ),
      .s_axi_awaddr    ( io_spi_lite.aw_addr   ),
      .s_axi_awready   ( io_spi_lite.aw_ready  ),
      .s_axi_awvalid   ( io_spi_lite.aw_valid  ),
      .s_axi_bready    ( io_spi_lite.b_ready   ),
      .s_axi_bresp     ( io_spi_lite.b_resp    ),
      .s_axi_bvalid    ( io_spi_lite.b_valid   ),
      .s_axi_rdata     ( io_spi_lite.r_data    ),
      .s_axi_rready    ( io_spi_lite.r_ready   ),
      .s_axi_rresp     ( io_spi_lite.r_resp    ),
      .s_axi_rvalid    ( io_spi_lite.r_valid   ),
      .s_axi_wdata     ( io_spi_lite.w_data    ),
      .s_axi_wready    ( io_spi_lite.w_ready   ),
      .s_axi_wstrb     ( io_spi_lite.w_strb    ),
      .s_axi_wvalid    ( io_spi_lite.w_valid   ),
      .io0_i           ( spi_mosi_i            ),
      .io0_o           ( spi_mosi_o            ),
      .io0_t           ( spi_mosi_t            ),
      .io1_i           ( spi_miso_i            ),
      .io1_o           ( spi_miso_o            ),
      .io1_t           ( spi_miso_t            ),
      .sck_i           ( spi_sclk_i            ),
      .sck_o           ( spi_sclk_o            ),
      .sck_t           ( spi_sclk_t            ),
      .ss_i            ( spi_cs_i              ),
      .ss_o            ( spi_cs_o              ),
      .ss_t            ( spi_cs_t              ),
      .ip2intc_irpt    ( spi_irq               )  // polling for now
      );

   // tri-state gate to protect SPI IOs
   assign spi_mosi = !spi_mosi_t ? spi_mosi_o : 1'bz;
   assign spi_mosi_i = 1'b1;    // always in master mode

   assign spi_miso = !spi_miso_t ? spi_miso_o : 1'bz;
   assign spi_miso_i = spi_miso;

   assign spi_sclk = !spi_sclk_t ? spi_sclk_o : 1'bz;
   assign spi_sclk_i = 1'b1;    // always in master mode

   assign spi_cs = !spi_cs_t ? spi_cs_o : 1'bz;
   assign spi_cs_i = 1'b1;;     // always in master mode

  `else // !`ifdef ADD_SPI

   assign spi_irq = 1'b0;

  `endif // !`ifdef ADD_SPI

   /////////////////////////////////////////////////////////////
   // Signals for debug system

   // Debug MAM signals
   logic                              mam_req_valid;
   logic                              mam_req_ready;
   logic                              mam_req_rw;
   logic [`PADDR_WIDTH-1:0]           mam_req_addr;
   logic                              mam_req_burst;
   logic [13:0]                       mam_req_beats;
   logic                              mam_write_valid;
   logic [`MAM_IO_DWIDTH-1:0]         mam_write_data;
   logic [`MAM_IO_DWIDTH/8-1:0]       mam_write_strb;
   logic                              mam_write_ready;
   logic                              mam_read_valid;
   logic [`MAM_IO_DWIDTH-1:0]         mam_read_data;
   logic                              mam_read_ready;

   // Debug ring connections
   dii_flit [1:0]                     debug_ring_start; // starting connector
   logic [1:0]                        debug_ring_start_ready;
   dii_flit [1:0]                     debug_ring_end; // ending connector
   logic [1:0]                        debug_ring_end_ready;

 `ifdef ENABLE_DEBUG
   debug_system
     #(
       .MAM_DATA_WIDTH   ( `MAM_IO_DWIDTH   ),
       .MAM_ADDR_WIDTH   ( `PADDR_WIDTH     )
       )
   u_debug_system
     (
      .*,
      .uart_irq        (uart_irq),
      .uart_ar_addr    ( io_uart_lite.ar_addr   ),
      .uart_ar_ready   ( io_uart_lite.ar_ready  ),
      .uart_ar_valid   ( io_uart_lite.ar_valid  ),
      .uart_aw_addr    ( io_uart_lite.aw_addr   ),
      .uart_aw_ready   ( io_uart_lite.aw_ready  ),
      .uart_aw_valid   ( io_uart_lite.aw_valid  ),
      .uart_b_ready    ( io_uart_lite.b_ready   ),
      .uart_b_resp     ( io_uart_lite.b_resp    ),
      .uart_b_valid    ( io_uart_lite.b_valid   ),
      .uart_r_data     ( io_uart_lite.r_data    ),
      .uart_r_ready    ( io_uart_lite.r_ready   ),
      .uart_r_resp     ( io_uart_lite.r_resp    ),
      .uart_r_valid    ( io_uart_lite.r_valid   ),
      .uart_w_data     ( io_uart_lite.w_data    ),
      .uart_w_ready    ( io_uart_lite.w_ready   ),
      .uart_w_valid    ( io_uart_lite.w_valid   ),
      .rx              ( rxd                    ),
      .tx              ( txd                    ),
      .sys_rst         ( sys_rst                ),
      .cpu_rst         ( cpu_rst                ),
      .ring_out        ( debug_ring_start       ),
      .ring_out_ready  ( debug_ring_start_ready ),
      .ring_in         ( debug_ring_end         ),
      .ring_in_ready   ( debug_ring_end_ready   ),
      .req_valid       ( mam_req_valid          ),
      .req_ready       ( mam_req_ready          ),
      .req_rw          ( mam_req_rw             ),
      .req_addr        ( mam_req_addr           ),
      .req_burst       ( mam_req_burst          ),
      .req_beats       ( mam_req_beats          ),
      .write_valid     ( mam_write_valid        ),
      .write_ready     ( mam_write_ready        ),
      .write_data      ( mam_write_data         ),
      .write_strb      ( mam_write_strb         ),
      .read_valid      ( mam_read_valid         ),
      .read_data       ( mam_read_data          ),
      .read_ready      ( mam_read_ready         )
      );
 `else
   assign sys_rst = rst;
   assign cpu_rst = 1'b0;
 `endif

   /////////////////////////////////////////////////////////////
   // IO crossbar

   // nasti-lite to nasti bridge for io_nasti_mem
   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   io_mem_nasti();

   generate
      if(NUM_OF_IO_DEVICE() > 0) begin
         // output of the IO crossbar
         nasti_channel
           #(
             .N_PORT      ( NUM_OF_IO_DEVICE() + 1),
             .ID_WIDTH    ( `MEM_TAG_WIDTH + 1    ),
             .ADDR_WIDTH  ( `PADDR_WIDTH          ),
             .DATA_WIDTH  ( `IO_DAT_WIDTH         ))
         io_cbo_lite();

         // IO to memory channel
         nasti_channel
           #(
             .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
             .ADDR_WIDTH  ( `PADDR_WIDTH       ),
             .DATA_WIDTH  ( `IO_DAT_WIDTH      ))
         io_mem_lite();

         nasti_channel ios_dmm3(), ios_dmm4(), ios_dmm5(), ios_dmm6(), ios_dmm7(); // dummy channels

         nasti_channel_slicer #(NUM_OF_IO_DEVICE() + 1)
         io_slicer (.s(io_cbo_lite), .m0(io_mem_lite), .m1(io_uart_lite), .m2(io_spi_lite),
                    .m3(ios_dmm3), .m4(ios_dmm4), .m5(ios_dmm5), .m6(ios_dmm6), .m7(ios_dmm7));

         // the io crossbar
         nasti_crossbar
           #(
             .N_INPUT    ( 1                      ),
             .N_OUTPUT   ( NUM_OF_IO_DEVICE() + 1 ),
             .IB_DEPTH   ( 0                      ),
             .OB_DEPTH   ( 1                      ), // some IPs response only with data, which will cause deadlock in nasti_demux (no lock)
             .W_MAX      ( 1                      ),
             .R_MAX      ( 1                      ),
             .ID_WIDTH   ( `MEM_TAG_WIDTH + 1     ),
             .ADDR_WIDTH ( `PADDR_WIDTH           ),
             .DATA_WIDTH ( `IO_DAT_WIDTH          ),
             .LITE_MODE  ( 1                      ),
             .BASE0      ( 0                      ), // memory
             .MASK0      ( 32'h7fffffff           ),
             .BASE1      ( 32'h80000000           ), // UART
             .MASK1      ( 32'h0000ffff           ),
             .BASE2      ( 32'h80010000           ), // SPI
             .MASK2      ( 32'h0000ffff           )
             )
         io_crossbar
           (
            .*,
            .s ( io_lite     ),
            .m ( io_cbo_lite )
            );

         lite_nasti_bridge
           #(
             .WRITE_TRANSACTION  ( 1                  ),
             .READ_TRANSACTION   ( 1                  ),
             .ID_WIDTH           ( `MEM_TAG_WIDTH + 1 ),
             .ADDR_WIDTH         ( `PADDR_WIDTH       ),
             .NASTI_DATA_WIDTH   ( `MEM_DAT_WIDTH     ),
             .LITE_DATA_WIDTH    ( `IO_DAT_WIDTH      )
             )
         io_nasti_bridge
           (
            .*,
            .lite_s  ( io_mem_lite      ),
            .nasti_m ( io_mem_nasti     )
            );

      end else begin // if (NUM_OF_IO_DEVICE() > 0)
         // No IO devices

         lite_nasti_bridge
           #(
             .WRITE_TRANSACTION  ( 1                  ),
             .READ_TRANSACTION   ( 1                  ),
             .ID_WIDTH           ( `MEM_TAG_WIDTH + 1 ),
             .ADDR_WIDTH         ( `PADDR_WIDTH       ),
             .NASTI_DATA_WIDTH   ( `MEM_DAT_WIDTH     ),
             .LITE_DATA_WIDTH    ( `IO_DAT_WIDTH      )
             )
         io_nasti_bridge
           (
            .*,
            .lite_s  ( io_lite          ),
            .nasti_m ( io_mem_nasti     )
            );

      end // else: !if(NUM_OF_IO_DEVICE() > 0)
   endgenerate

   /////////////////////////////////////////////////////////////
   // Memory crossbar
   nasti_channel
     #(
       .N_PORT      ( 2                  ),
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_cbi_nasti();

   nasti_channel mc_dmm2(), mc_dmm3(), mc_dmm4(), mc_dmm5(), mc_dmm6(), mc_dmm7(); // dummy channels
   nasti_channel_combiner #(2)
   mem_combiner (.s0(mem_nasti), .s1(io_mem_nasti),
                 .s2(mc_dmm2), .s3(mc_dmm3), .s4(mc_dmm4), .s5(mc_dmm5), .s6(mc_dmm6), .s7(mc_dmm7),
                 .m(mem_cbi_nasti)
                 );

 `ifdef ADD_BOOT_MEM
   nasti_channel
     #(
       .N_PORT      ( 2                  ),
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_cbo_nasti();

   // slice the channels from memory crossbar
   nasti_channel ms_dmm2(), ms_dmm3(), ms_dmm4(), ms_dmm5(), ms_dmm6(), ms_dmm7(); // dummy channels
   nasti_channel_slicer #(2)
   mem_slicer (.s(mem_cbo_nasti),
               .m0(mem_bram_nasti), .m1(mem_dram_nasti),
               .m2(ms_dmm2), .m3(ms_dmm3), .m4(ms_dmm4), .m5(ms_dmm5), .m6(ms_dmm6), .m7(ms_dmm7));
 `endif

   nasti_crossbar
     #(
       .N_INPUT    ( 2                  ),
       .N_OUTPUT   ( NUM_OF_MEM()       ),
       .IB_DEPTH   ( 2                  ),
       .OB_DEPTH   ( 2                  ),
       .W_MAX      ( 4                  ),
       .R_MAX      ( 4                  ),
       .ID_WIDTH   ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH ( `PADDR_WIDTH       ),
       .DATA_WIDTH ( `MEM_DAT_WIDTH     ),
       .LITE_MODE  ( 0                  ),
       .BASE0      ( 0                  ), // boot ram / behav ddr
       .MASK0      ( NUM_OF_MEM() == 1 ? 32'h7fffffff : 32'h3fffffff ),
       .BASE1      ( 32'h40000000       ), // DDR3 DRAM / behav ddr
       .MASK1      ( 32'h3fffffff       )
       )
   mem_crossbar
     (
      .*,
      .s ( mem_cbi_nasti  ),
 `ifdef ADD_BOOT_MEM
      .m ( mem_cbo_nasti  )
 `else
      .m ( mem_dram_nasti )
 `endif
      );

   /////////////////////////////////////////////////////////////
   // the Rocket chip

   Top Rocket
     (
      .clk                           ( clk                                    ),
      .reset                         ( sys_rst                                ),
      .io_nasti_aw_valid             ( mem_nasti.aw_valid                     ),
      .io_nasti_aw_ready             ( mem_nasti.aw_ready                     ),
      .io_nasti_aw_bits_id           ( mem_nasti_aw_id                        ),
      .io_nasti_aw_bits_addr         ( mem_nasti.aw_addr                      ),
      .io_nasti_aw_bits_len          ( mem_nasti.aw_len                       ),
      .io_nasti_aw_bits_size         ( mem_nasti.aw_size                      ),
      .io_nasti_aw_bits_burst        ( mem_nasti.aw_burst                     ),
      .io_nasti_aw_bits_lock         ( mem_nasti.aw_lock                      ),
      .io_nasti_aw_bits_cache        ( mem_nasti.aw_cache                     ),
      .io_nasti_aw_bits_prot         ( mem_nasti.aw_prot                      ),
      .io_nasti_aw_bits_qos          ( mem_nasti.aw_qos                       ),
      .io_nasti_aw_bits_region       ( mem_nasti.aw_region                    ),
      .io_nasti_aw_bits_user         ( mem_nasti.aw_user                      ),
      .io_nasti_w_valid              ( mem_nasti.w_valid                      ),
      .io_nasti_w_ready              ( mem_nasti.w_ready                      ),
      .io_nasti_w_bits_data          ( mem_nasti.w_data                       ),
      .io_nasti_w_bits_strb          ( mem_nasti.w_strb                       ),
      .io_nasti_w_bits_last          ( mem_nasti.w_last                       ),
      .io_nasti_w_bits_user          ( mem_nasti.w_user                       ),
      .io_nasti_b_valid              ( mem_nasti.b_valid                      ),
      .io_nasti_b_ready              ( mem_nasti.b_ready                      ),
      .io_nasti_b_bits_id            ( mem_nasti.b_id                         ),
      .io_nasti_b_bits_resp          ( mem_nasti.b_resp                       ),
      .io_nasti_b_bits_user          ( mem_nasti.b_user                       ),
      .io_nasti_ar_valid             ( mem_nasti.ar_valid                     ),
      .io_nasti_ar_ready             ( mem_nasti.ar_ready                     ),
      .io_nasti_ar_bits_id           ( mem_nasti_ar_id                        ),
      .io_nasti_ar_bits_addr         ( mem_nasti.ar_addr                      ),
      .io_nasti_ar_bits_len          ( mem_nasti.ar_len                       ),
      .io_nasti_ar_bits_size         ( mem_nasti.ar_size                      ),
      .io_nasti_ar_bits_burst        ( mem_nasti.ar_burst                     ),
      .io_nasti_ar_bits_lock         ( mem_nasti.ar_lock                      ),
      .io_nasti_ar_bits_cache        ( mem_nasti.ar_cache                     ),
      .io_nasti_ar_bits_prot         ( mem_nasti.ar_prot                      ),
      .io_nasti_ar_bits_qos          ( mem_nasti.ar_qos                       ),
      .io_nasti_ar_bits_region       ( mem_nasti.ar_region                    ),
      .io_nasti_ar_bits_user         ( mem_nasti.ar_user                      ),
      .io_nasti_r_valid              ( mem_nasti.r_valid                      ),
      .io_nasti_r_ready              ( mem_nasti.r_ready                      ),
      .io_nasti_r_bits_id            ( mem_nasti.r_id                         ),
      .io_nasti_r_bits_data          ( mem_nasti.r_data                       ),
      .io_nasti_r_bits_resp          ( mem_nasti.r_resp                       ),
      .io_nasti_r_bits_last          ( mem_nasti.r_last                       ),
      .io_nasti_r_bits_user          ( mem_nasti.r_user                       ),
      .io_nasti_lite_aw_valid        ( io_lite.aw_valid                       ),
      .io_nasti_lite_aw_ready        ( io_lite.aw_ready                       ),
      .io_nasti_lite_aw_bits_id      ( io_lite_aw_id                          ),
      .io_nasti_lite_aw_bits_addr    ( io_lite.aw_addr                        ),
      .io_nasti_lite_aw_bits_prot    ( io_lite.aw_prot                        ),
      .io_nasti_lite_aw_bits_qos     ( io_lite.aw_qos                         ),
      .io_nasti_lite_aw_bits_region  ( io_lite.aw_region                      ),
      .io_nasti_lite_aw_bits_user    ( io_lite.aw_user                        ),
      .io_nasti_lite_w_valid         ( io_lite.w_valid                        ),
      .io_nasti_lite_w_ready         ( io_lite.w_ready                        ),
      .io_nasti_lite_w_bits_data     ( io_lite.w_data                         ),
      .io_nasti_lite_w_bits_strb     ( io_lite.w_strb                         ),
      .io_nasti_lite_w_bits_user     ( io_lite.w_user                         ),
      .io_nasti_lite_b_valid         ( io_lite.b_valid                        ),
      .io_nasti_lite_b_ready         ( io_lite.b_ready                        ),
      .io_nasti_lite_b_bits_id       ( io_lite.b_id                           ),
      .io_nasti_lite_b_bits_resp     ( io_lite.b_resp                         ),
      .io_nasti_lite_b_bits_user     ( io_lite.b_user                         ),
      .io_nasti_lite_ar_valid        ( io_lite.ar_valid                       ),
      .io_nasti_lite_ar_ready        ( io_lite.ar_ready                       ),
      .io_nasti_lite_ar_bits_id      ( io_lite_ar_id                          ),
      .io_nasti_lite_ar_bits_addr    ( io_lite.ar_addr                        ),
      .io_nasti_lite_ar_bits_prot    ( io_lite.ar_prot                        ),
      .io_nasti_lite_ar_bits_qos     ( io_lite.ar_qos                         ),
      .io_nasti_lite_ar_bits_region  ( io_lite.ar_region                      ),
      .io_nasti_lite_ar_bits_user    ( io_lite.ar_user                        ),
      .io_nasti_lite_r_valid         ( io_lite.r_valid                        ),
      .io_nasti_lite_r_ready         ( io_lite.r_ready                        ),
      .io_nasti_lite_r_bits_id       ( io_lite.r_id                           ),
      .io_nasti_lite_r_bits_data     ( io_lite.r_data                         ),
      .io_nasti_lite_r_bits_resp     ( io_lite.r_resp                         ),
      .io_nasti_lite_r_bits_user     ( io_lite.r_user                         ),
      .io_host_req_ready             ( host_req_ready                         ),
      .io_host_req_valid             ( host_req_valid                         ),
      .io_host_req_bits_id           ( host_req_id                            ),
      .io_host_req_bits_data         ( host_req_data                          ),
      .io_host_resp_ready            ( host_resp_ready                        ),
      .io_host_resp_valid            ( host_resp_valid                        ),
      .io_host_resp_bits_id          ( host_resp_id                           ),
      .io_host_resp_bits_data        ( host_resp_data                         ),
      .io_interrupt                  ( interrupt                              ),
      .io_debug_net_0_dii_in         ( debug_ring_start[0]                    ),
      .io_debug_net_0_dii_in_ready   ( debug_ring_start_ready[0]              ),
      .io_debug_net_1_dii_in         ( debug_ring_start[1]                    ),
      .io_debug_net_1_dii_in_ready   ( debug_ring_start_ready[1]              ),
      .io_debug_net_0_dii_out        ( debug_ring_end[0]                      ),
      .io_debug_net_0_dii_out_ready  ( debug_ring_end_ready[0]                ),
      .io_debug_net_1_dii_out        ( debug_ring_end[1]                      ),
      .io_debug_net_1_dii_out_ready  ( debug_ring_end_ready[1]                ),
      .io_debug_mam_req_ready        ( mam_req_ready                          ),
      .io_debug_mam_req_valid        ( mam_req_valid                          ),
      .io_debug_mam_req_bits_rw      ( mam_req_rw                             ),
      .io_debug_mam_req_bits_addr    ( mam_req_addr                           ),
      .io_debug_mam_req_bits_burst   ( mam_req_burst                          ),
      .io_debug_mam_req_bits_beats   ( mam_req_beats                          ),
      .io_debug_mam_wdata_ready      ( mam_write_ready                        ),
      .io_debug_mam_wdata_valid      ( mam_write_valid                        ),
      .io_debug_mam_wdata_bits_data  ( mam_write_data                         ),
      .io_debug_mam_wdata_bits_strb  ( mam_write_strb                         ),
      .io_debug_mam_rdata_ready      ( mam_read_ready                         ),
      .io_debug_mam_rdata_valid      ( mam_read_valid                         ),
      .io_debug_mam_rdata_bits_data  ( mam_read_data                          ),
      .io_debug_rst                  ( rst                                    ),
      .io_cpu_rst                    ( cpu_rst                                )
      );

   // interrupt
   assign interrupt = {62'b0, spi_irq, uart_irq};

endmodule // chip_top
