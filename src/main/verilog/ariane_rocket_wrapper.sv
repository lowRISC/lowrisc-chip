// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 19.03.2017
// Description: Ariane Top-level module

`default_nettype none

import ariane_pkg::*;
  
module ExampleArianeSystem #(
        parameter int unsigned AXI_ID_WIDTH = 4, // minimum 1
        parameter int unsigned AXI_USER_WIDTH = 1, // minimum 1
        parameter int unsigned AXI_ADDRESS_WIDTH = 64,
        parameter int unsigned AXI_DATA_WIDTH = 64,
        parameter int unsigned INTERRUPT_COUNT = 4
    ) (
  input wire         clock,
  input wire         reset,
  input wire         debug_systemjtag_jtag_TCK,
  input wire         debug_systemjtag_jtag_TMS,
  input wire         debug_systemjtag_jtag_TDI,
  output wire        debug_systemjtag_jtag_TDO_data,
  output wire        debug_systemjtag_jtag_TDO_driven,
  input wire         debug_systemjtag_reset,
  input wire [10:0]  debug_systemjtag_mfr_id,
  output wire        debug_ndreset,
  output wire        debug_dmactive,
  input wire [31:0]  io_reset_vector,
  input wire [INTERRUPT_COUNT-1:0]   interrupts,
  input wire         mem_axi4_0_aw_ready,
  output wire        mem_axi4_0_aw_valid,
  output wire [AXI_ID_WIDTH-1:0]  mem_axi4_0_aw_bits_id,
  output wire [31:0] mem_axi4_0_aw_bits_addr,
  output wire [7:0]  mem_axi4_0_aw_bits_len,
  output wire [2:0]  mem_axi4_0_aw_bits_size,
  output wire [1:0]  mem_axi4_0_aw_bits_burst,
  output wire        mem_axi4_0_aw_bits_lock,
  output wire [3:0]  mem_axi4_0_aw_bits_cache,
  output wire [2:0]  mem_axi4_0_aw_bits_prot,
  output wire [3:0]  mem_axi4_0_aw_bits_qos,
  input wire         mem_axi4_0_w_ready,
  output wire        mem_axi4_0_w_valid,
  output wire [63:0] mem_axi4_0_w_bits_data,
  output wire [7:0]  mem_axi4_0_w_bits_strb,
  output wire        mem_axi4_0_w_bits_last,
  output wire        mem_axi4_0_b_ready,
  input wire         mem_axi4_0_b_valid,
  input wire [AXI_ID_WIDTH-1:0]   mem_axi4_0_b_bits_id,
  input wire [1:0]   mem_axi4_0_b_bits_resp,
  input wire         mem_axi4_0_ar_ready,
  output wire        mem_axi4_0_ar_valid,
  output wire [AXI_ID_WIDTH-1:0]  mem_axi4_0_ar_bits_id,
  output wire [31:0] mem_axi4_0_ar_bits_addr,
  output wire [7:0]  mem_axi4_0_ar_bits_len,
  output wire [2:0]  mem_axi4_0_ar_bits_size,
  output wire [1:0]  mem_axi4_0_ar_bits_burst,
  output wire        mem_axi4_0_ar_bits_lock,
  output wire [3:0]  mem_axi4_0_ar_bits_cache,
  output wire [2:0]  mem_axi4_0_ar_bits_prot,
  output wire [3:0]  mem_axi4_0_ar_bits_qos,
  output wire        mem_axi4_0_r_ready,
  input wire         mem_axi4_0_r_valid,
  input wire [AXI_ID_WIDTH-1:0]   mem_axi4_0_r_bits_id,
  input wire [63:0]  mem_axi4_0_r_bits_data,
  input wire [1:0]   mem_axi4_0_r_bits_resp,
  input wire         mem_axi4_0_r_bits_last,
  input wire         mmio_axi4_0_aw_ready,
  output wire        mmio_axi4_0_aw_valid,
  output wire [AXI_ID_WIDTH-1:0]  mmio_axi4_0_aw_bits_id,
  output wire [30:0] mmio_axi4_0_aw_bits_addr,
  output wire [7:0]  mmio_axi4_0_aw_bits_len,
  output wire [2:0]  mmio_axi4_0_aw_bits_size,
  output wire [1:0]  mmio_axi4_0_aw_bits_burst,
  output wire        mmio_axi4_0_aw_bits_lock,
  output wire [3:0]  mmio_axi4_0_aw_bits_cache,
  output wire [2:0]  mmio_axi4_0_aw_bits_prot,
  output wire [3:0]  mmio_axi4_0_aw_bits_qos,
  input wire         mmio_axi4_0_w_ready,
  output wire        mmio_axi4_0_w_valid,
  output wire [63:0] mmio_axi4_0_w_bits_data,
  output wire [7:0]  mmio_axi4_0_w_bits_strb,
  output wire        mmio_axi4_0_w_bits_last,
  output wire        mmio_axi4_0_b_ready,
  input wire         mmio_axi4_0_b_valid,
  input wire [AXI_ID_WIDTH-1:0]   mmio_axi4_0_b_bits_id,
  input wire [1:0]   mmio_axi4_0_b_bits_resp,
  input wire         mmio_axi4_0_ar_ready,
  output wire        mmio_axi4_0_ar_valid,
  output wire [AXI_ID_WIDTH-1:0]  mmio_axi4_0_ar_bits_id,
  output wire [30:0] mmio_axi4_0_ar_bits_addr,
  output wire [7:0]  mmio_axi4_0_ar_bits_len,
  output wire [2:0]  mmio_axi4_0_ar_bits_size,
  output wire [1:0]  mmio_axi4_0_ar_bits_burst,
  output wire        mmio_axi4_0_ar_bits_lock,
  output wire [3:0]  mmio_axi4_0_ar_bits_cache,
  output wire [2:0]  mmio_axi4_0_ar_bits_prot,
  output wire [3:0]  mmio_axi4_0_ar_bits_qos,
  output wire        mmio_axi4_0_r_ready,
  input wire         mmio_axi4_0_r_valid,
  input wire [AXI_ID_WIDTH-1:0]   mmio_axi4_0_r_bits_id,
  input wire [63:0]  mmio_axi4_0_r_bits_data,
  input wire [1:0]   mmio_axi4_0_r_bits_resp,
  input wire         mmio_axi4_0_r_bits_last,
// This slave bus is a placeholder                           
  output wire        l2_frontend_bus_axi4_0_aw_ready,
  input wire         l2_frontend_bus_axi4_0_aw_valid,
  input wire [7:0]   l2_frontend_bus_axi4_0_aw_bits_id,
  input wire [31:0]  l2_frontend_bus_axi4_0_aw_bits_addr,
  input wire [7:0]   l2_frontend_bus_axi4_0_aw_bits_len,
  input wire [2:0]   l2_frontend_bus_axi4_0_aw_bits_size,
  input wire [1:0]   l2_frontend_bus_axi4_0_aw_bits_burst,
  input wire         l2_frontend_bus_axi4_0_aw_bits_lock,
  input wire [3:0]   l2_frontend_bus_axi4_0_aw_bits_cache,
  input wire [2:0]   l2_frontend_bus_axi4_0_aw_bits_prot,
  input wire [3:0]   l2_frontend_bus_axi4_0_aw_bits_qos,
  output wire        l2_frontend_bus_axi4_0_w_ready,
  input wire         l2_frontend_bus_axi4_0_w_valid,
  input wire [63:0]  l2_frontend_bus_axi4_0_w_bits_data,
  input wire [7:0]   l2_frontend_bus_axi4_0_w_bits_strb,
  input wire         l2_frontend_bus_axi4_0_w_bits_last,
  input wire         l2_frontend_bus_axi4_0_b_ready,
  output wire        l2_frontend_bus_axi4_0_b_valid,
  output wire [7:0]  l2_frontend_bus_axi4_0_b_bits_id,
  output wire [1:0]  l2_frontend_bus_axi4_0_b_bits_resp,
  output wire        l2_frontend_bus_axi4_0_ar_ready,
  input wire         l2_frontend_bus_axi4_0_ar_valid,
  input wire [7:0]   l2_frontend_bus_axi4_0_ar_bits_id,
  input wire [31:0]  l2_frontend_bus_axi4_0_ar_bits_addr,
  input wire [7:0]   l2_frontend_bus_axi4_0_ar_bits_len,
  input wire [2:0]   l2_frontend_bus_axi4_0_ar_bits_size,
  input wire [1:0]   l2_frontend_bus_axi4_0_ar_bits_burst,
  input wire         l2_frontend_bus_axi4_0_ar_bits_lock,
  input wire [3:0]   l2_frontend_bus_axi4_0_ar_bits_cache,
  input wire [2:0]   l2_frontend_bus_axi4_0_ar_bits_prot,
  input wire [3:0]   l2_frontend_bus_axi4_0_ar_bits_qos,
  input wire         l2_frontend_bus_axi4_0_r_ready,
  output wire        l2_frontend_bus_axi4_0_r_valid,
  output wire [7:0]  l2_frontend_bus_axi4_0_r_bits_id,
  output wire [63:0] l2_frontend_bus_axi4_0_r_bits_data,
  output wire [1:0]  l2_frontend_bus_axi4_0_r_bits_resp,
  output wire        l2_frontend_bus_axi4_0_r_bits_last
);

    // disable test-enable
    logic        test_en;
    logic        ndmreset;
    logic        ndmreset_n;
    logic        debug_req_core;

    logic        init_done;

    logic        jtag_TCK;
    logic        jtag_TMS;
    logic        jtag_TDI;
    logic        jtag_TRSTn;
    logic        jtag_TDO_data;
    logic        jtag_TDO_driven;

    logic        debug_req_ready;
    logic [1:0]  debug_resp_bits_resp;
    logic [31:0] debug_resp_bits_data;

    logic        jtag_req_valid;
    logic [6:0]  jtag_req_bits_addr;
    logic [1:0]  jtag_req_bits_op;
    logic [31:0] jtag_req_bits_data;
    logic        jtag_resp_ready;
    logic        jtag_resp_valid;

    logic [6:0]  dmi_req_bits_addr;
    logic [1:0]  dmi_req_bits_op;
    logic [31:0] dmi_req_bits_data;

    logic rtc_i;
    assign rtc_i = 1'b0;

    assign test_en = 1'b0;
    assign ndmreset_n = ~ndmreset ;
    assign debug_ndreset = ndmreset_n;
   
    localparam NB_SLAVE = 4;
    localparam NB_MASTER = 5;

    localparam AXI_ID_WIDTH_SLAVES = AXI_ID_WIDTH + $clog2(NB_SLAVE);

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH    ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH      ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH    )
    ) slave[NB_SLAVE-1:0]();

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH      ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVES ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH      )
    ) master[NB_MASTER-1:0]();

    // ---------------
    // Debug
    // ---------------
    assign init_done = ~reset;

    dm::dmi_req_t  jtag_dmi_req;

    dm::dmi_resp_t debug_resp;

    dmi_jtag i_dmi_jtag (
        .clk_i            ( clock           ),
        .rst_ni           ( ~reset          ),
        .testmode_i       ( test_en         ),
        .dmi_req_o        ( jtag_dmi_req    ),
        .dmi_req_valid_o  ( jtag_req_valid  ),
        .dmi_req_ready_i  ( debug_req_ready ),
        .dmi_resp_i       ( debug_resp      ),
        .dmi_resp_ready_o ( jtag_resp_ready ),
        .dmi_resp_valid_i ( jtag_resp_valid ),
        .dmi_rst_no       (                 ), // not connected
        .tck_i            ( debug_systemjtag_jtag_TCK        ),
        .tms_i            ( debug_systemjtag_jtag_TMS        ),
        .trst_ni          ( ~debug_systemjtag_reset          ),
        .td_i             ( debug_systemjtag_jtag_TDI        ),
        .td_o             ( debug_systemjtag_jtag_TDO_data   ),
        .tdo_oe_o         ( debug_systemjtag_jtag_TDO_driven )
    );

    // debug module
    dm_top #(
        // current implementation only supports 1 hart
        .NrHarts              ( 1                    ),
        .AxiIdWidth           ( AXI_ID_WIDTH_SLAVES  ),
        .AxiAddrWidth         ( AXI_ADDRESS_WIDTH    ),
        .AxiDataWidth         ( AXI_DATA_WIDTH       ),
        .AxiUserWidth         ( AXI_USER_WIDTH       )
    ) i_dm_top (
        .clk_i                ( clock                ),
        .rst_ni               ( ~reset               ), // PoR
        .testmode_i           ( test_en              ),
        .ndmreset_o           ( ndmreset             ),
        .dmactive_o           ( debug_dmactive       ), // active debug session
        .debug_req_o          ( debug_req_core       ),
        .unavailable_i        ( '0                   ),
        .axi_master           ( slave[3]             ),
        .axi_slave            ( master[4]            ),
        .dmi_rst_ni           ( ~reset               ),
        .dmi_req_valid_i      ( jtag_req_valid       ),
        .dmi_req_ready_o      ( debug_req_ready      ),
        .dmi_req_i            ( jtag_dmi_req         ),
        .dmi_resp_valid_o     ( jtag_resp_valid      ),
        .dmi_resp_ready_i     ( jtag_resp_ready      ),
        .dmi_resp_o           ( debug_resp           )
    );

    // ---------------
    // ROM
    // ---------------
    logic                         rom_req;
    logic [AXI_ADDRESS_WIDTH-1:0] rom_addr;
    logic [AXI_DATA_WIDTH-1:0]    rom_rdata;

    axi2mem #(
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVES ),
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH      ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH      )
    ) i_axi2rom (
        .clk_i  ( clock      ),
        .rst_ni ( ndmreset_n ),
        .slave  ( master[3]  ),
        .req_o  ( rom_req    ),
        .we_o   (            ),
        .addr_o ( rom_addr   ),
        .be_o   (            ),
        .data_o (            ),
        .data_i ( rom_rdata  )
    );

    bootrom i_bootrom (
        .clk_i      ( clock     ),
        .req_i      ( rom_req   ),
        .addr_i     ( rom_addr  ),
        .rdata_o    ( rom_rdata )
    );

   

    // ---------------
    // AXI Xbar
    // ---------------
    axi_node_intf_wrap #(
        // three ports from Ariane (instruction, data and bypass)
        .NB_SLAVE       ( NB_SLAVE          ),
        .NB_MASTER      ( NB_MASTER         ), // debug unit, memory unit
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH    ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH    ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH      )
    ) i_axi_xbar (
        .clk          ( clock                                                       ),
        .rst_n        ( ndmreset_n                                                  ),
        .test_en_i    ( test_en                                                     ),
        .slave        ( slave                                                       ),
        .master       ( master                                                      ),
        .start_addr_i ( {64'h0,   64'h10000, 64'h2000000, 64'h40000000, 64'h80000000} ),
        .end_addr_i   ( {64'hFFF, 64'h1FFFF, 64'h2FFFFFF, 64'h41000000, 64'h88000000} )
    );

    // ---------------
    // CLINT
    // ---------------
    logic ipi;
    logic timer_irq;

    clint #(
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH      ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVES ),
        .NR_CORES       ( 1                   )
    ) i_clint (
        .clk_i       ( clock     ),
        .rst_ni      ( ~reset    ),
        .testmode_i  ( test_en   ),
        .slave       ( master[2] ),
        .rtc_i       ( rtc_i     ),
        .timer_irq_o ( timer_irq ),
        .ipi_o       ( ipi       )
    );

    // ---------------
    // Core
    // ---------------
    ariane #(
        .CACHE_START_ADDR ( 64'h80000000     ),
        .AXI_ID_WIDTH     ( AXI_ID_WIDTH     ),
        .AXI_USER_WIDTH   ( AXI_USER_WIDTH   )
    ) i_ariane (
        .clk_i                ( clock            ),
        .rst_ni               ( ndmreset_n       ),
        .boot_addr_i          ( io_reset_vector  ), // start fetching from ROM
        .core_id_i            ( '0               ),
        .cluster_id_i         ( '0               ),
        .irq_i                ( interrupts       ),
        .ipi_i                ( ipi              ),
        .time_irq_i           ( timer_irq        ),
        .debug_req_i          ( debug_req_core   ),
        .data_if              ( slave[2]         ),
        .bypass_if            ( slave[1]         ),
        .instr_if             ( slave[0]         )
    );

slave_adapter
  #(
    .ID_WIDTH(AXI_ID_WIDTH_SLAVES),                 // id width
    .ADDR_WIDTH(AXI_ADDRESS_WIDTH),             // address width
    .DATA_WIDTH(AXI_DATA_WIDTH),             // width of data
    .USER_WIDTH(AXI_USER_WIDTH)              // width of user field, must > 0, let synthesizer trim it if not in use
    )
 sadapt_mem (
  .s_axi_awid(master[0].aw_id),
  .s_axi_awaddr(master[0].aw_addr),
  .s_axi_awlen(master[0].aw_len),
  .s_axi_awsize(master[0].aw_size),
  .s_axi_awburst(master[0].aw_burst),
  .s_axi_awlock(master[0].aw_lock),
  .s_axi_awcache(master[0].aw_cache),
  .s_axi_awprot(master[0].aw_prot),
  .s_axi_awregion(master[0].aw_region),
  .s_axi_awqos(master[0].aw_qos),
  .s_axi_awuser(master[0].aw_user),
  .s_axi_awvalid(master[0].aw_valid),
  .s_axi_awready(master[0].aw_ready),
  .s_axi_wdata(master[0].w_data),
  .s_axi_wstrb(master[0].w_strb),
  .s_axi_wlast(master[0].w_last),
  .s_axi_wuser(master[0].w_user),
  .s_axi_wvalid(master[0].w_valid),
  .s_axi_wready(master[0].w_ready),
  .s_axi_bid(master[0].b_id),
  .s_axi_bresp(master[0].b_resp),
  .s_axi_buser(master[0].b_user),
  .s_axi_bvalid(master[0].b_valid),
  .s_axi_bready(master[0].b_ready),
  .s_axi_arid(master[0].ar_id),
  .s_axi_araddr(master[0].ar_addr),
  .s_axi_arlen(master[0].ar_len),
  .s_axi_arsize(master[0].ar_size),
  .s_axi_arburst(master[0].ar_burst),
  .s_axi_arlock(master[0].ar_lock),
  .s_axi_arcache(master[0].ar_cache),
  .s_axi_arprot(master[0].ar_prot),
  .s_axi_arregion(master[0].ar_region),
  .s_axi_arqos(master[0].ar_qos),
  .s_axi_aruser(master[0].ar_user),
  .s_axi_arvalid(master[0].ar_valid),
  .s_axi_arready(master[0].ar_ready),
  .s_axi_rid(master[0].r_id),
  .s_axi_rdata(master[0].r_data),
  .s_axi_rresp(master[0].r_resp),
  .s_axi_rlast(master[0].r_last),
  .s_axi_ruser(master[0].r_user),
  .s_axi_rvalid(master[0].r_valid),
  .s_axi_rready(master[0].r_ready),
      .m_axi_awid           ( mem_axi4_0_aw_bits_id      ),
      .m_axi_awaddr         ( mem_axi4_0_aw_bits_addr    ),
      .m_axi_awlen          ( mem_axi4_0_aw_bits_len     ),
      .m_axi_awsize         ( mem_axi4_0_aw_bits_size    ),
      .m_axi_awburst        ( mem_axi4_0_aw_bits_burst   ),
      .m_axi_awlock         ( mem_axi4_0_aw_bits_lock    ),
      .m_axi_awcache        ( mem_axi4_0_aw_bits_cache   ),
      .m_axi_awprot         ( mem_axi4_0_aw_bits_prot    ),
      .m_axi_awqos          ( mem_axi4_0_aw_bits_qos     ),
      .m_axi_awuser         ( /*mem_axi4_0_aw_user*/    ),
      .m_axi_awregion       ( /*mem_axi4_0_aw_region*/  ),
      .m_axi_awvalid        ( mem_axi4_0_aw_valid   ),
      .m_axi_awready        ( mem_axi4_0_aw_ready   ),
      .m_axi_wdata          ( mem_axi4_0_w_bits_data     ),
      .m_axi_wstrb          ( mem_axi4_0_w_bits_strb     ),
      .m_axi_wlast          ( mem_axi4_0_w_bits_last     ),
      .m_axi_wuser          ( /*mem_axi4_0_w_user*/     ),
      .m_axi_wvalid         ( mem_axi4_0_w_valid    ),
      .m_axi_wready         ( mem_axi4_0_w_ready    ),
      .m_axi_bid            ( mem_axi4_0_b_bits_id       ),
      .m_axi_bresp          ( mem_axi4_0_b_bits_resp     ),
      .m_axi_buser          ( /*mem_axi4_0_b_user*/     ),
      .m_axi_bvalid         ( mem_axi4_0_b_valid    ),
      .m_axi_bready         ( mem_axi4_0_b_ready    ),
      .m_axi_arid           ( mem_axi4_0_ar_bits_id      ),
      .m_axi_araddr         ( mem_axi4_0_ar_bits_addr    ),
      .m_axi_arlen          ( mem_axi4_0_ar_bits_len     ),
      .m_axi_arsize         ( mem_axi4_0_ar_bits_size    ),
      .m_axi_arburst        ( mem_axi4_0_ar_bits_burst   ),
      .m_axi_arlock         ( mem_axi4_0_ar_bits_lock    ),
      .m_axi_arcache        ( mem_axi4_0_ar_bits_cache   ),
      .m_axi_arprot         ( mem_axi4_0_ar_bits_prot    ),
      .m_axi_arqos          ( mem_axi4_0_ar_bits_qos     ),
      .m_axi_aruser         ( /*mem_axi4_0_ar_user*/    ),
      .m_axi_arregion       ( /*mem_axi4_0_ar_region*/  ),
      .m_axi_arvalid        ( mem_axi4_0_ar_valid   ),
      .m_axi_arready        ( mem_axi4_0_ar_ready   ),
      .m_axi_rid            ( mem_axi4_0_r_bits_id       ),
      .m_axi_rdata          ( mem_axi4_0_r_bits_data     ),
      .m_axi_rresp          ( mem_axi4_0_r_bits_resp     ),
      .m_axi_rlast          ( mem_axi4_0_r_bits_last     ),
      .m_axi_ruser          ( /*mem_axi4_0_r_user*/     ),
      .m_axi_rvalid         ( mem_axi4_0_r_valid    ),
      .m_axi_rready         ( mem_axi4_0_r_ready    )
        );

slave_adapter
  #(
    .ID_WIDTH(AXI_ID_WIDTH_SLAVES),                 // id width
    .ADDR_WIDTH(AXI_ADDRESS_WIDTH),             // address width
    .DATA_WIDTH(AXI_DATA_WIDTH),             // width of data
    .USER_WIDTH(AXI_USER_WIDTH)              // width of user field, must > 0, let synthesizer trim it if not in use
    )
 sadapt_mmio (
  .s_axi_awid(master[1].aw_id),
  .s_axi_awaddr(master[1].aw_addr),
  .s_axi_awlen(master[1].aw_len),
  .s_axi_awsize(master[1].aw_size),
  .s_axi_awburst(master[1].aw_burst),
  .s_axi_awlock(master[1].aw_lock),
  .s_axi_awcache(master[1].aw_cache),
  .s_axi_awprot(master[1].aw_prot),
  .s_axi_awregion(master[1].aw_region),
  .s_axi_awqos(master[1].aw_qos),
  .s_axi_awuser(master[1].aw_user),
  .s_axi_awvalid(master[1].aw_valid),
  .s_axi_awready(master[1].aw_ready),
  .s_axi_wdata(master[1].w_data),
  .s_axi_wstrb(master[1].w_strb),
  .s_axi_wlast(master[1].w_last),
  .s_axi_wuser(master[1].w_user),
  .s_axi_wvalid(master[1].w_valid),
  .s_axi_wready(master[1].w_ready),
  .s_axi_bid(master[1].b_id),
  .s_axi_bresp(master[1].b_resp),
  .s_axi_buser(master[1].b_user),
  .s_axi_bvalid(master[1].b_valid),
  .s_axi_bready(master[1].b_ready),
  .s_axi_arid(master[1].ar_id),
  .s_axi_araddr(master[1].ar_addr),
  .s_axi_arlen(master[1].ar_len),
  .s_axi_arsize(master[1].ar_size),
  .s_axi_arburst(master[1].ar_burst),
  .s_axi_arlock(master[1].ar_lock),
  .s_axi_arcache(master[1].ar_cache),
  .s_axi_arprot(master[1].ar_prot),
  .s_axi_arregion(master[1].ar_region),
  .s_axi_arqos(master[1].ar_qos),
  .s_axi_aruser(master[1].ar_user),
  .s_axi_arvalid(master[1].ar_valid),
  .s_axi_arready(master[1].ar_ready),
  .s_axi_rid(master[1].r_id),
  .s_axi_rdata(master[1].r_data),
  .s_axi_rresp(master[1].r_resp),
  .s_axi_rlast(master[1].r_last),
  .s_axi_ruser(master[1].r_user),
  .s_axi_rvalid(master[1].r_valid),
  .s_axi_rready(master[1].r_ready),
      .m_axi_awid           ( mmio_axi4_0_aw_bits_id      ),
      .m_axi_awaddr         ( mmio_axi4_0_aw_bits_addr    ),
      .m_axi_awlen          ( mmio_axi4_0_aw_bits_len     ),
      .m_axi_awsize         ( mmio_axi4_0_aw_bits_size    ),
      .m_axi_awburst        ( mmio_axi4_0_aw_bits_burst   ),
      .m_axi_awlock         ( mmio_axi4_0_aw_bits_lock    ),
      .m_axi_awcache        ( mmio_axi4_0_aw_bits_cache   ),
      .m_axi_awprot         ( mmio_axi4_0_aw_bits_prot    ),
      .m_axi_awqos          ( mmio_axi4_0_aw_bits_qos     ),
      .m_axi_awuser         ( /*mmio_axi4_0_aw_user*/    ),
      .m_axi_awregion       ( /*mmio_axi4_0_aw_region*/  ),
      .m_axi_awvalid        ( mmio_axi4_0_aw_valid   ),
      .m_axi_awready        ( mmio_axi4_0_aw_ready   ),
      .m_axi_wdata          ( mmio_axi4_0_w_bits_data     ),
      .m_axi_wstrb          ( mmio_axi4_0_w_bits_strb     ),
      .m_axi_wlast          ( mmio_axi4_0_w_bits_last     ),
      .m_axi_wuser          ( /*mmio_axi4_0_w_user*/     ),
      .m_axi_wvalid         ( mmio_axi4_0_w_valid    ),
      .m_axi_wready         ( mmio_axi4_0_w_ready    ),
      .m_axi_bid            ( mmio_axi4_0_b_bits_id       ),
      .m_axi_bresp          ( mmio_axi4_0_b_bits_resp     ),
      .m_axi_buser          ( /*mmio_axi4_0_b_user*/     ),
      .m_axi_bvalid         ( mmio_axi4_0_b_valid    ),
      .m_axi_bready         ( mmio_axi4_0_b_ready    ),
      .m_axi_arid           ( mmio_axi4_0_ar_bits_id      ),
      .m_axi_araddr         ( mmio_axi4_0_ar_bits_addr    ),
      .m_axi_arlen          ( mmio_axi4_0_ar_bits_len     ),
      .m_axi_arsize         ( mmio_axi4_0_ar_bits_size    ),
      .m_axi_arburst        ( mmio_axi4_0_ar_bits_burst   ),
      .m_axi_arlock         ( mmio_axi4_0_ar_bits_lock    ),
      .m_axi_arcache        ( mmio_axi4_0_ar_bits_cache   ),
      .m_axi_arprot         ( mmio_axi4_0_ar_bits_prot    ),
      .m_axi_arqos          ( mmio_axi4_0_ar_bits_qos     ),
      .m_axi_aruser         ( /*mmio_axi4_0_ar_user*/    ),
      .m_axi_arregion       ( /*mmio_axi4_0_ar_region*/  ),
      .m_axi_arvalid        ( mmio_axi4_0_ar_valid   ),
      .m_axi_arready        ( mmio_axi4_0_ar_ready   ),
      .m_axi_rid            ( mmio_axi4_0_r_bits_id       ),
      .m_axi_rdata          ( mmio_axi4_0_r_bits_data     ),
      .m_axi_rresp          ( mmio_axi4_0_r_bits_resp     ),
      .m_axi_rlast          ( mmio_axi4_0_r_bits_last     ),
      .m_axi_ruser          ( /*mmio_axi4_0_r_user*/     ),
      .m_axi_rvalid         ( mmio_axi4_0_r_valid    ),
      .m_axi_rready         ( mmio_axi4_0_r_ready    )
        );
   
endmodule
