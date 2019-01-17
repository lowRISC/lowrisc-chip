// See LICENSE for license details.

`include "consts.vh"
`include "config.vh"

module chip_top
  (
   // DDR3 RAM
   inout wire [31:0]  ddr_dq,
   inout wire [3:0]   ddr_dqs_n,
   inout wire [3:0]   ddr_dqs_p,
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
   output [3:0]  ddr_dm,
   output        ddr_odt,

   // Simple UART interface
   input wire         rxd,
   output wire       txd,

   // 4-bit full SD interface
   inout wire         sd_sclk,
   input wire         sd_detect,
   inout wire [3:0]   sd_dat,
   inout wire         sd_cmd,
   output wire        sd_reset,

   // LED and DIP switch
   output wire  [7:0] o_led,
   input wire   [7:0] i_dip,

   // push button array
   input wire         GPIO_SW_C,
   input wire         GPIO_SW_W,
   input wire         GPIO_SW_E,
   input wire         GPIO_SW_N,
   input wire         GPIO_SW_S,

   //keyboard
   inout wire         PS2_CLK,
   inout wire         PS2_DATA,

  // display
   output wire       VGA_HS_O,
   output wire       VGA_VS_O,
   output wire [3:0]  VGA_RED_O,
   output wire [3:0]  VGA_BLUE_O,
   output wire [3:0]  VGA_GREEN_O,

   /*
    * Ethernet: 1000BASE-T RGMII
    */
   input  wire       phy_rx_clk,
   input  wire [3:0] phy_rxd,
   input  wire       phy_rx_ctl,
   output wire       phy_tx_clk,
   output wire [3:0] phy_txd,
   output wire       phy_tx_ctl,
   output wire       phy_reset_n,
   input  wire       phy_int_n,
   input  wire       phy_pme_n,
   
   // clock and reset
   input wire         clk_p,
   input wire         clk_n,
   input wire         rst_top
   );

   genvar        i;

   // internal clock and reset signals
   logic  clk, rst, rstn;
   assign rst = !rstn;

   // Debug controlled reset of the Rocket system
   logic  sys_rst;
   // Interrupts
   logic spi_irq, sd_irq, eth_irq, uart_irq;
   // Miscellaneous
   logic TDO_driven;
   /////////////////////////////////////////////////////////////
   // NASTI/Lite on-chip interconnects

   // Rocket memory nasti bus
   nasti_channel
     #(
       .ID_WIDTH    ( `MEM_ID_WIDTH   ),
       .ADDR_WIDTH  ( `MEM_ADDR_WIDTH ),
       .DATA_WIDTH  ( `MEM_DATA_WIDTH ))
   mem_nasti();
wire io_emdio_i, phy_emdio_o, phy_emdio_t, clk_rgmii, clk_rgmii_quad, clk_locked, clk_locked_wiz;
reg phy_emdio_i, io_emdio_o, io_emdio_t;
logic mig_sys_clk, clk_pixel;

   // the NASTI bus for off-FPGA DRAM, converted to High frequency
   nasti_channel   
     #(
       .ID_WIDTH    ( `MEM_ID_WIDTH   ),
       .ADDR_WIDTH  ( `MEM_ADDR_WIDTH ),
       .DATA_WIDTH  ( `MEM_DATA_WIDTH ))
   mem_mig_nasti();

   // MIG clock
   logic mig_ui_clk, mig_ui_rst, mig_ui_rstn;
   assign mig_ui_rstn = !mig_ui_rst;

