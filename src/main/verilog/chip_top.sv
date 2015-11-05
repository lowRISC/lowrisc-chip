// See LICENSE for license details.

`include "config.vh"
`include "consts.DefaultConfig.vh"

module chip_top
  (
`ifdef FPGA
 `ifdef FPGA_FULL
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
 `endif //  `ifdef FPGA_FULL

   // UART
   input         rxd,
   output        txd,

   // SPI for SD-card
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

   localparam IO_ADDR_WIDTH = `PADDR_WIDTH - 4;

   // internal clock and reset signals
   logic  clk, rst, rstn;

   // the NASTI bus for cached memory
   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_nasti();
   logic [`MEM_TAG_WIDTH : 0] mem_nasti_aw_id, mem_nasti_ar_id;
   assign mem_nasti_aw_id[`MEM_TAG_WIDTH] = 1'b0; // differentiate Memory from IO
   assign mem_nasti_ar_id[`MEM_TAG_WIDTH] = 1'b0;
   assign mem_nasti.aw_id = mem_nasti_aw_id;
   assign mem_nasti.ar_id = mem_nasti_ar_id;

   // the NASTI-Lite bus for IO space
   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `IO_DAT_WIDTH      ))
   io_nasti();
   logic [`MEM_TAG_WIDTH : 0] io_nasti_aw_id, io_nasti_ar_id;
   assign io_nasti_aw_id[`MEM_TAG_WIDTH] = 1'b1; // differentiate Memory from IO
   assign io_nasti_ar_id[`MEM_TAG_WIDTH] = 1'b1;
   assign io_nasti.aw_id = io_nasti_aw_id;
   assign io_nasti.ar_id = io_nasti_ar_id;

   // host interface
   logic  host_req_valid, host_req_ready, host_resp_valid, host_resp_ready;
   logic [$clog2(`NTILES)-1:0] host_req_id, host_resp_id;
   logic [63:0]                host_req_data, host_resp_data;

   // interrupt line
   logic [63:0]                interrupt;

   // the Rocket chip
   Top Rocket
     (
      .clk                           ( clk                                    ),
      .reset                         ( rst                                    ),
      .io_nasti_aw_valid             ( mem_nasti.aw_valid                     ),
      .io_nasti_aw_ready             ( mem_nasti.aw_ready                     ),
      .io_nasti_aw_bits_id           ( mem_nasti_aw_id[`MEM_TAG_WIDTH-1:0]    ),
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
      .io_nasti_ar_bits_id           ( mem_nasti_ar_id[`MEM_TAG_WIDTH-1:0]    ),
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
      .io_nasti_lite_aw_valid        ( io_nasti.aw_valid                      ),
      .io_nasti_lite_aw_ready        ( io_nasti.aw_ready                      ),
      .io_nasti_lite_aw_bits_id      ( io_nasti_aw_id[`MEM_TAG_WIDTH-1:0]     ),
      .io_nasti_lite_aw_bits_addr    ( io_nasti.aw_addr                       ),
      .io_nasti_lite_aw_bits_prot    ( io_nasti.aw_prot                       ),
      .io_nasti_lite_aw_bits_qos     ( io_nasti.aw_qos                        ),
      .io_nasti_lite_aw_bits_region  ( io_nasti.aw_region                     ),
      .io_nasti_lite_aw_bits_user    ( io_nasti.aw_user                       ),
      .io_nasti_lite_w_valid         ( io_nasti.w_valid                       ),
      .io_nasti_lite_w_ready         ( io_nasti.w_ready                       ),
      .io_nasti_lite_w_bits_data     ( io_nasti.w_data                        ),
      .io_nasti_lite_w_bits_strb     ( io_nasti.w_strb                        ),
      .io_nasti_lite_w_bits_user     ( io_nasti.w_user                        ),
      .io_nasti_lite_b_valid         ( io_nasti.b_valid                       ),
      .io_nasti_lite_b_ready         ( io_nasti.b_ready                       ),
      .io_nasti_lite_b_bits_id       ( io_nasti.b_id                          ),
      .io_nasti_lite_b_bits_resp     ( io_nasti.b_resp                        ),
      .io_nasti_lite_b_bits_user     ( io_nasti.b_user                        ),
      .io_nasti_lite_ar_valid        ( io_nasti.ar_valid                      ),
      .io_nasti_lite_ar_ready        ( io_nasti.ar_ready                      ),
      .io_nasti_lite_ar_bits_id      ( io_nasti_ar_id[`MEM_TAG_WIDTH-1:0]     ),
      .io_nasti_lite_ar_bits_addr    ( io_nasti.ar_addr                       ),
      .io_nasti_lite_ar_bits_prot    ( io_nasti.ar_prot                       ),
      .io_nasti_lite_ar_bits_qos     ( io_nasti.ar_qos                        ),
      .io_nasti_lite_ar_bits_region  ( io_nasti.ar_region                     ),
      .io_nasti_lite_ar_bits_user    ( io_nasti.ar_user                       ),
      .io_nasti_lite_r_valid         ( io_nasti.r_valid                       ),
      .io_nasti_lite_r_ready         ( io_nasti.r_ready                       ),
      .io_nasti_lite_r_bits_id       ( io_nasti.r_id                          ),
      .io_nasti_lite_r_bits_data     ( io_nasti.r_data                        ),
      .io_nasti_lite_r_bits_resp     ( io_nasti.r_resp                        ),
      .io_nasti_lite_r_bits_user     ( io_nasti.r_user                        ),
      .io_host_req_ready             ( host_req_ready                         ),
      .io_host_req_valid             ( host_req_valid                         ),
      .io_host_req_bits_id           ( host_req_id                            ),
      .io_host_req_bits_data         ( host_req_data                          ),
      .io_host_resp_ready            ( host_resp_ready                        ),
      .io_host_resp_valid            ( host_resp_valid                        ),
      .io_host_resp_bits_id          ( host_resp_id                           ),
      .io_host_resp_bits_data        ( host_resp_data                         ),
      .io_interrupt                  ( interrupt                              )
      );

   // the memory contoller
`ifdef FPGA

   assign rst = !rstn;

   // output of the IO crossbar
   nasti_channel
     #(
       .N_PORT      ( 3                  ),
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `IO_DAT_WIDTH      ))
   io_nasti_cbo();

   // IO to memory channel
   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `IO_DAT_WIDTH      ))
   io_nasti_mem();

   // IO to UART and SPI
   nasti_channel
     #(
       .ADDR_WIDTH  ( IO_ADDR_WIDTH      ),
       .DATA_WIDTH  ( `IO_DAT_WIDTH      ))
   io_nasti_uart(), io_nasti_spi();

   // the io crossbar
   nasti_crossbar
     #(
       .N_INPUT    ( 1                  ),
       .N_OUTPUT   ( 3                  ),
       .IB_DEPTH   ( 0                  ),
       .OB_DEPTH   ( 1                  ), // some IPs response only with data, which will cause deadlock in nasti_demux (no lock)
       .W_MAX      ( 1                  ),
       .R_MAX      ( 1                  ),
       .ID_WIDTH   ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH ( `PADDR_WIDTH       ),
       .DATA_WIDTH ( `IO_DAT_WIDTH      ),
       .LITE_MODE  ( 1                  ),
       .BASE0      ( 0                  ), // memory
       .MASK0      ( 32'h7fffffff       ),
       .BASE1      ( 32'h80000000       ), // UART
       .MASK1      ( 32'h0000ffff       ),
       .BASE2      ( 32'h80010000       ), // SPI
       .MASK2      ( 32'h0000ffff       )
       )
   io_crossbar
     (
      .*,
      .s ( io_nasti     ),
      .m ( io_nasti_cbo )
      );

   // devide the combined channels
   nasti_channel ios_dmm3(), ios_dmm4(), ios_dmm5(), ios_dmm6(), ios_dmm7(); // dummy channels

   nasti_channel_slicer #(3)
   io_slicer (.s(io_nasti_cbo), .m0(io_nasti_mem), .m1(io_nasti_uart), .m2(io_nasti_spi),
              .m3(ios_dmm3), .m4(ios_dmm4), .m5(ios_dmm5), .m6(ios_dmm6), .m7(ios_dmm7));

   // Xilinx UART IP
   logic                       uart_irq;

   axi_uart16550_0 uart_i
     (
      .s_axi_aclk      ( clk                    ),
      .s_axi_aresetn   ( rstn                   ),
      .s_axi_araddr    ( io_nasti_uart.ar_addr  ),
      .s_axi_arready   ( io_nasti_uart.ar_ready ),
      .s_axi_arvalid   ( io_nasti_uart.ar_valid ),
      .s_axi_awaddr    ( io_nasti_uart.aw_addr  ),
      .s_axi_awready   ( io_nasti_uart.aw_ready ),
      .s_axi_awvalid   ( io_nasti_uart.aw_valid ),
      .s_axi_bready    ( io_nasti_uart.b_ready  ),
      .s_axi_bresp     ( io_nasti_uart.b_resp   ),
      .s_axi_bvalid    ( io_nasti_uart.b_valid  ),
      .s_axi_rdata     ( io_nasti_uart.r_data   ),
      .s_axi_rready    ( io_nasti_uart.r_ready  ),
      .s_axi_rresp     ( io_nasti_uart.r_resp   ),
      .s_axi_rvalid    ( io_nasti_uart.r_valid  ),
      .s_axi_wdata     ( io_nasti_uart.w_data   ),
      .s_axi_wready    ( io_nasti_uart.w_ready  ),
      .s_axi_wstrb     ( io_nasti_uart.w_strb   ),
      .s_axi_wvalid    ( io_nasti_uart.w_valid  ),
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

   // Xilinx SPI IP
   logic                       spi_irq;

   axi_quad_spi_0 spi_i
     (
      .ext_spi_clk     ( clk                   ),
      .s_axi_aclk      ( clk                   ),
      .s_axi_aresetn   ( rstn                  ),
      .s_axi_araddr    ( io_nasti_spi.ar_addr  ),
      .s_axi_arready   ( io_nasti_spi.ar_ready ),
      .s_axi_arvalid   ( io_nasti_spi.ar_valid ),
      .s_axi_awaddr    ( io_nasti_spi.aw_addr  ),
      .s_axi_awready   ( io_nasti_spi.aw_ready ),
      .s_axi_awvalid   ( io_nasti_spi.aw_valid ),
      .s_axi_bready    ( io_nasti_spi.b_ready  ),
      .s_axi_bresp     ( io_nasti_spi.b_resp   ),
      .s_axi_bvalid    ( io_nasti_spi.b_valid  ),
      .s_axi_rdata     ( io_nasti_spi.r_data   ),
      .s_axi_rready    ( io_nasti_spi.r_ready  ),
      .s_axi_rresp     ( io_nasti_spi.r_resp   ),
      .s_axi_rvalid    ( io_nasti_spi.r_valid  ),
      .s_axi_wdata     ( io_nasti_spi.w_data   ),
      .s_axi_wready    ( io_nasti_spi.w_ready  ),
      .s_axi_wstrb     ( io_nasti_spi.w_strb   ),
      .s_axi_wvalid    ( io_nasti_spi.w_valid  ),
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

   // interrupt
   assign interrupt = {62'b0, spi_irq, uart_irq};

   // nasti-lite to nasti bridge for io_nasti_mem
   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   io_nasti_mem_full();

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
      .lite_s  ( io_nasti_mem      ),
      .nasti_m ( io_nasti_mem_full )
      );

   // combine memory requests from mem and IO
   nasti_channel
     #(
       .N_PORT      ( 2                  ),
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_nasti_cbi(), mem_nasti_cbo();

   nasti_channel mc_dmm2(), mc_dmm3(), mc_dmm4(), mc_dmm5(), mc_dmm6(), mc_dmm7(); // dummy channels
   nasti_channel_combiner #(2)
   mem_combiner (.s0(mem_nasti), .s1(io_nasti_mem_full),
                 .s2(mc_dmm2), .s3(mc_dmm3), .s4(mc_dmm4), .s5(mc_dmm5), .s6(mc_dmm6), .s7(mc_dmm7),
                 .m(mem_nasti_cbi)
                 );

   // the io crossbar
   nasti_crossbar
     #(
       .N_INPUT    ( 2                  ),
       .N_OUTPUT   ( 2                  ),
       .IB_DEPTH   ( 2                  ),
       .OB_DEPTH   ( 2                  ),
       .W_MAX      ( 4                  ),
       .R_MAX      ( 4                  ),
       .ID_WIDTH   ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH ( `PADDR_WIDTH       ),
       .DATA_WIDTH ( `MEM_DAT_WIDTH     ),
       .LITE_MODE  ( 0                  ),
       .BASE0      ( 0                  ), // on-FPGA BRAM
       .MASK0      ( 32'h3fffffff       ),
       .BASE1      ( 32'h40000000       ), // DDR3 DRAM
       .MASK1      ( 32'h3fffffff       )
       )
   mem_crossbar
     (
      .*,
      .s ( mem_nasti_cbi ),
      .m ( mem_nasti_cbo )
      );

   // channel for BRAM and DRAM
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
   mem_nasti_bram();

   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( DRAM_ADDR_WIDTH    ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_nasti_dram();
   
   // slice the channels from memory crossbar
   nasti_channel ms_dmm2(), ms_dmm3(), ms_dmm4(), ms_dmm5(), ms_dmm6(), ms_dmm7(); // dummy channels
   nasti_channel_slicer #(2)
   mem_slicer (.s(mem_nasti_cbo),
               .m0(mem_nasti_bram), .m1(mem_nasti_dram),
               .m2(ms_dmm2), .m3(ms_dmm3), .m4(ms_dmm4), .m5(ms_dmm5), .m6(ms_dmm6), .m7(ms_dmm7));

   // BRAM controller
   logic ram_clk, ram_rst, ram_en;
   logic [MEM_DATA_WIDTH/8-1:0] ram_we;
   logic [BRAM_ADDR_WIDTH-1:0] ram_addr;
   logic [MEM_DATA_WIDTH-1:0] ram_wrdata, ram_rddata;

   axi_bram_ctrl_0 BramCtl
     (
      .s_axi_aclk      ( clk                     ),
      .s_axi_aresetn   ( rstn                    ),
      .s_axi_awid      ( mem_nasti_bram.aw_id    ),
      .s_axi_awaddr    ( mem_nasti_bram.aw_addr  ),
      .s_axi_awlen     ( mem_nasti_bram.aw_len   ),
      .s_axi_awsize    ( mem_nasti_bram.aw_size  ),
      .s_axi_awburst   ( mem_nasti_bram.aw_burst ),
      .s_axi_awlock    ( mem_nasti_bram.aw_lock  ),
      .s_axi_awcache   ( mem_nasti_bram.aw_cache ),
      .s_axi_awprot    ( mem_nasti_bram.aw_prot  ),
      .s_axi_awvalid   ( mem_nasti_bram.aw_valid ),
      .s_axi_awready   ( mem_nasti_bram.aw_ready ),
      .s_axi_wdata     ( mem_nasti_bram.w_data   ),
      .s_axi_wstrb     ( mem_nasti_bram.w_strb   ),
      .s_axi_wlast     ( mem_nasti_bram.w_last   ),
      .s_axi_wvalid    ( mem_nasti_bram.w_valid  ),
      .s_axi_wready    ( mem_nasti_bram.w_ready  ),
      .s_axi_bid       ( mem_nasti_bram.b_id     ),
      .s_axi_bresp     ( mem_nasti_bram.b_resp   ),
      .s_axi_bvalid    ( mem_nasti_bram.b_valid  ),
      .s_axi_bready    ( mem_nasti_bram.b_ready  ),
      .s_axi_arid      ( mem_nasti_bram.ar_id    ),
      .s_axi_araddr    ( mem_nasti_bram.ar_addr  ),
      .s_axi_arlen     ( mem_nasti_bram.ar_len   ),
      .s_axi_arsize    ( mem_nasti_bram.ar_size  ),
      .s_axi_arburst   ( mem_nasti_bram.ar_burst ),
      .s_axi_arlock    ( mem_nasti_bram.ar_lock  ),
      .s_axi_arcache   ( mem_nasti_bram.ar_cache ),
      .s_axi_arprot    ( mem_nasti_bram.ar_prot  ),
      .s_axi_arvalid   ( mem_nasti_bram.ar_valid ),
      .s_axi_arready   ( mem_nasti_bram.ar_ready ),
      .s_axi_rid       ( mem_nasti_bram.r_id     ),
      .s_axi_rdata     ( mem_nasti_bram.r_data   ),
      .s_axi_rresp     ( mem_nasti_bram.r_resp   ),
      .s_axi_rlast     ( mem_nasti_bram.r_last   ),
      .s_axi_rvalid    ( mem_nasti_bram.r_valid  ),
      .s_axi_rready    ( mem_nasti_bram.r_ready  ),
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

 `ifdef FPGA_FULL

   // the NASTI bus for off-FPGA DRAM, converted to High frequency
   nasti_channel   
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( DRAM_ADDR_WIDTH    ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_nasti_mig();

   // MIG clock
   logic mig_clk, mig_rst, mig_rstn;
   always_ff @(posedge mig_clk)
     mig_rstn <= !mig_rst;

   // clock converter
   axi_clock_converter_0 clk_conv
     (
      .s_axi_aclk           ( clk                      ),
      .s_axi_aresetn        ( rstn                     ),
      .s_axi_awid           ( mem_nasti_dram.aw_id     ),
      .s_axi_awaddr         ( mem_nasti_dram.aw_addr   ),
      .s_axi_awlen          ( mem_nasti_dram.aw_len    ),
      .s_axi_awsize         ( mem_nasti_dram.aw_size   ),
      .s_axi_awburst        ( mem_nasti_dram.aw_burst  ),
      .s_axi_awlock         ( 1'b0                     ), // not supported in AXI4
      .s_axi_awcache        ( mem_nasti_dram.aw_cache  ),
      .s_axi_awprot         ( mem_nasti_dram.aw_prot   ),
      .s_axi_awqos          ( mem_nasti_dram.aw_qos    ),
      .s_axi_awregion       ( mem_nasti_dram.aw_region ),
      .s_axi_awvalid        ( mem_nasti_dram.aw_valid  ),
      .s_axi_awready        ( mem_nasti_dram.aw_ready  ),
      .s_axi_wdata          ( mem_nasti_dram.w_data    ),
      .s_axi_wstrb          ( mem_nasti_dram.w_strb    ),
      .s_axi_wlast          ( mem_nasti_dram.w_last    ),
      .s_axi_wvalid         ( mem_nasti_dram.w_valid   ),
      .s_axi_wready         ( mem_nasti_dram.w_ready   ),
      .s_axi_bid            ( mem_nasti_dram.b_id      ),
      .s_axi_bresp          ( mem_nasti_dram.b_resp    ),
      .s_axi_bvalid         ( mem_nasti_dram.b_valid   ),
      .s_axi_bready         ( mem_nasti_dram.b_ready   ),
      .s_axi_arid           ( mem_nasti_dram.ar_id     ),
      .s_axi_araddr         ( mem_nasti_dram.ar_addr   ),
      .s_axi_arlen          ( mem_nasti_dram.ar_len    ),
      .s_axi_arsize         ( mem_nasti_dram.ar_size   ),
      .s_axi_arburst        ( mem_nasti_dram.ar_burst  ),
      .s_axi_arlock         ( 1'b0                     ), // not supported in AXI4
      .s_axi_arcache        ( mem_nasti_dram.ar_cache  ),
      .s_axi_arprot         ( mem_nasti_dram.ar_prot   ),
      .s_axi_arqos          ( mem_nasti_dram.ar_qos    ),
      .s_axi_arregion       ( mem_nasti_dram.ar_region ),
      .s_axi_arvalid        ( mem_nasti_dram.ar_valid  ),
      .s_axi_arready        ( mem_nasti_dram.ar_ready  ),
      .s_axi_rid            ( mem_nasti_dram.r_id      ),
      .s_axi_rdata          ( mem_nasti_dram.r_data    ),
      .s_axi_rresp          ( mem_nasti_dram.r_resp    ),
      .s_axi_rlast          ( mem_nasti_dram.r_last    ),
      .s_axi_rvalid         ( mem_nasti_dram.r_valid   ),
      .s_axi_rready         ( mem_nasti_dram.r_ready   ),
      .m_axi_aclk           ( mig_clk                  ),
      .m_axi_aresetn        ( mig_rstn                 ),
      .m_axi_awid           ( mem_nasti_mig.aw_id      ),
      .m_axi_awaddr         ( mem_nasti_mig.aw_addr    ),
      .m_axi_awlen          ( mem_nasti_mig.aw_len     ),
      .m_axi_awsize         ( mem_nasti_mig.aw_size    ),
      .m_axi_awburst        ( mem_nasti_mig.aw_burst   ),
      .m_axi_awlock         (                          ), // not supported in AXI4
      .m_axi_awcache        ( mem_nasti_mig.aw_cache   ),
      .m_axi_awprot         ( mem_nasti_mig.aw_prot    ),
      .m_axi_awqos          ( mem_nasti_mig.aw_qos     ),
      .m_axi_awregion       ( mem_nasti_mig.aw_region  ),
      .m_axi_awvalid        ( mem_nasti_mig.aw_valid   ),
      .m_axi_awready        ( mem_nasti_mig.aw_ready   ),
      .m_axi_wdata          ( mem_nasti_mig.w_data     ),
      .m_axi_wstrb          ( mem_nasti_mig.w_strb     ),
      .m_axi_wlast          ( mem_nasti_mig.w_last     ),
      .m_axi_wvalid         ( mem_nasti_mig.w_valid    ),
      .m_axi_wready         ( mem_nasti_mig.w_ready    ),
      .m_axi_bid            ( mem_nasti_mig.b_id       ),
      .m_axi_bresp          ( mem_nasti_mig.b_resp     ),
      .m_axi_bvalid         ( mem_nasti_mig.b_valid    ),
      .m_axi_bready         ( mem_nasti_mig.b_ready    ),
      .m_axi_arid           ( mem_nasti_mig.ar_id      ),
      .m_axi_araddr         ( mem_nasti_mig.ar_addr    ),
      .m_axi_arlen          ( mem_nasti_mig.ar_len     ),
      .m_axi_arsize         ( mem_nasti_mig.ar_size    ),
      .m_axi_arburst        ( mem_nasti_mig.ar_burst   ),
      .m_axi_arlock         (                          ), // not supported in AXI4
      .m_axi_arcache        ( mem_nasti_mig.ar_cache   ),
      .m_axi_arprot         ( mem_nasti_mig.ar_prot    ),
      .m_axi_arqos          ( mem_nasti_mig.ar_qos     ),
      .m_axi_arregion       ( mem_nasti_mig.ar_region  ),
      .m_axi_arvalid        ( mem_nasti_mig.ar_valid   ),
      .m_axi_arready        ( mem_nasti_mig.ar_ready   ),
      .m_axi_rid            ( mem_nasti_mig.r_id       ),
      .m_axi_rdata          ( mem_nasti_mig.r_data     ),
      .m_axi_rresp          ( mem_nasti_mig.r_resp     ),
      .m_axi_rlast          ( mem_nasti_mig.r_last     ),
      .m_axi_rvalid         ( mem_nasti_mig.r_valid    ),
      .m_axi_rready         ( mem_nasti_mig.r_ready    )
      );

   // DRAM controller
   mig_7series_0 dram_ctl
     (
      .sys_clk_p            ( clk_p                  ),
      .sys_clk_n            ( clk_n                  ),
      .sys_rst              ( rst_top                ),
      .ddr3_dq              ( ddr3_dq                ),
      .ddr3_dqs_n           ( ddr3_dqs_n             ),
      .ddr3_dqs_p           ( ddr3_dqs_p             ),
      .ddr3_addr            ( ddr3_addr              ),
      .ddr3_ba              ( ddr3_ba                ),
      .ddr3_ras_n           ( ddr3_ras_n             ),
      .ddr3_cas_n           ( ddr3_cas_n             ),
      .ddr3_we_n            ( ddr3_we_n              ),
      .ddr3_reset_n         ( ddr3_reset_n           ),
      .ddr3_ck_p            ( ddr3_ck_p              ),
      .ddr3_ck_n            ( ddr3_ck_n              ),
      .ddr3_cke             ( ddr3_cke               ),
      .ddr3_cs_n            ( ddr3_cs_n              ),
      .ddr3_dm              ( ddr3_dm                ),
      .ddr3_odt             ( ddr3_odt               ),
      .ui_clk               ( mig_clk                ),
      .ui_clk_sync_rst      ( mig_rst                ),
      .ui_addn_clk_0        ( clk                    ),
      .mmcm_locked          ( rstn                   ),
      .aresetn              ( rstn                   ), // AXI reset
      .app_sr_req           ( 1'b0                   ),
      .app_ref_req          ( 1'b0                   ),
      .app_zq_req           ( 1'b0                   ),
      .s_axi_awid           ( mem_nasti_mig.aw_id    ),
      .s_axi_awaddr         ( mem_nasti_mig.aw_addr  ),
      .s_axi_awlen          ( mem_nasti_mig.aw_len   ),
      .s_axi_awsize         ( mem_nasti_mig.aw_size  ),
      .s_axi_awburst        ( mem_nasti_mig.aw_burst ),
      .s_axi_awlock         ( 1'b0                   ), // not supported in AXI4
      .s_axi_awcache        ( mem_nasti_mig.aw_cache ),
      .s_axi_awprot         ( mem_nasti_mig.aw_prot  ),
      .s_axi_awqos          ( mem_nasti_mig.aw_qos   ),
      .s_axi_awvalid        ( mem_nasti_mig.aw_valid ),
      .s_axi_awready        ( mem_nasti_mig.aw_ready ),
      .s_axi_wdata          ( mem_nasti_mig.w_data   ),
      .s_axi_wstrb          ( mem_nasti_mig.w_strb   ),
      .s_axi_wlast          ( mem_nasti_mig.w_last   ),
      .s_axi_wvalid         ( mem_nasti_mig.w_valid  ),
      .s_axi_wready         ( mem_nasti_mig.w_ready  ),
      .s_axi_bid            ( mem_nasti_mig.b_id     ),
      .s_axi_bresp          ( mem_nasti_mig.b_resp   ),
      .s_axi_bvalid         ( mem_nasti_mig.b_valid  ),
      .s_axi_bready         ( mem_nasti_mig.b_ready  ),
      .s_axi_arid           ( mem_nasti_mig.ar_id    ),
      .s_axi_araddr         ( mem_nasti_mig.ar_addr  ),
      .s_axi_arlen          ( mem_nasti_mig.ar_len   ),
      .s_axi_arsize         ( mem_nasti_mig.ar_size  ),
      .s_axi_arburst        ( mem_nasti_mig.ar_burst ),
      .s_axi_arlock         ( 1'b0                   ), // not supported in AXI4
      .s_axi_arcache        ( mem_nasti_mig.ar_cache ),
      .s_axi_arprot         ( mem_nasti_mig.ar_prot  ),
      .s_axi_arqos          ( mem_nasti_mig.ar_qos   ),
      .s_axi_arvalid        ( mem_nasti_mig.ar_valid ),
      .s_axi_arready        ( mem_nasti_mig.ar_ready ),
      .s_axi_rid            ( mem_nasti_mig.r_id     ),
      .s_axi_rdata          ( mem_nasti_mig.r_data   ),
      .s_axi_rresp          ( mem_nasti_mig.r_resp   ),
      .s_axi_rlast          ( mem_nasti_mig.r_last   ),
      .s_axi_rvalid         ( mem_nasti_mig.r_valid  ),
      .s_axi_rready         ( mem_nasti_mig.r_ready  )
      );

   // host interface is not used
   assign host_req_ready = 1'b0;
   assign host_resp_id = 0;
   assign host_resp_data = 0;
   assign host_resp_valid = 1'b0;

 `else // !`ifdef FPGA_FULL

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
      .nasti         ( mem_nasti_dram   )
      );

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

 `endif // !`ifdef FPGA_FULL

`elsif SIMULATION

   assign clk = clk_p;
   assign rst = rst_top;
   assign rstn = !rst_top;
   assign interrupt = 0;

   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   io_nasti_full(), ram_nasti();

   nasti_channel
     #(
       .N_PORT      ( 2                  ),
       .ID_WIDTH    ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH  ( `PADDR_WIDTH       ),
       .DATA_WIDTH  ( `MEM_DAT_WIDTH     ))
   mem_io_nasti();

   // convert nasti-lite io_nasti to full nasti io_nasti_full
   lite_nasti_bridge
     #(
       .ID_WIDTH          ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH        ( `PADDR_WIDTH       ),
       .NASTI_DATA_WIDTH  ( `MEM_DAT_WIDTH     ),
       .LITE_DATA_WIDTH   ( `IO_DAT_WIDTH      )
       )
   io_nasti_conv
     (
      .*,
      .lite_s  ( io_nasti      ),
      .nasti_m ( io_nasti_full )
      );

   // combine memory and io nasti channels
   nasti_channel dummy2(), dummy3(), dummy4(), dummy5(), dummy6(), dummy7();

   nasti_channel_combiner #(2)
   mem_io_combiner
     (
      .*,
      .s0  ( mem_nasti     ),
      .s1  ( io_nasti_full ),
      .s2  ( dummy2        ),
      .s3  ( dummy3        ),
      .s4  ( dummy4        ),
      .s5  ( dummy5        ),
      .s6  ( dummy6        ),
      .s7  ( dummy7        ),
      .m   ( mem_io_nasti  )
      );

   // crossbar to merge memory and IO to the behaviour dram
   nasti_crossbar
     #(
       .N_INPUT    ( 2                  ),
       .N_OUTPUT   ( 1                  ),
       .IB_DEPTH   ( 3                  ),
       .OB_DEPTH   ( 3                  ),
       .W_MAX      ( 4                  ),
       .R_MAX      ( 4                  ),
       .ID_WIDTH   ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH ( `PADDR_WIDTH       ),
       .DATA_WIDTH ( `MEM_DAT_WIDTH     ),
       .BASE0      ( 0                  ),
       .MASK0      ( 32'hffffffff       )
       )
   mem_crossbar
     (
      .*,
      .s ( mem_io_nasti  ),
      .m ( ram_nasti     )
      );

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
      .nasti         ( ram_nasti        )
      );

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

`endif

endmodule // chip_top
