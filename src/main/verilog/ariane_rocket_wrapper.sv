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

module ExampleRocketSystem #(
        parameter logic [63:0] CACHE_START_ADDR = 64'h4000_0000, // address on which to decide whether the request is cache-able or not
        parameter logic [63:0] DDR_START_ADDR   = 64'h8000_0000, // address on which to decide whether the request is cache-able or not
        parameter logic [63:0] MMIO_START_ADDR  = 64'h4100_0000, // address on which to decide whether the request is cache-able or not
        parameter int unsigned AXI_ID_WIDTH = 4, // minimum 1
        parameter int unsigned AXI_USER_WIDTH = 1, // minimum 1
        parameter int unsigned AXI_ADDRESS_WIDTH = 64,
        parameter int unsigned AXI_DATA_WIDTH = 64,
        parameter int unsigned DDR_NUM_WORDS         = 2**24,          // memory size
        parameter int unsigned MMIO_NUM_WORDS        = 2**20,          // mmio size
        parameter int unsigned INTERRUPT_COUNT = 4
    ) (
  input wire         clock,
  input wire         reset,
  input wire         debug_systemjtag_jtag_TCK,
  input wire         debug_systemjtag_jtag_TMS,
  input wire         debug_systemjtag_jtag_TDI,
  output reg         debug_systemjtag_jtag_TDO_data,
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

    logic trap;
    logic [31:0] dbg_reg_x0;
    logic [31:0] dbg_reg_x1;
    logic [31:0] dbg_reg_x2;
    logic [31:0] dbg_reg_x3;
    logic [31:0] dbg_reg_x4;
    logic [31:0] dbg_reg_x5;
    logic [31:0] dbg_reg_x6;
    logic [31:0] dbg_reg_x7;
    logic [31:0] dbg_reg_x8;
    logic [31:0] dbg_reg_x9;
    logic [31:0] dbg_reg_x10;
    logic [31:0] dbg_reg_x11;
    logic [31:0] dbg_reg_x12;
    logic [31:0] dbg_reg_x13;
    logic [31:0] dbg_reg_x14;
    logic [31:0] dbg_reg_x15;
    logic [31:0] dbg_reg_x16;
    logic [31:0] dbg_reg_x17;
    logic [31:0] dbg_reg_x18;
    logic [31:0] dbg_reg_x19;
    logic [31:0] dbg_reg_x20;
    logic [31:0] dbg_reg_x21;
    logic [31:0] dbg_reg_x22;
    logic [31:0] dbg_reg_x23;
    logic [31:0] dbg_reg_x24;
    logic [31:0] dbg_reg_x25;
    logic [31:0] dbg_reg_x26;
    logic [31:0] dbg_reg_x27;
    logic [31:0] dbg_reg_x28;
    logic [31:0] dbg_reg_x29;
    logic [31:0] dbg_reg_x30;
    logic [31:0] dbg_reg_x31;
    logic [31:0] dbg_insn_opcode;
    logic [31:0] dbg_insn_addr;
    logic dbg_mem_valid;
    logic dbg_mem_instr;
    logic dbg_mem_ready;
    logic [31:0] dbg_mem_addr;
    logic [31:0] dbg_mem_wdata;
    logic [3:0] dbg_mem_wstrb;
    logic [31:0] dbg_mem_rdata;
    logic [63:0] dbg_ascii_instr;
    logic [31:0] dbg_insn_imm;
    logic [4:0] dbg_insn_rs1;
    logic [4:0] dbg_insn_rs2;
    logic [4:0] dbg_insn_rd;
    logic [31:0] dbg_rs1val;
    logic [31:0] dbg_rs2val;
    logic dbg_rs1val_valid;
    logic dbg_rs2val_valid;
    logic dbg_next;
    logic dbg_valid_insn;
    logic [127:0] dbg_ascii_state;
    logic trace_valid;
    logic [35:0] trace_data;
    logic [31:0] irq;
    logic mem_axi_awvalid;
    logic mem_axi_awready;
    logic [31:0] mem_axi_awaddr;
    logic [2:0] mem_axi_awprot;
    logic mem_axi_wvalid;
    logic mem_axi_wready;
    logic [31:0] mem_axi_wdata;
    logic [3:0] mem_axi_wstrb;
    logic mem_axi_bvalid;
    logic mem_axi_bready;
    logic mem_axi_arvalid;
    logic mem_axi_arready;
    logic [31:0] mem_axi_araddr;
    logic [2:0] mem_axi_arprot;
    logic mem_axi_rvalid;
    logic mem_axi_rready;
    logic [31:0] mem_axi_rdata;
    logic [1023:0] firmware_file;

  wire [63:0]m1_axi_awaddr;
  wire [2:0]m1_axi_awprot;
  wire m1_axi_awvalid;
  wire m1_axi_awready;
  wire [63:0]m1_axi_wdata;
  wire [7:0]m1_axi_wstrb;
  wire m1_axi_wvalid;
  wire m1_axi_wready;
  wire [1:0]m1_axi_bresp;
  wire m1_axi_bvalid;
  wire m1_axi_bready;
  wire [63:0]m1_axi_araddr;
  wire [2:0]m1_axi_arprot;
  wire m1_axi_arvalid;
  wire m1_axi_arready;
  wire [63:0]m1_axi_rdata;
  wire [1:0]m1_axi_rresp;
  wire m1_axi_rvalid;
  wire m1_axi_rready;
  wire [1:0] mem_axi_bresp;
  wire [1 : 0] mem_axi_rresp;
   wire [63 : 0] m2_axi_awaddr;
   wire [7 : 0]  m2_axi_awlen;
   wire [2 : 0]  m2_axi_awsize;
   wire [1 : 0]  m2_axi_awburst;
   wire [0 : 0]  m2_axi_awlock;
   wire [3 : 0]  m2_axi_awcache;
   wire [2 : 0]  m2_axi_awprot;
   wire [3 : 0]  m2_axi_awregion,mem_axi4_0_aw_bits_region,mmio_axi4_0_aw_bits_region,mem_axi4_0_ar_bits_region,mmio_axi4_0_ar_bits_region;
   wire [3 : 0]  m2_axi_awqos;
   wire      m2_axi_awvalid;
   wire      mem_axi4_0_aw_bits_user,mmio_axi4_0_aw_bits_user,mem_axi4_0_ar_bits_user,mmio_axi4_0_ar_bits_user;
   wire m2_axi_awready;
   wire mem_axi4_0_w_bits_user,mmio_axi4_0_w_bits_user;
   wire mem_axi4_0_b_bits_user = 1'b0,mmio_axi4_0_b_bits_user = 1'b0;
   wire mem_axi4_0_r_bits_user = 1'b0, mmio_axi4_0_r_bits_user = 1'b0;
   
wire [63 : 0] m2_axi_wdata;
wire [7 : 0] m2_axi_wstrb;
wire m2_axi_wlast;
wire m2_axi_wvalid;
wire m2_axi_wready;
wire [1 : 0] m2_axi_bresp;
wire m2_axi_bvalid;
wire m2_axi_bready;
wire [63 : 0] m2_axi_araddr;
wire [7 : 0] m2_axi_arlen;
wire [2 : 0] m2_axi_arsize;
wire [1 : 0] m2_axi_arburst;
wire [0 : 0] m2_axi_arlock;
wire [3 : 0] m2_axi_arcache;
wire [2 : 0] m2_axi_arprot;
wire [3 : 0] m2_axi_arregion;
wire [3 : 0] m2_axi_arqos;
wire m2_axi_arvalid;
wire m2_axi_arready;
wire [63 : 0] m2_axi_rdata;
wire [1 : 0] m2_axi_rresp;
wire m2_axi_rlast;
wire m2_axi_rvalid;
wire m2_axi_rready;
   wire [3 : 0] m2_axi_bid;
   wire [0 : 0] m2_axi_buser;
   wire [3 : 0] m2_axi_rid;
   wire [0 : 0] m2_axi_ruser;
   wire [3 : 0] m2_axi_awid = 4'b0;
   wire [3 : 0] m2_axi_arid = 4'b0;
   wire [0 : 0] m2_axi_aruser = trap;
   wire [0 : 0] m2_axi_wuser = 1'b0;
   wire [0 : 0] m2_axi_awuser = 1'b0;   
   wire         trig_in_ack;

    always @(posedge debug_systemjtag_jtag_TCK)
      debug_systemjtag_jtag_TDO_data = debug_systemjtag_jtag_TDI;
   
    assign irq = interrupts;
    assign debug_systemjtag_jtag_TDO_driven = 1'b1;
    assign debug_ndreset = debug_systemjtag_reset;
    assign debug_dmactive = 1'b0;
   
   axi_dwidth_converter_0 wconv1 (
  .s_axi_aclk(clock),        // input wire s_axi_aclk
  .s_axi_aresetn(!reset),  // input wire s_axi_aresetn
  .s_axi_awaddr({32'b0,mem_axi_awaddr}),    // input wire [63 : 0] s_axi_awaddr
  .s_axi_awprot(mem_axi_awprot),    // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(mem_axi_awvalid),  // input wire s_axi_awvalid
  .s_axi_awready(mem_axi_awready),  // output wire s_axi_awready
  .s_axi_wdata(mem_axi_wdata),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(mem_axi_wstrb),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(mem_axi_wvalid),    // input wire s_axi_wvalid
  .s_axi_wready(mem_axi_wready),    // output wire s_axi_wready
  .s_axi_bresp(mem_axi_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(mem_axi_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(mem_axi_bready),    // input wire s_axi_bready
  .s_axi_araddr({32'b0,mem_axi_araddr}),    // input wire [63 : 0] s_axi_araddr
  .s_axi_arprot(mem_axi_arprot),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(mem_axi_arvalid),  // input wire s_axi_arvalid
  .s_axi_arready(mem_axi_arready),  // output wire s_axi_arready
  .s_axi_rdata(mem_axi_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(mem_axi_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(mem_axi_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(mem_axi_rready),    // input wire s_axi_rready
  .m_axi_awaddr(m1_axi_awaddr),    // output wire [63 : 0] m_axi_awaddr
  .m_axi_awprot(m1_axi_awprot),    // output wire [2 : 0] m_axi_awprot
  .m_axi_awvalid(m1_axi_awvalid),  // output wire m_axi_awvalid
  .m_axi_awready(m1_axi_awready),  // input wire m_axi_awready
  .m_axi_wdata(m1_axi_wdata),      // output wire [63 : 0] m_axi_wdata
  .m_axi_wstrb(m1_axi_wstrb),      // output wire [7 : 0] m_axi_wstrb
  .m_axi_wvalid(m1_axi_wvalid),    // output wire m_axi_wvalid
  .m_axi_wready(m1_axi_wready),    // input wire m_axi_wready
  .m_axi_bresp(m1_axi_bresp),      // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(m1_axi_bvalid),    // input wire m_axi_bvalid
  .m_axi_bready(m1_axi_bready),    // output wire m_axi_bready
  .m_axi_araddr(m1_axi_araddr),    // output wire [63 : 0] m_axi_araddr
  .m_axi_arprot(m1_axi_arprot),    // output wire [2 : 0] m_axi_arprot
  .m_axi_arvalid(m1_axi_arvalid),  // output wire m_axi_arvalid
  .m_axi_arready(m1_axi_arready),  // input wire m_axi_arready
  .m_axi_rdata(m1_axi_rdata),      // input wire [63 : 0] m_axi_rdata
  .m_axi_rresp(m1_axi_rresp),      // input wire [1 : 0] m_axi_rresp
  .m_axi_rvalid(m1_axi_rvalid),    // input wire m_axi_rvalid
  .m_axi_rready(m1_axi_rready)    // output wire m_axi_rready
);   
   
axi_protocol_converter_0 proto1 (
  .aclk(clock),
  .aresetn(!reset),                  // input wire aresetn
  .s_axi_awaddr(m1_axi_awaddr),      // input wire [63 : 0] s_axi_awaddr
  .s_axi_awprot(m1_axi_awprot),      // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(m1_axi_awvalid),    // input wire s_axi_awvalid
  .s_axi_awready(m1_axi_awready),    // output wire s_axi_awready
  .s_axi_wdata(m1_axi_wdata),        // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(m1_axi_wstrb),        // input wire [7 : 0] s_axi_wstrb
  .s_axi_wvalid(m1_axi_wvalid),      // input wire s_axi_wvalid
  .s_axi_wready(m1_axi_wready),      // output wire s_axi_wready
  .s_axi_bresp(m1_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(m1_axi_bvalid),      // output wire s_axi_bvalid
  .s_axi_bready(m1_axi_bready),      // input wire s_axi_bready
  .s_axi_araddr(m1_axi_araddr),      // input wire [63 : 0] s_axi_araddr
  .s_axi_arprot(m1_axi_arprot),      // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(m1_axi_arvalid),    // input wire s_axi_arvalid
  .s_axi_arready(m1_axi_arready),    // output wire s_axi_arready
  .s_axi_rdata(m1_axi_rdata),        // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(m1_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(m1_axi_rvalid),      // output wire s_axi_rvalid
  .s_axi_rready(m1_axi_rready),      // input wire s_axi_rready
  .m_axi_awaddr(m2_axi_awaddr),      // output wire [63 : 0] m_axi_awaddr
  .m_axi_awlen(m2_axi_awlen),        // output wire [7 : 0] m_axi_awlen
  .m_axi_awsize(m2_axi_awsize),      // output wire [2 : 0] m_axi_awsize
  .m_axi_awburst(m2_axi_awburst),    // output wire [1 : 0] m_axi_awburst
  .m_axi_awlock(m2_axi_awlock),      // output wire [0 : 0] m_axi_awlock
  .m_axi_awcache(m2_axi_awcache),    // output wire [3 : 0] m_axi_awcache
  .m_axi_awprot(m2_axi_awprot),      // output wire [2 : 0] m_axi_awprot
  .m_axi_awregion(m2_axi_awregion),  // output wire [3 : 0] m_axi_awregion
  .m_axi_awqos(m2_axi_awqos),        // output wire [3 : 0] m_axi_awqos
  .m_axi_awvalid(m2_axi_awvalid),    // output wire m_axi_awvalid
  .m_axi_awready(m2_axi_awready),    // input wire m_axi_awready
  .m_axi_wdata(m2_axi_wdata),        // output wire [63 : 0] m_axi_wdata
  .m_axi_wstrb(m2_axi_wstrb),        // output wire [7 : 0] m_axi_wstrb
  .m_axi_wlast(m2_axi_wlast),        // output wire m_axi_wlast
  .m_axi_wvalid(m2_axi_wvalid),      // output wire m_axi_wvalid
  .m_axi_wready(m2_axi_wready),      // input wire m_axi_wready
  .m_axi_bresp(m2_axi_bresp),        // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(m2_axi_bvalid),      // input wire m_axi_bvalid
  .m_axi_bready(m2_axi_bready),      // output wire m_axi_bready
  .m_axi_araddr(m2_axi_araddr),      // output wire [63 : 0] m_axi_araddr
  .m_axi_arlen(m2_axi_arlen),        // output wire [7 : 0] m_axi_arlen
  .m_axi_arsize(m2_axi_arsize),      // output wire [2 : 0] m_axi_arsize
  .m_axi_arburst(m2_axi_arburst),    // output wire [1 : 0] m_axi_arburst
  .m_axi_arlock(m2_axi_arlock),      // output wire [0 : 0] m_axi_arlock
  .m_axi_arcache(m2_axi_arcache),    // output wire [3 : 0] m_axi_arcache
  .m_axi_arprot(m2_axi_arprot),      // output wire [2 : 0] m_axi_arprot
  .m_axi_arregion(m2_axi_arregion),  // output wire [3 : 0] m_axi_arregion
  .m_axi_arqos(m2_axi_arqos),        // output wire [3 : 0] m_axi_arqos
  .m_axi_arvalid(m2_axi_arvalid),    // output wire m_axi_arvalid
  .m_axi_arready(m2_axi_arready),    // input wire m_axi_arready
  .m_axi_rdata(m2_axi_rdata),        // input wire [63 : 0] m_axi_rdata
  .m_axi_rresp(m2_axi_rresp),        // input wire [1 : 0] m_axi_rresp
  .m_axi_rlast(m2_axi_rlast),        // input wire m_axi_rlast
  .m_axi_rvalid(m2_axi_rvalid),      // input wire m_axi_rvalid
  .m_axi_rready(m2_axi_rready)       // output wire m_axi_rready
);
   
ila_0 analyzer1 (
	.clk(clock),
	.probe0( m2_axi_wready), // input wire [0:0] probe0  
	.probe1( m2_axi_awaddr), // input wire [63:0]  probe1 
	.probe2( m2_axi_bresp), // input wire [1:0]  probe2 
	.probe3( m2_axi_bvalid), // input wire [0:0]  probe3 
	.probe4( m2_axi_bready), // input wire [0:0]  probe4 
	.probe5( m2_axi_araddr), // input wire [63:0]  probe5 
	.probe6( m2_axi_rready), // input wire [0:0]  probe6 
	.probe7( m2_axi_wvalid), // input wire [0:0]  probe7 
	.probe8( m2_axi_arvalid), // input wire [0:0]  probe8 
	.probe9( m2_axi_arready), // input wire [0:0]  probe9 
	.probe10( m2_axi_rdata), // input wire [63:0]  probe10 
	.probe11( m2_axi_awvalid), // input wire [0:0]  probe11 
	.probe12( m2_axi_awready), // input wire [0:0]  probe12 
	.probe13( m2_axi_rresp), // input wire [1:0]  probe13 
	.probe14( m2_axi_wdata), // input wire [63:0]  probe14 
	.probe15( m2_axi_wstrb), // input wire [7:0]  probe15 
	.probe16( m2_axi_rvalid), // input wire [0:0]  probe16 
	.probe17( m2_axi_arprot), // input wire [2:0]  probe17 
	.probe18( m2_axi_awprot), // input wire [2:0]  probe18 
	.probe19( m2_axi_awid), // input wire [3:0]  probe19 
	.probe20( m2_axi_bid), // input wire [3:0]  probe20 
	.probe21( m2_axi_awlen), // input wire [7:0]  probe21 
	.probe22( m2_axi_buser), // input wire [0:0]  probe22 
	.probe23( m2_axi_awsize), // input wire [2:0]  probe23 
	.probe24( m2_axi_awburst), // input wire [1:0]  probe24 
	.probe25( m2_axi_arid), // input wire [3:0]  probe25 
	.probe26( m2_axi_awlock), // input wire [0:0]  probe26 
	.probe27( m2_axi_arlen), // input wire [7:0]  probe27 
	.probe28( m2_axi_arsize), // input wire [2:0]  probe28 
	.probe29( m2_axi_arburst), // input wire [1:0]  probe29 
	.probe30( m2_axi_arlock), // input wire [0:0]  probe30 
	.probe31( m2_axi_arcache), // input wire [3:0]  probe31 
	.probe32( m2_axi_awcache), // input wire [3:0]  probe32 
	.probe33( m2_axi_arregion), // input wire [3:0]  probe33 
	.probe34( m2_axi_arqos), // input wire [3:0]  probe34 
	.probe35( m2_axi_aruser), // input wire [0:0]  probe35 
	.probe36( m2_axi_awregion), // input wire [3:0]  probe36 
	.probe37( m2_axi_awqos), // input wire [3:0]  probe37 
	.probe38( m2_axi_rid), // input wire [3:0]  probe38 
	.probe39( m2_axi_awuser), // input wire [0:0]  probe39 
	.probe40( m2_axi_wuser), // input wire [0:0]  probe40 
	.probe41( m2_axi_rlast), // input wire [0:0]  probe41 
	.probe42( m2_axi_ruser), // input wire [0:0]  probe42  
	.probe43( m2_axi_wlast) // input wire [0:0]  probe43
);
   
axi_crossbar_0 cross1 (
  .aclk(clock),
  .aresetn(!reset),                  // input wire aresetn
  .s_axi_awid(m2_axi_awid),          // input wire [3 : 0] s_axi_awid
  .s_axi_awaddr(m2_axi_awaddr),      // input wire [63 : 0] s_axi_awaddr
  .s_axi_awlen(m2_axi_awlen),        // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(m2_axi_awsize),      // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(m2_axi_awburst),    // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(m2_axi_awlock),      // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache(m2_axi_awcache),    // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(m2_axi_awprot),      // input wire [2 : 0] s_axi_awprot
  .s_axi_awqos(m2_axi_awqos),        // input wire [3 : 0] s_axi_awqos
  .s_axi_awuser(m2_axi_awuser),      // input wire [0 : 0] s_axi_awuser
  .s_axi_awvalid(m2_axi_awvalid),    // input wire [0 : 0] s_axi_awvalid
  .s_axi_awready(m2_axi_awready),    // output wire [0 : 0] s_axi_awready
  .s_axi_wdata(m2_axi_wdata),        // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(m2_axi_wstrb),        // input wire [7 : 0] s_axi_wstrb
  .s_axi_wlast(m2_axi_wlast),        // input wire [0 : 0] s_axi_wlast
  .s_axi_wuser(m2_axi_wuser),        // input wire [0 : 0] s_axi_wuser
  .s_axi_wvalid(m2_axi_wvalid),      // input wire [0 : 0] s_axi_wvalid
  .s_axi_wready(m2_axi_wready),      // output wire [0 : 0] s_axi_wready
  .s_axi_bid(m2_axi_bid),            // output wire [3 : 0] s_axi_bid
  .s_axi_bresp(m2_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_buser(m2_axi_buser),        // output wire [0 : 0] s_axi_buser
  .s_axi_bvalid(m2_axi_bvalid),      // output wire [0 : 0] s_axi_bvalid
  .s_axi_bready(m2_axi_bready),      // input wire [0 : 0] s_axi_bready
  .s_axi_arid(m2_axi_arid),          // input wire [3 : 0] s_axi_arid
  .s_axi_araddr(m2_axi_araddr),      // input wire [63 : 0] s_axi_araddr
  .s_axi_arlen(m2_axi_arlen),        // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(m2_axi_arsize),      // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(m2_axi_arburst),    // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(m2_axi_arlock),      // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache(m2_axi_arcache),    // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(m2_axi_arprot),      // input wire [2 : 0] s_axi_arprot
  .s_axi_arqos(m2_axi_arqos),        // input wire [3 : 0] s_axi_arqos
  .s_axi_aruser(m2_axi_aruser),      // input wire [0 : 0] s_axi_aruser
  .s_axi_arvalid(m2_axi_arvalid),    // input wire [0 : 0] s_axi_arvalid
  .s_axi_arready(m2_axi_arready),    // output wire [0 : 0] s_axi_arready
  .s_axi_rid(m2_axi_rid),            // output wire [3 : 0] s_axi_rid
  .s_axi_rdata(m2_axi_rdata),        // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(m2_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(m2_axi_rlast),        // output wire [0 : 0] s_axi_rlast
  .s_axi_ruser(m2_axi_ruser),        // output wire [0 : 0] s_axi_ruser
  .s_axi_rvalid(m2_axi_rvalid),      // output wire [0 : 0] s_axi_rvalid
  .s_axi_rready(m2_axi_rready),      // input wire [0 : 0] s_axi_rready
  .m_axi_awid({mem_axi4_0_aw_bits_id,mmio_axi4_0_aw_bits_id}),          // output wire [7 : 0] m_axi_awid
  .m_axi_awaddr({mem_axi4_0_aw_bits_addr,mmio_axi4_0_aw_bits_addr}),      // output wire [127 : 0] m_axi_awaddr
  .m_axi_awlen({mem_axi4_0_aw_bits_len,mmio_axi4_0_aw_bits_len}),        // output wire [15 : 0] m_axi_awlen
  .m_axi_awsize({mem_axi4_0_aw_bits_size,mmio_axi4_0_aw_bits_size}),      // output wire [5 : 0] m_axi_awsize
  .m_axi_awburst({mem_axi4_0_aw_bits_burst,mmio_axi4_0_aw_bits_burst}),    // output wire [3 : 0] m_axi_awburst
  .m_axi_awlock({mem_axi4_0_aw_bits_lock,mmio_axi4_0_aw_bits_lock}),      // output wire [1 : 0] m_axi_awlock
  .m_axi_awcache({mem_axi4_0_aw_bits_cache,mmio_axi4_0_aw_bits_cache}),    // output wire [7 : 0] m_axi_awcache
  .m_axi_awprot({mem_axi4_0_aw_bits_prot,mmio_axi4_0_aw_bits_prot}),      // output wire [5 : 0] m_axi_awprot
  .m_axi_awregion({mem_axi4_0_aw_bits_region,mmio_axi4_0_aw_bits_region}),  // output wire [7 : 0] m_axi_awregion
  .m_axi_awqos({mem_axi4_0_aw_bits_qos,mmio_axi4_0_aw_bits_qos}),        // output wire [7 : 0] m_axi_awqos
  .m_axi_awuser({mem_axi4_0_aw_bits_user,mmio_axi4_0_aw_bits_user}),      // output wire [1 : 0] m_axi_awuser
  .m_axi_awvalid({mem_axi4_0_aw_valid,mmio_axi4_0_aw_valid}),    // output wire [1 : 0] m_axi_awvalid
  .m_axi_awready({mem_axi4_0_aw_ready,mmio_axi4_0_aw_ready}),    // input wire [1 : 0] m_axi_awready
  .m_axi_wdata({mem_axi4_0_w_bits_data,mmio_axi4_0_w_bits_data}),        // output wire [127 : 0] m_axi_wdata
  .m_axi_wstrb({mem_axi4_0_w_bits_strb,mmio_axi4_0_w_bits_strb}),        // output wire [15 : 0] m_axi_wstrb
  .m_axi_wlast({mem_axi4_0_w_bits_last,mmio_axi4_0_w_bits_last}),        // output wire [1 : 0] m_axi_wlast
  .m_axi_wuser({mem_axi4_0_w_bits_user,mmio_axi4_0_w_bits_user}),        // output wire [1 : 0] m_axi_wuser
  .m_axi_wvalid({mem_axi4_0_w_valid,mmio_axi4_0_w_valid}),      // output wire [1 : 0] m_axi_wvalid
  .m_axi_wready({mem_axi4_0_w_ready,mmio_axi4_0_w_ready}),      // input wire [1 : 0] m_axi_wready
  .m_axi_bid({mem_axi4_0_b_bits_id,mmio_axi4_0_b_bits_id}),            // input wire [7 : 0] m_axi_bid
  .m_axi_bresp({mem_axi4_0_b_bits_resp,mmio_axi4_0_b_bits_resp}),        // input wire [3 : 0] m_axi_bresp
  .m_axi_buser({mem_axi4_0_b_bits_user,mmio_axi4_0_b_bits_user}),        // input wire [1 : 0] m_axi_buser
  .m_axi_bvalid({mem_axi4_0_b_valid,mmio_axi4_0_b_valid}),      // input wire [1 : 0] m_axi_bvalid
  .m_axi_bready({mem_axi4_0_b_ready,mmio_axi4_0_b_ready}),      // output wire [1 : 0] m_axi_bready
  .m_axi_arid({mem_axi4_0_ar_bits_id,mmio_axi4_0_ar_bits_id}),          // output wire [7 : 0] m_axi_arid
  .m_axi_araddr({mem_axi4_0_ar_bits_addr,mmio_axi4_0_ar_bits_addr}),      // output wire [127 : 0] m_axi_araddr
  .m_axi_arlen({mem_axi4_0_ar_bits_len,mmio_axi4_0_ar_bits_len}),        // output wire [15 : 0] m_axi_arlen
  .m_axi_arsize({mem_axi4_0_ar_bits_size,mmio_axi4_0_ar_bits_size}),      // output wire [5 : 0] m_axi_arsize
  .m_axi_arburst({mem_axi4_0_ar_bits_burst,mmio_axi4_0_ar_bits_burst}),    // output wire [3 : 0] m_axi_arburst
  .m_axi_arlock({mem_axi4_0_ar_bits_lock,mmio_axi4_0_ar_bits_lock}),      // output wire [1 : 0] m_axi_arlock
  .m_axi_arcache({mem_axi4_0_ar_bits_cache,mmio_axi4_0_ar_bits_cache}),    // output wire [7 : 0] m_axi_arcache
  .m_axi_arprot({mem_axi4_0_ar_bits_prot,mmio_axi4_0_ar_bits_prot}),      // output wire [5 : 0] m_axi_arprot
  .m_axi_arregion({mem_axi4_0_ar_bits_region,mmio_axi4_0_ar_bits_region}),  // output wire [7 : 0] m_axi_arregion
  .m_axi_arqos({mem_axi4_0_ar_bits_qos,mmio_axi4_0_ar_bits_qos}),        // output wire [7 : 0] m_axi_arqos
  .m_axi_aruser({mem_axi4_0_ar_bits_user,mmio_axi4_0_ar_bits_user}),      // output wire [1 : 0] m_axi_aruser
  .m_axi_arvalid({mem_axi4_0_ar_valid,mmio_axi4_0_ar_valid}),    // output wire [1 : 0] m_axi_arvalid
  .m_axi_arready({mem_axi4_0_ar_ready,mmio_axi4_0_ar_ready}),    // input wire [1 : 0] m_axi_arready
  .m_axi_rid({mem_axi4_0_r_bits_id,mmio_axi4_0_r_bits_id}),            // input wire [7 : 0] m_axi_rid
  .m_axi_rdata({mem_axi4_0_r_bits_data,mmio_axi4_0_r_bits_data}),        // input wire [127 : 0] m_axi_rdata
  .m_axi_rresp({mem_axi4_0_r_bits_resp,mmio_axi4_0_r_bits_resp}),        // input wire [3 : 0] m_axi_rresp
  .m_axi_rlast({mem_axi4_0_r_bits_last,mmio_axi4_0_r_bits_last}),        // input wire [1 : 0] m_axi_rlast
  .m_axi_ruser({mem_axi4_0_r_bits_user,mmio_axi4_0_r_bits_user}),        // input wire [1 : 0] m_axi_ruser
  .m_axi_rvalid({mem_axi4_0_r_valid,mmio_axi4_0_r_valid}),      // input wire [1 : 0] m_axi_rvalid
  .m_axi_rready({mem_axi4_0_r_ready,mmio_axi4_0_r_ready})      // output wire [1 : 0] m_axi_rready
);
      
    picorv32_axi__pi1_opt uut( 
    .clk(clock),
    .resetn(!reset),
    .trap(trap),
    .io_reset_vector,
    .mem_axi_awvalid(mem_axi_awvalid),
    .mem_axi_awready(mem_axi_awready),
    .mem_axi_awaddr(mem_axi_awaddr),
    .mem_axi_awprot(mem_axi_awprot),
    .mem_axi_wvalid(mem_axi_wvalid),
    .mem_axi_wready(mem_axi_wready),
    .mem_axi_wdata(mem_axi_wdata),
    .mem_axi_wstrb(mem_axi_wstrb),
    .mem_axi_bvalid(mem_axi_bvalid),
    .mem_axi_bready(mem_axi_bready),
    .mem_axi_arvalid(mem_axi_arvalid),
    .mem_axi_arready(mem_axi_arready),
    .mem_axi_araddr(mem_axi_araddr),
    .mem_axi_arprot(mem_axi_arprot),
    .mem_axi_rvalid(mem_axi_rvalid),
    .mem_axi_rready(mem_axi_rready),
    .mem_axi_rdata(mem_axi_rdata),
    .irq(irq),
    .dbg_reg_x0(dbg_reg_x0),
    .dbg_reg_x1(dbg_reg_x1),
    .dbg_reg_x2(dbg_reg_x2),
    .dbg_reg_x3(dbg_reg_x3),
    .dbg_reg_x4(dbg_reg_x4),
    .dbg_reg_x5(dbg_reg_x5),
    .dbg_reg_x6(dbg_reg_x6),
    .dbg_reg_x7(dbg_reg_x7),
    .dbg_reg_x8(dbg_reg_x8),
    .dbg_reg_x9(dbg_reg_x9),
    .dbg_reg_x10(dbg_reg_x10),
    .dbg_reg_x11(dbg_reg_x11),
    .dbg_reg_x12(dbg_reg_x12),
    .dbg_reg_x13(dbg_reg_x13),
    .dbg_reg_x14(dbg_reg_x14),
    .dbg_reg_x15(dbg_reg_x15),
    .dbg_reg_x16(dbg_reg_x16),
    .dbg_reg_x17(dbg_reg_x17),
    .dbg_reg_x18(dbg_reg_x18),
    .dbg_reg_x19(dbg_reg_x19),
    .dbg_reg_x20(dbg_reg_x20),
    .dbg_reg_x21(dbg_reg_x21),
    .dbg_reg_x22(dbg_reg_x22),
    .dbg_reg_x23(dbg_reg_x23),
    .dbg_reg_x24(dbg_reg_x24),
    .dbg_reg_x25(dbg_reg_x25),
    .dbg_reg_x26(dbg_reg_x26),
    .dbg_reg_x27(dbg_reg_x27),
    .dbg_reg_x28(dbg_reg_x28),
    .dbg_reg_x29(dbg_reg_x29),
    .dbg_reg_x30(dbg_reg_x30),
    .dbg_reg_x31(dbg_reg_x31),
    .dbg_insn_opcode(dbg_insn_opcode),
    .dbg_insn_addr(dbg_insn_addr),
    .dbg_mem_valid(dbg_mem_valid),
    .dbg_mem_instr(dbg_mem_instr),
    .dbg_mem_ready(dbg_mem_ready),
    .dbg_mem_addr(dbg_mem_addr),
    .dbg_mem_wdata(dbg_mem_wdata),
    .dbg_mem_wstrb(dbg_mem_wstrb),
    .dbg_mem_rdata(dbg_mem_rdata),
    .dbg_ascii_instr(dbg_ascii_instr),
    .dbg_insn_imm(dbg_insn_imm),
    .dbg_insn_rs1(dbg_insn_rs1),
    .dbg_insn_rs2(dbg_insn_rs2),
    .dbg_insn_rd(dbg_insn_rd),
    .dbg_rs1val(dbg_rs1val),
    .dbg_rs2val(dbg_rs2val),
    .dbg_rs1val_valid(dbg_rs1val_valid),
    .dbg_rs2val_valid(dbg_rs2val_valid),
    .dbg_next(dbg_next),
    .dbg_valid_insn(dbg_valid_insn),
    .dbg_ascii_state(dbg_ascii_state),
    .trace_valid(trace_valid),
    .trace_data(trace_data),
    .pcpi_valid(),
    .pcpi_insn(),
    .pcpi_rs1(),
    .pcpi_rs2(),
    .pcpi_wr(),
    .pcpi_rd(),
    .pcpi_wait(),
    .pcpi_ready(),
    .eoi()
    );

ila_1 trace_instance (
	.clk(clock),
	.probe0(dbg_reg_x0), // input wire [31:0]  probe0  
	.probe1(dbg_reg_x1), // input wire [31:0]  probe1 
	.probe2(dbg_reg_x2), // input wire [31:0]  probe2 
	.probe3(dbg_reg_x3), // input wire [31:0]  probe3 
	.probe4(dbg_reg_x4), // input wire [31:0]  probe4 
	.probe5(dbg_reg_x5), // input wire [31:0]  probe5 
	.probe6(dbg_reg_x6), // input wire [31:0]  probe6 
	.probe7(dbg_reg_x7), // input wire [31:0]  probe7 
	.probe8(dbg_reg_x8), // input wire [31:0]  probe8 
	.probe9(dbg_reg_x9), // input wire [31:0]  probe9 
	.probe10(dbg_reg_x10), // input wire [31:0]  probe10 
	.probe11(dbg_reg_x11), // input wire [31:0]  probe11 
	.probe12(dbg_reg_x12), // input wire [31:0]  probe12 
	.probe13(dbg_reg_x13), // input wire [31:0]  probe13 
	.probe14(dbg_reg_x14), // input wire [31:0]  probe14 
	.probe15(dbg_reg_x15), // input wire [31:0]  probe15 
	.probe16(dbg_reg_x16), // input wire [31:0]  probe16 
	.probe17(dbg_reg_x17), // input wire [31:0]  probe17 
	.probe18(dbg_reg_x18), // input wire [31:0]  probe18 
	.probe19(dbg_reg_x19), // input wire [31:0]  probe19 
	.probe20(dbg_reg_x20), // input wire [31:0]  probe20 
	.probe21(dbg_reg_x21), // input wire [31:0]  probe21 
	.probe22(dbg_reg_x22), // input wire [31:0]  probe22 
	.probe23(dbg_reg_x23), // input wire [31:0]  probe23 
	.probe24(dbg_reg_x24), // input wire [31:0]  probe24 
	.probe25(dbg_reg_x25), // input wire [31:0]  probe25 
	.probe26(dbg_reg_x26), // input wire [31:0]  probe26 
	.probe27(dbg_reg_x27), // input wire [31:0]  probe27 
	.probe28(dbg_reg_x28), // input wire [31:0]  probe28 
	.probe29(dbg_reg_x29), // input wire [31:0]  probe29 
	.probe30(dbg_reg_x30), // input wire [31:0]  probe30 
	.probe31(dbg_reg_x31), // input wire [31:0]  probe31 
        .probe32(dbg_insn_opcode),
        .probe33(dbg_insn_addr),
        .probe34(dbg_mem_valid),
        .probe35(dbg_mem_instr),
        .probe36(dbg_mem_ready),
        .probe37(dbg_mem_addr),
        .probe38(dbg_mem_wdata),
        .probe39(dbg_mem_wstrb),
        .probe40(dbg_mem_rdata),
        .probe41(dbg_ascii_instr),
        .probe42(dbg_insn_imm),
        .probe43(dbg_insn_rs1),
        .probe44(dbg_insn_rs2),
        .probe45(dbg_insn_rd),
        .probe46(dbg_rs1val),
        .probe47(dbg_rs2val),
        .probe48(dbg_rs1val_valid),
        .probe49(dbg_rs2val_valid),
        .probe50(dbg_next),
        .probe51(dbg_valid_insn),
        .probe52(dbg_ascii_state),
	.probe53(trace_valid), // input wire [0:0]  probe53 
	.probe54(trace_data), // input wire [35:0]  probe54 
	.probe55(trap), // input wire [0:0]  probe55 
	.probe56(irq[0]), // input wire [0:0]  probe56 
	.probe57(irq[1]), // input wire [0:0]  probe57 
	.probe58(irq[2]), // input wire [0:0]  probe58 
	.probe59(irq[3]) // input wire [0:0]  probe59
);

endmodule