`define UBAUD_DEFAULT 108

   // clock converter
   axi_clock_converter_0 clk_conv
     (
      .s_axi_aclk           ( clk                      ),
      .s_axi_aresetn        ( rstn                     ),
      .s_axi_awid           ( mem_nasti.aw_id          ),
      .s_axi_awaddr         ( mem_nasti.aw_addr        ),
      .s_axi_awlen          ( mem_nasti.aw_len         ),
      .s_axi_awsize         ( mem_nasti.aw_size        ),
      .s_axi_awburst        ( mem_nasti.aw_burst       ),
      .s_axi_awlock         ( 1'b0                     ), // not supported in AXI4
      .s_axi_awcache        ( mem_nasti.aw_cache       ),
      .s_axi_awprot         ( mem_nasti.aw_prot        ),
      .s_axi_awqos          ( mem_nasti.aw_qos         ),
      .s_axi_awregion       ( 4'b0                     ), // not supported in AXI4
      .s_axi_awvalid        ( mem_nasti.aw_valid       ),
      .s_axi_awready        ( mem_nasti.aw_ready       ),
      .s_axi_wdata          ( mem_nasti.w_data         ),
      .s_axi_wstrb          ( mem_nasti.w_strb         ),
      .s_axi_wlast          ( mem_nasti.w_last         ),
      .s_axi_wvalid         ( mem_nasti.w_valid        ),
      .s_axi_wready         ( mem_nasti.w_ready        ),
      .s_axi_bid            ( mem_nasti.b_id           ),
      .s_axi_bresp          ( mem_nasti.b_resp         ),
      .s_axi_bvalid         ( mem_nasti.b_valid        ),
      .s_axi_bready         ( mem_nasti.b_ready        ),
      .s_axi_arid           ( mem_nasti.ar_id          ),
      .s_axi_araddr         ( mem_nasti.ar_addr        ),
      .s_axi_arlen          ( mem_nasti.ar_len         ),
      .s_axi_arsize         ( mem_nasti.ar_size        ),
      .s_axi_arburst        ( mem_nasti.ar_burst       ),
      .s_axi_arlock         ( 1'b0                     ), // not supported in AXI4
      .s_axi_arcache        ( mem_nasti.ar_cache       ),
      .s_axi_arprot         ( mem_nasti.ar_prot        ),
      .s_axi_arqos          ( mem_nasti.ar_qos         ),
      .s_axi_arregion       ( 4'b0                     ), // not supported in AXI4
      .s_axi_arvalid        ( mem_nasti.ar_valid       ),
      .s_axi_arready        ( mem_nasti.ar_ready       ),
      .s_axi_rid            ( mem_nasti.r_id           ),
      .s_axi_rdata          ( mem_nasti.r_data         ),
      .s_axi_rresp          ( mem_nasti.r_resp         ),
      .s_axi_rlast          ( mem_nasti.r_last         ),
      .s_axi_rvalid         ( mem_nasti.r_valid        ),
      .s_axi_rready         ( mem_nasti.r_ready        ),
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

   clk_wiz_0 clk_gen
     (
      .clk_in1        ( mig_ui_clk     ), // 100 MHz onboard
      .clk_out1       ( mig_sys_clk    ), // 200 MHz
      .clk_cpu        ( clk            ), // 50 MHz
      .clk_pixel      ( clk_pixel      ), // 100 MHz
      .clk_rgmii      ( clk_rgmii      ), // 125 MHz rgmii
      .clk_rgmii_quad ( clk_rgmii_quad ), // 125 MHz rgmii quad
      .reset          ( mig_ui_rst     ),
      .locked         ( clk_locked_wiz )
      );
   assign clk_locked = clk_locked_wiz & rst_top;
   assign sys_rst = ~rstn;
      
   // DRAM controller
   mig_7series_0 dram_ctl
     (
      .sys_clk_p            ( clk_p                  ),
      .sys_clk_n            ( clk_n                  ),
      .sys_rst              ( rst_top                ),
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

   /////////////////////////////////////////////////////////////
   // IO space buses

   nasti_channel
     #(
       .ID_WIDTH    ( `MMIO_MASTER_ID_WIDTH   ),
       .ADDR_WIDTH  ( `MMIO_MASTER_ADDR_WIDTH ),
       .DATA_WIDTH  ( `MMIO_MASTER_DATA_WIDTH ))
   mmio_master_nasti();

   nasti_channel
     #(
       .ID_WIDTH    ( `MMIO_SLAVE_ID_WIDTH   ),
       .ADDR_WIDTH  ( `MMIO_SLAVE_ADDR_WIDTH ),
       .DATA_WIDTH  ( `MMIO_SLAVE_DATA_WIDTH ))
   io_slave_nasti();      // IO nasti interface to Rocket

   // currently the slave port is not used
   assign io_slave_nasti.aw_valid = 'b0;
   assign io_slave_nasti.w_valid  = 'b0;
   assign io_slave_nasti.b_ready  = 'b0;
   assign io_slave_nasti.ar_valid = 'b0;
   assign io_slave_nasti.r_ready  = 'b0;

   /////////////////////////////////////////////////////////////
   // On-chip Block RAM

   localparam BRAM_SIZE          = 16;        // 2^16 -> 64 KB
   localparam BRAM_WIDTH         = 128;       // always 128-bit wide
   localparam BRAM_LINE          = 2 ** BRAM_SIZE / (BRAM_WIDTH/8);
   localparam BRAM_OFFSET_BITS   = $clog2(`LOWRISC_IO_DAT_WIDTH/8);
   localparam BRAM_ADDR_LSB_BITS = $clog2(BRAM_WIDTH / `LOWRISC_IO_DAT_WIDTH);
   localparam BRAM_ADDR_BLK_BITS = BRAM_SIZE - BRAM_ADDR_LSB_BITS - BRAM_OFFSET_BITS;

   initial assert (BRAM_OFFSET_BITS < 7) else $fatal(1, "Do not support BRAM AXI width > 64-bit!");

   // BRAM controller
   logic ram_clk, ram_rst, ram_en;
   logic [7:0] ram_we;
   logic [15:0] ram_addr;
   logic [63:0]   ram_wrdata, ram_rddata;

   logic [30:0] bram_ar_addr, bram_aw_addr;

   assign bram_ar_addr = mmio_master_nasti.ar_addr ;
   assign bram_aw_addr = mmio_master_nasti.aw_addr ;
   
   reg   [BRAM_WIDTH-1:0]         ram [0 : BRAM_LINE-1];
   logic [BRAM_ADDR_BLK_BITS-1:0] ram_block_addr, ram_block_addr_delay;
   logic [BRAM_ADDR_LSB_BITS-1:0] ram_lsb_addr, ram_lsb_addr_delay;
   logic [BRAM_WIDTH/8-1:0]       ram_we_full;
   logic [BRAM_WIDTH-1:0]         ram_wrdata_full, ram_rddata_full;
   int                            ram_rddata_shift, ram_we_shift;

   assign ram_block_addr = ram_addr >> BRAM_ADDR_LSB_BITS + BRAM_OFFSET_BITS;
   assign ram_lsb_addr = ram_addr >> BRAM_OFFSET_BITS;
   assign ram_we_shift = ram_lsb_addr << BRAM_OFFSET_BITS; // avoid ISim error
   assign ram_we_full = ram_we << ram_we_shift;
   assign ram_wrdata_full = {(BRAM_WIDTH / `LOWRISC_IO_DAT_WIDTH){ram_wrdata}};

   always @(posedge ram_clk)
    begin
     if(ram_en) begin
        ram_block_addr_delay <= ram_block_addr;
        ram_lsb_addr_delay <= ram_lsb_addr;
        foreach (ram_we_full[i])
          if(ram_we_full[i]) ram[ram_block_addr][i*8 +:8] <= ram_wrdata_full[i*8 +: 8];
     end
    end

   assign ram_rddata_full = ram[ram_block_addr_delay];
   assign ram_rddata_shift = ram_lsb_addr_delay << (BRAM_OFFSET_BITS + 3); // avoid ISim error
   assign ram_rddata = ram_rddata_full >> ram_rddata_shift;

   initial $readmemh("boot.mem", ram);

   assign spi_irq = 1'b0;

   /////////////////////////////////////////////////////////////
   // Human interface and miscellaneous devices

   wire                        hid_rst, hid_clk, hid_en;
   wire [7:0]                  hid_we;
   wire [17:0]                 hid_addr;
   wire [63:0]                 hid_wrdata,  hid_rddata;
   logic [30:0]                hid_ar_addr, hid_aw_addr;
   logic [1:0] eth_txd;
   logic eth_rstn, eth_refclk, eth_txen;

   axi_bram_ctrl_dummy BramCtl
     (
      .s_axi_aclk      ( clk                        ),
      .s_axi_aresetn   ( rstn                       ),
      .s_axi_arid      ( mmio_master_nasti.ar_id    ),
      .s_axi_araddr    ( bram_ar_addr[17:0]         ),
      .s_axi_arlen     ( mmio_master_nasti.ar_len   ),
      .s_axi_arsize    ( mmio_master_nasti.ar_size  ),
      .s_axi_arburst   ( mmio_master_nasti.ar_burst ),
      .s_axi_arlock    ( mmio_master_nasti.ar_lock  ),
      .s_axi_arcache   ( mmio_master_nasti.ar_cache ),
      .s_axi_arprot    ( mmio_master_nasti.ar_prot  ),
      .s_axi_arready   ( mmio_master_nasti.ar_ready ),
      .s_axi_arvalid   ( mmio_master_nasti.ar_valid ),
      .s_axi_rid       ( mmio_master_nasti.r_id     ),
      .s_axi_rdata     ( mmio_master_nasti.r_data   ),
      .s_axi_rresp     ( mmio_master_nasti.r_resp   ),
      .s_axi_rlast     ( mmio_master_nasti.r_last   ),
      .s_axi_rready    ( mmio_master_nasti.r_ready  ),
      .s_axi_rvalid    ( mmio_master_nasti.r_valid  ),
      .s_axi_awid      ( mmio_master_nasti.aw_id    ),
      .s_axi_awaddr    ( bram_aw_addr[17:0]         ),
      .s_axi_awlen     ( mmio_master_nasti.aw_len   ),
      .s_axi_awsize    ( mmio_master_nasti.aw_size  ),
      .s_axi_awburst   ( mmio_master_nasti.aw_burst ),
      .s_axi_awlock    ( mmio_master_nasti.aw_lock  ),
      .s_axi_awcache   ( mmio_master_nasti.aw_cache ),
      .s_axi_awprot    ( mmio_master_nasti.aw_prot  ),
      .s_axi_awready   ( mmio_master_nasti.aw_ready ),
      .s_axi_awvalid   ( mmio_master_nasti.aw_valid ),
      .s_axi_wdata     ( mmio_master_nasti.w_data   ),
      .s_axi_wstrb     ( mmio_master_nasti.w_strb   ),
      .s_axi_wlast     ( mmio_master_nasti.w_last   ),
      .s_axi_wready    ( mmio_master_nasti.w_ready  ),
      .s_axi_wvalid    ( mmio_master_nasti.w_valid  ),
      .s_axi_bid       ( mmio_master_nasti.b_id     ),
      .s_axi_bresp     ( mmio_master_nasti.b_resp   ),
      .s_axi_bready    ( mmio_master_nasti.b_ready  ),
      .s_axi_bvalid    ( mmio_master_nasti.b_valid  ),
      .bram_rst_a      ( hid_rst                   ),
      .bram_clk_a      ( hid_clk                   ),
      .bram_en_a       ( hid_en                    ),
      .bram_we_a       ( hid_we                    ),
      .bram_addr_a     ( hid_addr                  ),
      .bram_wrdata_a   ( hid_wrdata                ),
      .bram_rddata_a   ( hid_rddata                )
      );
  

   periph_soc #(.UBAUD_DEFAULT(`UBAUD_DEFAULT)) psoc
     (
      .msoc_clk   ( clk             ),
      .sd_sclk    ( sd_sclk         ),
      .sd_detect  ( sd_detect       ),
      .sd_dat     ( sd_dat          ),
      .sd_cmd     ( sd_cmd          ),
      .sd_irq     ( sd_irq          ),
      .from_dip   ( i_dip           ),
      .to_led     ( o_led           ),
      .rstn       ( clk_locked      ),
      .clk_200MHz ( mig_sys_clk     ),
      .pxl_clk    ( clk_pixel       ),
      .uart_rx    ( rxd             ),
      .uart_tx    ( txd             ),
      .clk_rgmii  ( clk_rgmii       ),
      .clk_rgmii_quad ( clk_rgmii_quad ),
    // RGMII ethernet PHY connections
      .phy_rx_clk,
      .phy_rxd,
      .phy_rx_ctl,
      .phy_tx_clk,
      .phy_txd,
      .phy_tx_ctl,
      .phy_reset_n,
      .phy_int_n,
      .phy_pme_n,
      .eth_irq    ( eth_irq         ),
      .*
      );

   /////////////////////////////////////////////////////////////
   // Host for ISA regression

   nasti_channel
     #(
       .ADDR_WIDTH  ( `MMIO_MASTER_ADDR_WIDTH   ),
       .DATA_WIDTH  ( `LOWRISC_IO_DAT_WIDTH     ))
   io_host_lite();

   /////////////////////////////////////////////////////////////
   // the Rocket chip

   wire CAPTURE, DRCK, RESET, RUNTEST, SEL, SHIFT, TCK, TDI, TMS, UPDATE, TDO, TCK_unbuf;

   /* This block is just used to feed the JTAG clock into the parts of Rocket that need it */
      
   BSCANE2 #(
      .JTAG_CHAIN(2)  // Value for USER command.
   )
   BSCANE2_inst1 (
      .CAPTURE(CAPTURE), // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DRCK),       // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                         // SHIFT are asserted.

      .RESET(RESET),     // 1-bit output: Reset output for TAP controller.
      .RUNTEST(RUNTEST), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(SEL),         // 1-bit output: USER instruction active output.
      .SHIFT(SHIFT),     // 1-bit output: SHIFT output from TAP controller.
      .TCK(TCK_unbuf),   // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(TDI),         // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(TMS),         // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(UPDATE),   // 1-bit output: UPDATE output from TAP controller
      .TDO(TDO)          // 1-bit input: Test Data Output (TDO) input for USER function.
   );

   // BUFH: HROW Clock Buffer for a Single Clocking Region
   //       Artix-7
   // Xilinx HDL Language Template, version 2016.1

   BUFH BUFH_inst (
      .O(TCK), // 1-bit output: Clock output
      .I(TCK_unbuf)  // 1-bit input: Clock input
   );
  
  /* DMI interface tie-off */
  wire  ExampleRocketSystem_debug_ndreset;
  wire  ExampleRocketSystem_debug_dmactive;
  reg [31:0] io_reset_vector;

   always @*
     begin
        casez (i_dip[1:0])
          2'b?0: io_reset_vector = 32'h40000000;
          2'b01: io_reset_vector = 32'h80000000;
          2'b11: io_reset_vector = 32'h80200000;
        endcase // casez ()
     end
   
   ExampleRocketSystem Rocket
     (
      .debug_systemjtag_jtag_TCK(TCK),
      .debug_systemjtag_jtag_TMS(TMS),
      .debug_systemjtag_jtag_TDI(TDI),
      .debug_systemjtag_jtag_TDO_data(TDO),
      .debug_systemjtag_jtag_TDO_driven(TDO_driven),
      .debug_systemjtag_reset(RESET),
      .debug_systemjtag_mfr_id(11'h5AA),
      .debug_ndreset(ExampleRocketSystem_debug_ndreset),
      .debug_dmactive(ExampleRocketSystem_debug_dmactive),
      .mem_axi4_0_aw_valid                ( mem_nasti.aw_valid                     ),
      .mem_axi4_0_aw_ready                ( mem_nasti.aw_ready                     ),
      .mem_axi4_0_aw_bits_id              ( mem_nasti.aw_id                        ),
      .mem_axi4_0_aw_bits_addr            ( mem_nasti.aw_addr                      ),
      .mem_axi4_0_aw_bits_len             ( mem_nasti.aw_len                       ),
      .mem_axi4_0_aw_bits_size            ( mem_nasti.aw_size                      ),
      .mem_axi4_0_aw_bits_burst           ( mem_nasti.aw_burst                     ),
      .mem_axi4_0_aw_bits_lock            ( mem_nasti.aw_lock                      ),
      .mem_axi4_0_aw_bits_cache           ( mem_nasti.aw_cache                     ),
      .mem_axi4_0_aw_bits_prot            ( mem_nasti.aw_prot                      ),
      .mem_axi4_0_aw_bits_qos             ( mem_nasti.aw_qos                       ),
      .mem_axi4_0_w_valid                 ( mem_nasti.w_valid                      ),
      .mem_axi4_0_w_ready                 ( mem_nasti.w_ready                      ),
      .mem_axi4_0_w_bits_data             ( mem_nasti.w_data                       ),
      .mem_axi4_0_w_bits_strb             ( mem_nasti.w_strb                       ),
      .mem_axi4_0_w_bits_last             ( mem_nasti.w_last                       ),
      .mem_axi4_0_b_valid                 ( mem_nasti.b_valid                      ),
      .mem_axi4_0_b_ready                 ( mem_nasti.b_ready                      ),
      .mem_axi4_0_b_bits_id               ( mem_nasti.b_id                         ),
      .mem_axi4_0_b_bits_resp             ( mem_nasti.b_resp                       ),
      .mem_axi4_0_ar_valid                ( mem_nasti.ar_valid                     ),
      .mem_axi4_0_ar_ready                ( mem_nasti.ar_ready                     ),
      .mem_axi4_0_ar_bits_id              ( mem_nasti.ar_id                        ),
      .mem_axi4_0_ar_bits_addr            ( mem_nasti.ar_addr                      ),
      .mem_axi4_0_ar_bits_len             ( mem_nasti.ar_len                       ),
      .mem_axi4_0_ar_bits_size            ( mem_nasti.ar_size                      ),
      .mem_axi4_0_ar_bits_burst           ( mem_nasti.ar_burst                     ),
      .mem_axi4_0_ar_bits_lock            ( mem_nasti.ar_lock                      ),
      .mem_axi4_0_ar_bits_cache           ( mem_nasti.ar_cache                     ),
      .mem_axi4_0_ar_bits_prot            ( mem_nasti.ar_prot                      ),
      .mem_axi4_0_ar_bits_qos             ( mem_nasti.ar_qos                       ),
      .mem_axi4_0_r_valid                 ( mem_nasti.r_valid                      ),
      .mem_axi4_0_r_ready                 ( mem_nasti.r_ready                      ),
      .mem_axi4_0_r_bits_id               ( mem_nasti.r_id                         ),
      .mem_axi4_0_r_bits_data             ( mem_nasti.r_data                       ),
      .mem_axi4_0_r_bits_resp             ( mem_nasti.r_resp                       ),
      .mem_axi4_0_r_bits_last             ( mem_nasti.r_last                       ),
      .mmio_axi4_0_aw_valid        ( mmio_master_nasti.aw_valid               ),
      .mmio_axi4_0_aw_ready        ( mmio_master_nasti.aw_ready               ),
      .mmio_axi4_0_aw_bits_id      ( mmio_master_nasti.aw_id                  ),
      .mmio_axi4_0_aw_bits_addr    ( mmio_master_nasti.aw_addr                ),
      .mmio_axi4_0_aw_bits_len     ( mmio_master_nasti.aw_len                 ),
      .mmio_axi4_0_aw_bits_size    ( mmio_master_nasti.aw_size                ),
      .mmio_axi4_0_aw_bits_burst   ( mmio_master_nasti.aw_burst               ),
      .mmio_axi4_0_aw_bits_lock    ( mmio_master_nasti.aw_lock                ),
      .mmio_axi4_0_aw_bits_cache   ( mmio_master_nasti.aw_cache               ),
      .mmio_axi4_0_aw_bits_prot    ( mmio_master_nasti.aw_prot                ),
      .mmio_axi4_0_aw_bits_qos     ( mmio_master_nasti.aw_qos                 ),
      .mmio_axi4_0_w_valid         ( mmio_master_nasti.w_valid                ),
      .mmio_axi4_0_w_ready         ( mmio_master_nasti.w_ready                ),
      .mmio_axi4_0_w_bits_data     ( mmio_master_nasti.w_data                 ),
      .mmio_axi4_0_w_bits_strb     ( mmio_master_nasti.w_strb                 ),
      .mmio_axi4_0_w_bits_last     ( mmio_master_nasti.w_last                 ),
      .mmio_axi4_0_b_valid         ( mmio_master_nasti.b_valid                ),
      .mmio_axi4_0_b_ready         ( mmio_master_nasti.b_ready                ),
      .mmio_axi4_0_b_bits_id       ( mmio_master_nasti.b_id                   ),
      .mmio_axi4_0_b_bits_resp     ( mmio_master_nasti.b_resp                 ),
      .mmio_axi4_0_ar_valid        ( mmio_master_nasti.ar_valid               ),
      .mmio_axi4_0_ar_ready        ( mmio_master_nasti.ar_ready               ),
      .mmio_axi4_0_ar_bits_id      ( mmio_master_nasti.ar_id                  ),
      .mmio_axi4_0_ar_bits_addr    ( mmio_master_nasti.ar_addr                ),
      .mmio_axi4_0_ar_bits_len     ( mmio_master_nasti.ar_len                 ),
      .mmio_axi4_0_ar_bits_size    ( mmio_master_nasti.ar_size                ),
      .mmio_axi4_0_ar_bits_burst   ( mmio_master_nasti.ar_burst               ),
      .mmio_axi4_0_ar_bits_lock    ( mmio_master_nasti.ar_lock                ),
      .mmio_axi4_0_ar_bits_cache   ( mmio_master_nasti.ar_cache               ),
      .mmio_axi4_0_ar_bits_prot    ( mmio_master_nasti.ar_prot                ),
      .mmio_axi4_0_ar_bits_qos     ( mmio_master_nasti.ar_qos                 ),
      .mmio_axi4_0_r_valid         ( mmio_master_nasti.r_valid                ),
      .mmio_axi4_0_r_ready         ( mmio_master_nasti.r_ready                ),
      .mmio_axi4_0_r_bits_id       ( mmio_master_nasti.r_id                   ),
      .mmio_axi4_0_r_bits_data     ( mmio_master_nasti.r_data                 ),
      .mmio_axi4_0_r_bits_resp     ( mmio_master_nasti.r_resp                 ),
      .mmio_axi4_0_r_bits_last     ( mmio_master_nasti.r_last                 ),
      .l2_frontend_bus_axi4_0_aw_valid         ( io_slave_nasti.aw_valid                ),
      .l2_frontend_bus_axi4_0_aw_ready         ( io_slave_nasti.aw_ready                ),
      .l2_frontend_bus_axi4_0_aw_bits_id       ( io_slave_nasti.aw_id                   ),
      .l2_frontend_bus_axi4_0_aw_bits_addr     ( io_slave_nasti.aw_addr                 ),
      .l2_frontend_bus_axi4_0_aw_bits_len      ( io_slave_nasti.aw_len                  ),
      .l2_frontend_bus_axi4_0_aw_bits_size     ( io_slave_nasti.aw_size                 ),
      .l2_frontend_bus_axi4_0_aw_bits_burst    ( io_slave_nasti.aw_burst                ),
      .l2_frontend_bus_axi4_0_aw_bits_lock     ( io_slave_nasti.aw_lock                 ),
      .l2_frontend_bus_axi4_0_aw_bits_cache    ( io_slave_nasti.aw_cache                ),
      .l2_frontend_bus_axi4_0_aw_bits_prot     ( io_slave_nasti.aw_prot                 ),
      .l2_frontend_bus_axi4_0_aw_bits_qos      ( io_slave_nasti.aw_qos                  ),
      .l2_frontend_bus_axi4_0_w_valid          ( io_slave_nasti.w_valid                 ),
      .l2_frontend_bus_axi4_0_w_ready          ( io_slave_nasti.w_ready                 ),
      .l2_frontend_bus_axi4_0_w_bits_data      ( io_slave_nasti.w_data                  ),
      .l2_frontend_bus_axi4_0_w_bits_strb      ( io_slave_nasti.w_strb                  ),
      .l2_frontend_bus_axi4_0_w_bits_last      ( io_slave_nasti.w_last                  ),
      .l2_frontend_bus_axi4_0_b_valid          ( io_slave_nasti.b_valid                 ),
      .l2_frontend_bus_axi4_0_b_ready          ( io_slave_nasti.b_ready                 ),
      .l2_frontend_bus_axi4_0_b_bits_id        ( io_slave_nasti.b_id                    ),
      .l2_frontend_bus_axi4_0_b_bits_resp      ( io_slave_nasti.b_resp                  ),
      .l2_frontend_bus_axi4_0_ar_valid         ( io_slave_nasti.ar_valid                ),
      .l2_frontend_bus_axi4_0_ar_ready         ( io_slave_nasti.ar_ready                ),
      .l2_frontend_bus_axi4_0_ar_bits_id       ( io_slave_nasti.ar_id                   ),
      .l2_frontend_bus_axi4_0_ar_bits_addr     ( io_slave_nasti.ar_addr                 ),
      .l2_frontend_bus_axi4_0_ar_bits_len      ( io_slave_nasti.ar_len                  ),
      .l2_frontend_bus_axi4_0_ar_bits_size     ( io_slave_nasti.ar_size                 ),
      .l2_frontend_bus_axi4_0_ar_bits_burst    ( io_slave_nasti.ar_burst                ),
      .l2_frontend_bus_axi4_0_ar_bits_lock     ( io_slave_nasti.ar_lock                 ),
      .l2_frontend_bus_axi4_0_ar_bits_cache    ( io_slave_nasti.ar_cache                ),
      .l2_frontend_bus_axi4_0_ar_bits_prot     ( io_slave_nasti.ar_prot                 ),
      .l2_frontend_bus_axi4_0_ar_bits_qos      ( io_slave_nasti.ar_qos                  ),
      .l2_frontend_bus_axi4_0_r_valid          ( io_slave_nasti.r_valid                 ),
      .l2_frontend_bus_axi4_0_r_ready          ( io_slave_nasti.r_ready                 ),
      .l2_frontend_bus_axi4_0_r_bits_id        ( io_slave_nasti.r_id                    ),
      .l2_frontend_bus_axi4_0_r_bits_data      ( io_slave_nasti.r_data                  ),
      .l2_frontend_bus_axi4_0_r_bits_resp      ( io_slave_nasti.r_resp                  ),
      .l2_frontend_bus_axi4_0_r_bits_last      ( io_slave_nasti.r_last                  ),
      .interrupts                    ( {sd_irq, eth_irq, spi_irq, uart_irq} ),
      .io_reset_vector               ( io_reset_vector                      ),
      .clock                         ( clk                                  ),
      .reset                         ( sys_rst                              )
      );
   
endmodule // chip_top
