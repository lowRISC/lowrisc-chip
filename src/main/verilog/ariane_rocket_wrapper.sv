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

   wire mem_axi4_0_aw_region;
   wire mem_axi4_0_ar_region;
   wire mmio_axi4_0_aw_region;
   wire mmio_axi4_0_ar_region;
  
  // Tracing
   tracer_t tracer;
   
   logic             test_en_i = 'b1; // enable all clock gates for testing
   // Core ID; Cluster ID and boot address are considered more or less static
   logic [ 3:0]      core_id_i = 'b0;
   logic [ 5:0]      cluster_id_i = 'b0;
   logic             sec_lvl_o; // current privilege level oot
   // Timer facilities
   logic [63:0]      time_i, mtimecmp; // global time (most probably coming from an RTC)
   logic             time_irq_i; // timer interrupt in
   
   genvar        i;

   // internal clock and reset signals
   wire aresetn = !reset;

always @(posedge clock)
    begin
    if (!aresetn)
        time_i = 'b0;
    else
        time_i = time_i + 1'b1;
        time_irq_i = time_i >= mtimecmp;
    end
    
   // the NASTI bus for off-FPGA DRAM, converted to High frequency
   nasti_channel   
     #(
       .ID_WIDTH    ( 10 ),
       .ADDR_WIDTH  ( 32 ),
       .DATA_WIDTH  ( 64 ))
   mem_mig_nasti();

    AXI_BUS #(
              .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH ),
              .AXI_DATA_WIDTH ( AXI_DATA_WIDTH    ),
              .AXI_ID_WIDTH   ( AXI_ID_WIDTH      ),
              .AXI_USER_WIDTH ( AXI_USER_WIDTH    )
              ) instr_if(), data_if(), bypass_if();

   // interrupt lines from peripherals
   wire [63:0]                 minten, sinten;
   wire [INTERRUPT_COUNT-1:0]                  minterrupt = interrupts & minten;
   wire [INTERRUPT_COUNT-1:0]                  sinterrupt = interrupts & sinten;
   // Ariane nterrupts in
   wire [1:0]                  irq_i = {|minterrupt,|sinterrupt}; // level sensitive IR lines; meip & seip
   logic                       ipi_i = 'b0; // inter-processor interrupts

    logic        flush_dcache_ack_o, flush_dcache_i = 1'b0;
    
    ariane #(
        .AXI_ID_WIDTH     ( AXI_ID_WIDTH     ),
        .AXI_USER_WIDTH   ( AXI_USER_WIDTH   )
    ) i_ariane (
        .*,
        .clk_i                  ( clock                ),
        .tracer                 ( tracer               ),
        .rst_ni                 ( aresetn              ),
        .flush_dcache_i         ( flush_dcache_i       ),
        .flush_dcache_ack_o     ( flush_dcache_ack_o   ),
        .data_if                ( data_if              ),
        .bypass_if              ( bypass_if            ),
        .instr_if               ( instr_if             ),
        .boot_addr_i            ( 64'h40000000         ),
        .mtimecmp_o             ( mtimecmp             ),
        .minten_o               ( minten               ),
        .sinten_o               ( sinten               )
        );

        // Debug Interface
   logic                                 debug_gnt_o;
   logic                                 debug_halt_i = 'b0;
   logic                                 debug_resume_i = 'b0;
   logic                                 debug_rvalid_o;
   logic [15:0]                          debug_addr_i = 'b0;
   logic                                 debug_we_i = 'b0;
   logic [63:0]                          debug_wdata_i = 'b0;
   logic [63:0]                          debug_rdata_o;
   logic                                 debug_halted_o;
   logic                                 debug_req_i = 'b0;
         
   // CPU Control Signals
   logic                                 fetch_enable_i = 'b1; 
 
 //  crossbar_socip
axi_crossbar_0 crossbar (
  .aclk(clock),                      // input wire wire aclk
  .aresetn(aresetn),                // input wire wire aresetn
  .s_axi_awid({bypass_if.aw_id,data_if.aw_id,instr_if.aw_id}),          // input wire wire [29 : 0] s_axi_awid
  .s_axi_awaddr({bypass_if.aw_addr,data_if.aw_addr,instr_if.aw_addr}),      // input wire wire [191 : 0] s_axi_awaddr
  .s_axi_awlen({bypass_if.aw_len,data_if.aw_len,instr_if.aw_len}),        // input wire wire [23 : 0] s_axi_awlen
  .s_axi_awsize({bypass_if.aw_size,data_if.aw_size,instr_if.aw_size}),      // input wire wire [8 : 0] s_axi_awsize
  .s_axi_awburst({bypass_if.aw_burst,data_if.aw_burst,instr_if.aw_burst}),    // input wire wire [5 : 0] s_axi_awburst
  .s_axi_awlock({bypass_if.aw_lock,data_if.aw_lock,instr_if.aw_lock}),      // input wire wire [2 : 0] s_axi_awlock
  .s_axi_awcache({bypass_if.aw_cache,data_if.aw_cache,instr_if.aw_cache}),    // input wire wire [11 : 0] s_axi_awcache
  .s_axi_awprot({bypass_if.aw_prot,data_if.aw_prot,instr_if.aw_prot}),      // input wire wire [8 : 0] s_axi_awprot
  .s_axi_awqos({bypass_if.aw_qos,data_if.aw_qos,instr_if.aw_qos}),        // input wire wire [11 : 0] s_axi_awqos
//  .s_axi_awuser({bypass_if.aw_user,data_if.aw_user,instr_if.aw_user}),      // input wire wire [2 : 0] s_axi_awuser
  .s_axi_awvalid({bypass_if.aw_valid,data_if.aw_valid,instr_if.aw_valid}),    // input wire wire [2 : 0] s_axi_awvalid
  .s_axi_awready({bypass_if.aw_ready,data_if.aw_ready,instr_if.aw_ready}),    // output wire wire [2 : 0] s_axi_awready
  .s_axi_wdata({bypass_if.w_data,data_if.w_data,instr_if.w_data}),        // input wire wire [191 : 0] s_axi_wdata
  .s_axi_wstrb({bypass_if.w_strb,data_if.w_strb,instr_if.w_strb}),        // input wire wire [23 : 0] s_axi_wstrb
  .s_axi_wlast({bypass_if.w_last,data_if.w_last,instr_if.w_last}),        // input wire wire [2 : 0] s_axi_wlast
//  .s_axi_wuser({bypass_if.w_user,data_if.w_user,instr_if.w_user}),        // input wire wire [2 : 0] s_axi_wuser
  .s_axi_wvalid({bypass_if.w_valid,data_if.w_valid,instr_if.w_valid}),      // input wire wire [2 : 0] s_axi_wvalid
  .s_axi_wready({bypass_if.w_ready,data_if.w_ready,instr_if.w_ready}),      // output wire wire [2 : 0] s_axi_wready
  .s_axi_bid({bypass_if.b_id,data_if.b_id,instr_if.b_id}),            // output wire wire [29 : 0] s_axi_bid
  .s_axi_bresp({bypass_if.b_resp,data_if.b_resp,instr_if.b_resp}),        // output wire wire [5 : 0] s_axi_bresp
//  .s_axi_buser({bypass_if.b_user,data_if.b_user,instr_if.b_user}),        // output wire wire [2 : 0] s_axi_buser
  .s_axi_bvalid({bypass_if.b_valid,data_if.b_valid,instr_if.b_valid}),      // output wire wire [2 : 0] s_axi_bvalid
  .s_axi_bready({bypass_if.b_ready,data_if.b_ready,instr_if.b_ready}),      // input wire wire [2 : 0] s_axi_bready
  .s_axi_arid({bypass_if.ar_id,data_if.ar_id,instr_if.ar_id}),          // input wire wire [29 : 0] s_axi_arid
  .s_axi_araddr({bypass_if.ar_addr,data_if.ar_addr,instr_if.ar_addr}),      // input wire wire [191 : 0] s_axi_araddr
  .s_axi_arlen({bypass_if.ar_len,data_if.ar_len,instr_if.ar_len}),        // input wire wire [23 : 0] s_axi_arlen
  .s_axi_arsize({bypass_if.ar_size,data_if.ar_size,instr_if.ar_size}),      // input wire wire [8 : 0] s_axi_arsize
  .s_axi_arburst({bypass_if.ar_burst,data_if.ar_burst,instr_if.ar_burst}),    // input wire wire [5 : 0] s_axi_arburst
  .s_axi_arlock({bypass_if.ar_lock,data_if.ar_lock,instr_if.ar_lock}),      // input wire wire [2 : 0] s_axi_arlock
  .s_axi_arcache({bypass_if.ar_cache,data_if.ar_cache,instr_if.ar_cache}),    // input wire wire [11 : 0] s_axi_arcache
  .s_axi_arprot({bypass_if.ar_prot,data_if.ar_prot,instr_if.ar_prot}),      // input wire wire [8 : 0] s_axi_arprot
  .s_axi_arqos({bypass_if.ar_qos,data_if.ar_qos,instr_if.ar_qos}),        // input wire wire [11 : 0] s_axi_arqos
//  .s_axi_aruser({bypass_if.ar_user,data_if.ar_user,instr_if.ar_user}),      // input wire wire [2 : 0] s_axi_aruser
  .s_axi_arvalid({bypass_if.ar_valid,data_if.ar_valid,instr_if.ar_valid}),    // input wire wire [2 : 0] s_axi_arvalid
  .s_axi_arready({bypass_if.ar_ready,data_if.ar_ready,instr_if.ar_ready}),    // output wire wire [2 : 0] s_axi_arready
  .s_axi_rid({bypass_if.r_id,data_if.r_id,instr_if.r_id}),            // output wire wire [29 : 0] s_axi_rid
  .s_axi_rdata({bypass_if.r_data,data_if.r_data,instr_if.r_data}),        // output wire wire [191 : 0] s_axi_rdata
  .s_axi_rresp({bypass_if.r_resp,data_if.r_resp,instr_if.r_resp}),        // output wire wire [5 : 0] s_axi_rresp
  .s_axi_rlast({bypass_if.r_last,data_if.r_last,instr_if.r_last}),        // output wire wire [2 : 0] s_axi_rlast
//  .s_axi_ruser({bypass_if.r_user,data_if.r_user,instr_if.r_user}),        // output wire wire [2 : 0] s_axi_ruser
  .s_axi_rvalid({bypass_if.r_valid,data_if.r_valid,instr_if.r_valid}),      // output wire wire [2 : 0] s_axi_rvalid
  .s_axi_rready({bypass_if.r_ready,data_if.r_ready,instr_if.r_ready}),      // input wire wire [2 : 0] s_axi_rready
  .m_axi_awid({mmio_axi4_0_aw_bits_id,mem_axi4_0_aw_bits_id}),          // input wire wire [29 : 0] s_axi_awid
  .m_axi_awaddr({mmio_axi4_0_aw_bits_addr,mem_axi4_0_aw_bits_addr}),      // input wire wire [191 : 0] s_axi_awaddr
  .m_axi_awlen({mmio_axi4_0_aw_bits_len,mem_axi4_0_aw_bits_len}),        // input wire wire [23 : 0] s_axi_awlen
  .m_axi_awsize({mmio_axi4_0_aw_bits_size,mem_axi4_0_aw_bits_size}),      // input wire wire [8 : 0] s_axi_awsize
  .m_axi_awburst({mmio_axi4_0_aw_bits_burst,mem_axi4_0_aw_bits_burst}),    // input wire wire [5 : 0] s_axi_awburst
  .m_axi_awlock({mmio_axi4_0_aw_bits_lock,mem_axi4_0_aw_bits_lock}),      // input wire wire [2 : 0] s_axi_awlock
  .m_axi_awcache({mmio_axi4_0_aw_bits_cache,mem_axi4_0_aw_bits_cache}),    // input wire wire [11 : 0] s_axi_awcache
  .m_axi_awprot({mmio_axi4_0_aw_bits_prot,mem_axi4_0_aw_bits_prot}),      // input wire wire [8 : 0] s_axi_awprot
  .m_axi_awqos({mmio_axi4_0_aw_bits_qos,mem_axi4_0_aw_bits_qos}),        // input wire wire [11 : 0] s_axi_awqos
//  .m_axi_awuser({mmio_axi4_0_aw_user,mem_axi4_0_aw_user}),      // input wire wire [2 : 0] s_axi_awuser
  .m_axi_awvalid({mmio_axi4_0_aw_valid,mem_axi4_0_aw_valid}),    // input wire wire [2 : 0] s_axi_awvalid
  .m_axi_awready({mmio_axi4_0_aw_ready,mem_axi4_0_aw_ready}),    // output wire wire [2 : 0] s_axi_awready
  .m_axi_awregion({mmio_axi4_0_aw_region,mem_axi4_0_aw_region}),    // output wire s_axi_awregion
  .m_axi_wdata({mmio_axi4_0_w_bits_data,mem_axi4_0_w_bits_data}),        // input wire wire [191 : 0] s_axi_wdata
  .m_axi_wstrb({mmio_axi4_0_w_bits_strb,mem_axi4_0_w_bits_strb}),        // input wire wire [23 : 0] s_axi_wstrb
  .m_axi_wlast({mmio_axi4_0_w_bits_last,mem_axi4_0_w_bits_last}),        // input wire wire [2 : 0] s_axi_wlast
//  .m_axi_wuser({mmio_axi4_0_w_user,mem_axi4_0_w_user}),        // input wire wire [2 : 0] s_axi_wuser
  .m_axi_wvalid({mmio_axi4_0_w_valid,mem_axi4_0_w_valid}),      // input wire wire [2 : 0] s_axi_wvalid
  .m_axi_wready({mmio_axi4_0_w_ready,mem_axi4_0_w_ready}),      // output wire wire [2 : 0] s_axi_wready
  .m_axi_bid({mmio_axi4_0_b_bits_id,mem_axi4_0_b_bits_id}),            // output wire wire [29 : 0] s_axi_bid
  .m_axi_bresp({mmio_axi4_0_b_bits_resp,mem_axi4_0_b_bits_resp}),        // output wire wire [5 : 0] s_axi_bresp
//  .m_axi_buser({mmio_axi4_0_b_user,mem_axi4_0_b_user}),        // output wire wire [2 : 0] s_axi_buser
  .m_axi_bvalid({mmio_axi4_0_b_valid,mem_axi4_0_b_valid}),      // output wire wire [2 : 0] s_axi_bvalid
  .m_axi_bready({mmio_axi4_0_b_ready,mem_axi4_0_b_ready}),      // input wire wire [2 : 0] s_axi_bready
  .m_axi_arid({mmio_axi4_0_ar_bits_id,mem_axi4_0_ar_bits_id}),          // input wire wire [29 : 0] s_axi_arid
  .m_axi_araddr({mmio_axi4_0_ar_bits_addr,mem_axi4_0_ar_bits_addr}),      // input wire wire [191 : 0] s_axi_araddr
  .m_axi_arlen({mmio_axi4_0_ar_bits_len,mem_axi4_0_ar_bits_len}),        // input wire wire [23 : 0] s_axi_arlen
  .m_axi_arsize({mmio_axi4_0_ar_bits_size,mem_axi4_0_ar_bits_size}),      // input wire wire [8 : 0] s_axi_arsize
  .m_axi_arburst({mmio_axi4_0_ar_bits_burst,mem_axi4_0_ar_bits_burst}),    // input wire wire [5 : 0] s_axi_arburst
  .m_axi_arlock({mmio_axi4_0_ar_bits_lock,mem_axi4_0_ar_bits_lock}),      // input wire wire [2 : 0] s_axi_arlock
  .m_axi_arcache({mmio_axi4_0_ar_bits_cache,mem_axi4_0_ar_bits_cache}),    // input wire wire [11 : 0] s_axi_arcache
  .m_axi_arprot({mmio_axi4_0_ar_bits_prot,mem_axi4_0_ar_bits_prot}),      // input wire wire [8 : 0] s_axi_arprot
  .m_axi_arqos({mmio_axi4_0_ar_bits_qos,mem_axi4_0_ar_bits_qos}),        // input wire wire [11 : 0] s_axi_arqos
//  .m_axi_aruser({mmio_axi4_0_ar_user,mem_axi4_0_ar_user}),      // input wire wire [2 : 0] s_axi_aruser
  .m_axi_arvalid({mmio_axi4_0_ar_valid,mem_axi4_0_ar_valid}),    // input wire wire [2 : 0] s_axi_arvalid
  .m_axi_arready({mmio_axi4_0_ar_ready,mem_axi4_0_ar_ready}),    // output wire wire [2 : 0] s_axi_arready
  .m_axi_arregion({mmio_axi4_0_ar_region,mem_axi4_0_ar_region}),    // output wire s_axi_arregion
  .m_axi_rid({mmio_axi4_0_r_bits_id,mem_axi4_0_r_bits_id}),            // output wire wire [29 : 0] s_axi_rid
  .m_axi_rdata({mmio_axi4_0_r_bits_data,mem_axi4_0_r_bits_data}),        // output wire wire [191 : 0] s_axi_rdata
  .m_axi_rresp({mmio_axi4_0_r_bits_resp,mem_axi4_0_r_bits_resp}),        // output wire wire [5 : 0] s_axi_rresp
  .m_axi_rlast({mmio_axi4_0_r_bits_last,mem_axi4_0_r_bits_last}),        // output wire wire [2 : 0] s_axi_rlast
//  .m_axi_ruser({mmio_axi4_0_r_user,mem_axi4_0_r_user}),        // output wire wire [2 : 0] s_axi_ruser
  .m_axi_rvalid({mmio_axi4_0_r_valid,mem_axi4_0_r_valid}),      // output wire wire [2 : 0] s_axi_rvalid
  .m_axi_rready({mmio_axi4_0_r_ready,mem_axi4_0_r_ready})      // input wire wire [2 : 0] s_axi_rready
);
   
endmodule
