// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Description: Xilinx FPGA top-level
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

module ariane_xilinx (
`ifdef GENESYSII
  input  logic         sys_clk_p   ,
  input  logic         sys_clk_n   ,
  input  logic         cpu_resetn  ,
  inout  wire  [31:0]  ddr3_dq     ,
  inout  wire  [ 3:0]  ddr3_dqs_n  ,
  inout  wire  [ 3:0]  ddr3_dqs_p  ,
  output logic [14:0]  ddr3_addr   ,
  output logic [ 2:0]  ddr3_ba     ,
  output logic         ddr3_ras_n  ,
  output logic         ddr3_cas_n  ,
  output logic         ddr3_we_n   ,
  output logic         ddr3_reset_n,
  output logic [ 0:0]  ddr3_ck_p   ,
  output logic [ 0:0]  ddr3_ck_n   ,
  output logic [ 0:0]  ddr3_cke    ,
  output logic [ 0:0]  ddr3_cs_n   ,
  output logic [ 3:0]  ddr3_dm     ,
  output logic [ 0:0]  ddr3_odt    ,
`elsif NEXYS4DDR
  input  logic        clk_p       ,
  input  logic        cpu_resetn  ,
  inout  wire  [15:0] ddr2_dq     ,
  inout  wire  [ 1:0] ddr2_dqs_n  ,
  inout  wire  [ 1:0] ddr2_dqs_p  ,
  output logic [12:0] ddr2_addr   ,
  output logic [ 2:0] ddr2_ba     ,
  output logic        ddr2_ras_n  ,
  output logic        ddr2_cas_n  ,
  output logic        ddr2_we_n   ,
  output logic [ 0:0] ddr2_ck_p   ,
  output logic [ 0:0] ddr2_ck_n   ,
  output logic [ 0:0] ddr2_cke    ,
  output logic [ 1:0] ddr2_dm     ,
  output logic [ 0:0] ddr2_odt    ,
`elsif NEXYS_VIDEO
  input  logic        clk_p       ,
  input  logic        cpu_resetn  ,
  inout wire   [15:0] ddr3_dq     ,
  inout wire    [1:0] ddr3_dqs_n  ,
  inout wire    [1:0] ddr3_dqs_p  ,
  output logic [14:0] ddr3_addr   ,
  output logic  [2:0] ddr3_ba     ,
  output logic        ddr3_ras_n  ,
  output logic        ddr3_cas_n  ,
  output logic        ddr3_we_n   ,
  output logic        ddr3_reset_n,
  output logic        ddr3_ck_n   ,
  output logic        ddr3_ck_p   ,
  output logic        ddr3_cke    ,
  output logic  [1:0] ddr3_dm     ,
  output logic        ddr3_odt    ,
`endif
`ifdef RGMII
  output wire          eth_rst_n   ,
  input  wire          eth_rxck    ,
  input  wire          eth_rxctl   ,
  input  wire [3:0]    eth_rxd     ,
  output wire          eth_txck    ,
  output wire          eth_txctl   ,
  output wire [3:0]    eth_txd     ,
`endif
`ifdef RMII
  //! Ethernet MAC PHY interface signals
  input wire [1:0]    i_erxd, // RMII receive data
  input wire          i_erx_dv, // PHY data valid
  input wire          i_erx_er, // PHY coding error
  input wire          i_emdint, // PHY interrupt in active low
  output reg          o_erefclk, // RMII clock out
  output reg [1:0]    o_etxd, // RMII transmit data
  output reg          o_etx_en, // RMII transmit enable
  output wire         o_erstn, // PHY reset active low 
`endif
  inout  wire          eth_mdio    ,
  output logic         eth_mdc     ,
  output logic [ 7:0]  led         ,
  input  logic [ 7:0]  sw          ,
  output logic         fan_pwm     ,
  // SD (shared with SPI)
  output wire        sd_sclk,
  input wire         sd_detect,
  inout wire [3:0]   sd_dat,
  inout wire         sd_cmd,
  output reg         sd_reset,
  // common part
  input  logic        tck         ,
  input  logic        tms         ,
  input  logic        trst_n      ,
  input  logic        tdi         ,
  output wire         tdo         ,
  input  logic        rx          ,
  output logic        tx          ,
  // Quad-SPI
  inout wire          QSPI_CSN    ,
  inout wire [3:0]    QSPI_D
);
localparam NBSlave = 2; // debug, ariane
localparam AxiAddrWidth = 64;
localparam AxiDataWidth = 64;
localparam AxiIdWidthMaster = 4;
localparam AxiIdWidthSlaves = AxiIdWidthMaster + $clog2(NBSlave); // 5
localparam AxiUserWidth = 1;

// MIG clock
logic mig_sys_clk, mig_ui_clk, mig_ui_rst, sys_rst,
      clk, clk_rmii, clk_rmii_quad, clk_pixel, phy_tx_clk, eth_clk, pll_locked;
logic rst_n, tdo_oe, tdo_data, ndmreset_n;

IOBUF #(
          .DRIVE(12), // Specify the output drive strength
          .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
          .IOSTANDARD("DEFAULT"), // Specify the I/O standard
          .SLEW("SLOW") // Specify the output slew rate
       ) IOBUF_inst (
          .O(),     // Buffer output
          .IO(tdo),      // Buffer inout port (connect directly to top-level port)
          .I(tdo_data),     // Buffer input
          .T(~tdo_oe)    // 3-state enable input, high=input, low=output
       );

`ifdef GENESYSII

xlnx_clk_genesys2 i_xlnx_clk_gen (
  .clk_out1 ( clk           ), // 50 MHz
  .clk_out2 ( phy_tx_clk    ), // 125 MHz (for RGMII PHY)
  .clk_out3 ( eth_clk       ), // 125 MHz quadrature (90 deg phase shift)
  .clk_out4 ( sd_clk_sys    ), // 50 MHz clock
  .resetn   ( cpu_resetn    ),
  .locked   ( pll_locked    ),
  .clk_in1  ( mig_ui_clk    )
);

assign mig_sys_clk = mig_ui_clk;
   
`elsif NEXYS4DDR

xlnx_clk_nexys4_ddr i_xlnx_clk_gen (
  .clk_out1 ( mig_sys_clk    ), // 200 MHz
  .clk_out2 ( clk_rmii       ), // 50 MHz (for RGMII PHY)
  .clk_out3 ( clk_rmii_quad  ), // 50 MHz quadrature (90 deg phase shift)
  .clk_out4 ( clk_pixel      ), // 120 MHz clock
  .resetn   ( cpu_resetn     ),
  .locked   ( pll_locked     ),
  .clk_in1  ( clk_p          )
);

assign clk = mig_ui_clk;

`elsif NEXYS_VIDEO

xlnx_clk_nexys_video i_xlnx_clk_gen (
  .clk_out1 ( mig_sys_clk    ), // 200 MHz
  .clk_out2 ( phy_tx_clk     ), // 125 MHz (for RGMII PHY)
  .clk_out3 ( eth_clk        ), // 125 MHz quadrature (90 deg phase shift)
  .clk_out4 ( clk            ), // 50 MHz clock
  .resetn   ( cpu_resetn     ),
  .locked   ( pll_locked     ),
  .clk_in1  ( clk_p          )
);

`endif
 
logic rst_done;   
logic [5:0] rst_count;
   
always @(posedge mig_ui_clk or posedge mig_ui_rst)
  if (mig_ui_rst)
    begin
       rst_count <= '0;
       rst_done = '0;
       rst_n = '0;
    end
  else
    begin
       rst_done = &rst_count;
       rst_count <= rst_count + !rst_done;
       if (rst_done && pll_locked)
         rst_n = '1;
    end

// ---------------
// DDR
// ---------------

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) dram(), iobus();

`ifdef GENESYSII
 `define CLOCK_CONVERTER
`endif

`ifdef NEXYS_VIDEO
 `define CLOCK_CONVERTER
`endif

`ifdef CLOCK_CONVERTER   
logic [AxiIdWidthSlaves-1:0] s_axi_awid;
logic [AxiAddrWidth-1:0]     s_axi_awaddr;
logic [7:0]                  s_axi_awlen;
logic [2:0]                  s_axi_awsize;
logic [1:0]                  s_axi_awburst;
logic [0:0]                  s_axi_awlock;
logic [3:0]                  s_axi_awcache;
logic [2:0]                  s_axi_awprot;
logic [3:0]                  s_axi_awregion;
logic [3:0]                  s_axi_awqos;
logic                        s_axi_awvalid;
logic                        s_axi_awready;
logic [AxiDataWidth-1:0]     s_axi_wdata;
logic [AxiDataWidth/8-1:0]   s_axi_wstrb;
logic                        s_axi_wlast;
logic                        s_axi_wvalid;
logic                        s_axi_wready;
logic [AxiIdWidthSlaves-1:0] s_axi_bid;
logic [1:0]                  s_axi_bresp;
logic                        s_axi_bvalid;
logic                        s_axi_bready;
logic [AxiIdWidthSlaves-1:0] s_axi_arid;
logic [AxiAddrWidth-1:0]     s_axi_araddr;
logic [7:0]                  s_axi_arlen;
logic [2:0]                  s_axi_arsize;
logic [1:0]                  s_axi_arburst;
logic [0:0]                  s_axi_arlock;
logic [3:0]                  s_axi_arcache;
logic [2:0]                  s_axi_arprot;
logic [3:0]                  s_axi_arregion;
logic [3:0]                  s_axi_arqos;
logic                        s_axi_arvalid;
logic                        s_axi_arready;
logic [AxiIdWidthSlaves-1:0] s_axi_rid;
logic [AxiDataWidth-1:0]     s_axi_rdata;
logic [1:0]                  s_axi_rresp;
logic                        s_axi_rlast;
logic                        s_axi_rvalid;
logic                        s_axi_rready;

xlnx_axi_clock_converter i_xlnx_axi_clock_converter_ddr (
  .s_axi_aclk     ( clk              ),
  .s_axi_aresetn  ( rst_n            ),
  .s_axi_awid     ( dram.aw_id       ),
  .s_axi_awaddr   ( dram.aw_addr     ),
  .s_axi_awlen    ( dram.aw_len      ),
  .s_axi_awsize   ( dram.aw_size     ),
  .s_axi_awburst  ( dram.aw_burst    ),
  .s_axi_awlock   ( dram.aw_lock     ),
  .s_axi_awcache  ( dram.aw_cache    ),
  .s_axi_awprot   ( dram.aw_prot     ),
  .s_axi_awregion ( dram.aw_region   ),
  .s_axi_awqos    ( dram.aw_qos      ),
  .s_axi_awvalid  ( dram.aw_valid    ),
  .s_axi_awready  ( dram.aw_ready    ),
  .s_axi_wdata    ( dram.w_data      ),
  .s_axi_wstrb    ( dram.w_strb      ),
  .s_axi_wlast    ( dram.w_last      ),
  .s_axi_wvalid   ( dram.w_valid     ),
  .s_axi_wready   ( dram.w_ready     ),
  .s_axi_bid      ( dram.b_id        ),
  .s_axi_bresp    ( dram.b_resp      ),
  .s_axi_bvalid   ( dram.b_valid     ),
  .s_axi_bready   ( dram.b_ready     ),
  .s_axi_arid     ( dram.ar_id       ),
  .s_axi_araddr   ( dram.ar_addr     ),
  .s_axi_arlen    ( dram.ar_len      ),
  .s_axi_arsize   ( dram.ar_size     ),
  .s_axi_arburst  ( dram.ar_burst    ),
  .s_axi_arlock   ( dram.ar_lock     ),
  .s_axi_arcache  ( dram.ar_cache    ),
  .s_axi_arprot   ( dram.ar_prot     ),
  .s_axi_arregion ( dram.ar_region   ),
  .s_axi_arqos    ( dram.ar_qos      ),
  .s_axi_arvalid  ( dram.ar_valid    ),
  .s_axi_arready  ( dram.ar_ready    ),
  .s_axi_rid      ( dram.r_id        ),
  .s_axi_rdata    ( dram.r_data      ),
  .s_axi_rresp    ( dram.r_resp      ),
  .s_axi_rlast    ( dram.r_last      ),
  .s_axi_rvalid   ( dram.r_valid     ),
  .s_axi_rready   ( dram.r_ready     ),
  // to size converter
  .m_axi_aclk     ( mig_ui_clk       ),
  .m_axi_aresetn  ( rst_n            ),
  .m_axi_awid     ( s_axi_awid       ),
  .m_axi_awaddr   ( s_axi_awaddr     ),
  .m_axi_awlen    ( s_axi_awlen      ),
  .m_axi_awsize   ( s_axi_awsize     ),
  .m_axi_awburst  ( s_axi_awburst    ),
  .m_axi_awlock   ( s_axi_awlock     ),
  .m_axi_awcache  ( s_axi_awcache    ),
  .m_axi_awprot   ( s_axi_awprot     ),
  .m_axi_awregion ( s_axi_awregion   ),
  .m_axi_awqos    ( s_axi_awqos      ),
  .m_axi_awvalid  ( s_axi_awvalid    ),
  .m_axi_awready  ( s_axi_awready    ),
  .m_axi_wdata    ( s_axi_wdata      ),
  .m_axi_wstrb    ( s_axi_wstrb      ),
  .m_axi_wlast    ( s_axi_wlast      ),
  .m_axi_wvalid   ( s_axi_wvalid     ),
  .m_axi_wready   ( s_axi_wready     ),
  .m_axi_bid      ( s_axi_bid        ),
  .m_axi_bresp    ( s_axi_bresp      ),
  .m_axi_bvalid   ( s_axi_bvalid     ),
  .m_axi_bready   ( s_axi_bready     ),
  .m_axi_arid     ( s_axi_arid       ),
  .m_axi_araddr   ( s_axi_araddr     ),
  .m_axi_arlen    ( s_axi_arlen      ),
  .m_axi_arsize   ( s_axi_arsize     ),
  .m_axi_arburst  ( s_axi_arburst    ),
  .m_axi_arlock   ( s_axi_arlock     ),
  .m_axi_arcache  ( s_axi_arcache    ),
  .m_axi_arprot   ( s_axi_arprot     ),
  .m_axi_arregion ( s_axi_arregion   ),
  .m_axi_arqos    ( s_axi_arqos      ),
  .m_axi_arvalid  ( s_axi_arvalid    ),
  .m_axi_arready  ( s_axi_arready    ),
  .m_axi_rid      ( s_axi_rid        ),
  .m_axi_rdata    ( s_axi_rdata      ),
  .m_axi_rresp    ( s_axi_rresp      ),
  .m_axi_rlast    ( s_axi_rlast      ),
  .m_axi_rvalid   ( s_axi_rvalid     ),
  .m_axi_rready   ( s_axi_rready     )
);
`endif //  `ifdef CLOCK_CONVERTER

`ifdef GENESYSII
xlnx_mig_7_ddr_genesys2 i_ddr (
    .sys_clk_p,
    .sys_clk_n,
    .sys_rst         ( cpu_resetn    ),
    .ddr3_dq,
    .ddr3_dqs_n,
    .ddr3_dqs_p,
    .ddr3_addr,
    .ddr3_ba,
    .ddr3_ras_n,
    .ddr3_cas_n,
    .ddr3_we_n,
    .ddr3_reset_n,
    .ddr3_ck_p,
    .ddr3_ck_n,
    .ddr3_cke,
    .ddr3_cs_n,
    .ddr3_dm,
    .ddr3_odt,
    .mmcm_locked     (                ), // keep open
    .app_sr_req      ( '0             ),
    .app_ref_req     ( '0             ),
    .app_zq_req      ( '0             ),
    .app_sr_active   (                ), // keep open
    .app_ref_ack     (                ), // keep open
    .app_zq_ack      (                ), // keep open
    .ui_clk          ( mig_ui_clk     ),
    .ui_clk_sync_rst ( mig_ui_rst     ),
    .aresetn         ( rst_n          ),
    .s_axi_awid,
    .s_axi_awaddr    ( s_axi_awaddr[29:0] ),
    .s_axi_awlen,
    .s_axi_awsize,
    .s_axi_awburst,
    .s_axi_awlock,
    .s_axi_awcache,
    .s_axi_awprot,
    .s_axi_awqos,
    .s_axi_awvalid,
    .s_axi_awready,
    .s_axi_wdata,
    .s_axi_wstrb,
    .s_axi_wlast,
    .s_axi_wvalid,
    .s_axi_wready,
    .s_axi_bready,
    .s_axi_bid,
    .s_axi_bresp,
    .s_axi_bvalid,
    .s_axi_arid,
    .s_axi_araddr     ( s_axi_araddr[29:0] ),
    .s_axi_arlen,
    .s_axi_arsize,
    .s_axi_arburst,
    .s_axi_arlock,
    .s_axi_arcache,
    .s_axi_arprot,
    .s_axi_arqos,
    .s_axi_arvalid,
    .s_axi_arready,
    .s_axi_rready,
    .s_axi_rid,
    .s_axi_rdata,
    .s_axi_rresp,
    .s_axi_rlast,
    .s_axi_rvalid,
    .init_calib_complete (            ), // keep open
    .device_temp         (            )  // keep open
);
`elsif NEXYS4DDR
   
xlnx_mig_7_ddr_nexys4_ddr i_ddr (
    .sys_clk_i          ( mig_sys_clk ),
    .sys_rst            ( pll_locked  ),
    .ui_addn_clk_0      (             ),
    .ui_addn_clk_1      (             ),  // output                                       ui_addn_clk_1
    .ui_addn_clk_2      (             ),  // output                                       ui_addn_clk_2
    .ui_addn_clk_3      (             ),  // output                                       ui_addn_clk_3
    .ui_addn_clk_4      (             ),  // output                                       ui_addn_clk_4    
    .device_temp_i      ( 0           ),
    .ddr2_dq,
    .ddr2_dqs_n,
    .ddr2_dqs_p,
    .ddr2_addr,
    .ddr2_ba,
    .ddr2_ras_n,
    .ddr2_cas_n,
    .ddr2_we_n,
    .ddr2_ck_p,
    .ddr2_ck_n,
    .ddr2_cke,
    .ddr2_dm,
    .ddr2_odt,
    .ui_clk          ( mig_ui_clk     ),
    .ui_clk_sync_rst ( mig_ui_rst     ),
    .mmcm_locked     (                ), // keep open
    .aresetn         ( rst_n          ),
    .app_sr_req      ( '0             ),
    .app_ref_req     ( '0             ),
    .app_zq_req      ( '0             ),
    .app_sr_active   (                ), // keep open
    .app_ref_ack     (                ), // keep open
    .app_zq_ack      (                ), // keep open
    .s_axi_awid      ( dram.aw_id     ),
    .s_axi_awaddr    ( dram.aw_addr   ),
    .s_axi_awlen     ( dram.aw_len    ),
    .s_axi_awsize    ( dram.aw_size   ),
    .s_axi_awburst   ( dram.aw_burst  ),
    .s_axi_awlock    ( dram.aw_lock   ),
    .s_axi_awcache   ( dram.aw_cache  ),
    .s_axi_awprot    ( dram.aw_prot   ),
    .s_axi_awqos     ( dram.aw_qos    ),
    .s_axi_awvalid   ( dram.aw_valid  ),
    .s_axi_awready   ( dram.aw_ready  ),
    .s_axi_wdata     ( dram.w_data    ),
    .s_axi_wstrb     ( dram.w_strb    ),
    .s_axi_wlast     ( dram.w_last    ),
    .s_axi_wvalid    ( dram.w_valid   ),
    .s_axi_wready    ( dram.w_ready   ),
    .s_axi_bid       ( dram.b_id      ),
    .s_axi_bresp     ( dram.b_resp    ),
    .s_axi_bvalid    ( dram.b_valid   ),
    .s_axi_bready    ( dram.b_ready   ),
    .s_axi_arid      ( dram.ar_id     ),
    .s_axi_araddr    ( dram.ar_addr   ),
    .s_axi_arlen     ( dram.ar_len    ),
    .s_axi_arsize    ( dram.ar_size   ),
    .s_axi_arburst   ( dram.ar_burst  ),
    .s_axi_arlock    ( dram.ar_lock   ),
    .s_axi_arcache   ( dram.ar_cache  ),
    .s_axi_arprot    ( dram.ar_prot   ),
    .s_axi_arqos     ( dram.ar_qos    ),
    .s_axi_arvalid   ( dram.ar_valid  ),
    .s_axi_arready   ( dram.ar_ready  ),
    .s_axi_rid       ( dram.r_id      ),
    .s_axi_rdata     ( dram.r_data    ),
    .s_axi_rresp     ( dram.r_resp    ),
    .s_axi_rlast     ( dram.r_last    ),
    .s_axi_rvalid    ( dram.r_valid   ),
    .s_axi_rready    ( dram.r_ready   ),
    .init_calib_complete (            ) // keep open
);
`elsif NEXYS_VIDEO
   
xlnx_mig_7_ddr_nexys_video i_ddr (
    .sys_clk_i          ( mig_sys_clk ),
    .sys_rst            ( pll_locked  ),
    .ddr3_dq,
    .ddr3_dqs_n,
    .ddr3_dqs_p,
    .ddr3_addr,
    .ddr3_ba,
    .ddr3_ras_n,
    .ddr3_cas_n,
    .ddr3_we_n,
    .ddr3_ck_p,
    .ddr3_ck_n,
    .ddr3_cke,
    .ddr3_dm,
    .ddr3_odt,
    .ui_clk          ( mig_ui_clk     ),
    .ui_clk_sync_rst ( mig_ui_rst     ),
    .mmcm_locked     (                ), // keep open
    .aresetn         ( rst_n          ),
    .app_sr_req      ( '0             ),
    .app_ref_req     ( '0             ),
    .app_zq_req      ( '0             ),
    .app_sr_active   (                ), // keep open
    .app_ref_ack     (                ), // keep open
    .app_zq_ack      (                ), // keep open
    .s_axi_awid,
    .s_axi_awaddr    ( s_axi_awaddr[29:0] ),
    .s_axi_awlen,
    .s_axi_awsize,
    .s_axi_awburst,
    .s_axi_awlock,
    .s_axi_awcache,
    .s_axi_awprot,
    .s_axi_awqos,
    .s_axi_awvalid,
    .s_axi_awready,
    .s_axi_wdata,
    .s_axi_wstrb,
    .s_axi_wlast,
    .s_axi_wvalid,
    .s_axi_wready,
    .s_axi_bready,
    .s_axi_bid,
    .s_axi_bresp,
    .s_axi_bvalid,
    .s_axi_arid,
    .s_axi_araddr     ( s_axi_araddr[29:0] ),
    .s_axi_arlen,
    .s_axi_arsize,
    .s_axi_arburst,
    .s_axi_arlock,
    .s_axi_arcache,
    .s_axi_arprot,
    .s_axi_arqos,
    .s_axi_arvalid,
    .s_axi_arready,
    .s_axi_rready,
    .s_axi_rid,
    .s_axi_rdata,
    .s_axi_rresp,
    .s_axi_rlast,
    .s_axi_rvalid,
    .init_calib_complete (            ) // keep open
);

`else // simulation
localparam NUM_WORDS = 16 * 1024 * 1024;
   
logic                    ddr_req, ddr_we;
logic [AxiAddrWidth-1:0] ddr_addr;
logic [AxiDataWidth-1:0] ddr_rdata, ddr_wdata;
logic [AxiDataWidth/8-1:0] ddr_be;

axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) i_axi2rom (
    .clk_i  ( clk                      ),
    .rst_ni ( rst_n                    ),
    .slave  ( dram                     ),
    .req_o  ( ddr_req                  ),
    .we_o   ( ddr_we                   ),
    .addr_o ( ddr_addr                 ),
    .be_o   ( ddr_be                   ),
    .data_o ( ddr_wdata                ),
    .data_i ( ddr_rdata                )
);

sram #(
    .DATA_WIDTH ( AxiDataWidth ),
    .NUM_WORDS  ( NUM_WORDS    )
  ) i_sram (
    .clk_i      ( clk                                                                         ),
    .rst_ni     ( rst_n                                                                       ),
    .req_i      ( req                                                                         ),
    .we_i       ( we                                                                          ),
    .addr_i     ( addr[$clog2(NUM_WORDS)-1+$clog2(AxiDataWidth/8):$clog2(AxiDataWidth/8)] ),
    .wdata_i    ( wdata                                                                       ),
    .be_i       ( be                                                                          ),
    .rdata_o    ( rdata                                                                       )
  );

assign mig_ui_rst = !pll_locked;   
  
`endif

// disable test-enable
wire test_en = 1'b0;

logic spi_clk_i;
logic sd_clk_sys;

assign sys_rst = ~rst_n;

logic [ariane_soc::NumSources-1:0] irq_sources;

// ---------------
// Peripherals
// ---------------
ariane_peripherals_xilinx #(
    .AxiAddrWidth ( AxiAddrWidth     ),
    .AxiDataWidth ( AxiDataWidth     ),
    .AxiIdWidth   ( AxiIdWidthSlaves ),
    .AxiUserWidth ( AxiUserWidth     ),
    .InclUART     ( 1'b1             ),
    .InclGPIO     ( 1'b1             ),
    .InclSPI      ( 1'b1             ),
    .InclEthernet ( 1'b1             )
) i_ariane_peripherals (
    .clk_i         ( clk             ),
    .clk_200MHz_i  ( mig_sys_clk     ),
    .rst_ni        ( rst_n           ),
    .iobus,
    .irq_sources,
    .rx_i          ( rx              ),
    .tx_o          ( tx              ),
`ifdef RGMII                        
    .eth_clk_i     ( eth_clk         ),
    .phy_tx_clk_i  ( phy_tx_clk      ),
    .eth_txck,
    .eth_rxck,
    .eth_rxctl,
    .eth_rxd,
    .eth_rst_n,
    .eth_txctl,
    .eth_txd,
`endif                        
`ifdef RMII                        
    .clk_rmii      ( clk_rmii        ),
    .clk_rmii_quad ( clk_rmii_quad   ),
    .i_erxd, // RMII receive data
    .i_erx_dv, // PHY data valid
    .i_erx_er, // PHY coding error
    .i_emdint, // PHY interrupt in active low
    .o_erefclk, // RMII clock out
    .o_etxd, // RMII transmit data
    .o_etx_en, // RMII transmit enable
    .o_erstn, // PHY reset active low
`endif                        
    .eth_mdio, // PHY control
    .eth_mdc,                        
    .sd_sclk, // SD-Card
    .sd_detect,
    .sd_dat,
    .sd_cmd,
    .sd_reset,
    .leds_o         ( led             ),
    .dip_switches_i ( sw              ),
    .QSPI_CSN, // Quad-SPI (for MAC address)
    .QSPI_D
);


// ---------------------
// Board peripherals
// ---------------------

fan_ctrl i_fan_ctrl (
    .clk_i         ( clk        ),
    .rst_ni        ( rst_n      ),
    .pwm_setting_i ( 'd8        ),
    .fan_pwm_o     ( fan_pwm    )
);

`ifdef ARIANE_SHELL   
ariane_shell shell1(.*);
`elsif ROCKET_SHELL
rocket_shell shell1(.*);
`elsif BOOM_SHELL
boom_shell shell1(.*);
`else
   if (1) $error("One of ARIANE_SHELL, ROCKET_SHELL, BOOM_SHELL should be defined");
`endif
   
endmodule
