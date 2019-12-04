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
// ----------------------------
// AXI to SRAM Adapter
// ----------------------------
// Author: Florian Zaruba (zarubaf@iis.ee.ethz.ch)
//
// Description: Manages AXI transactions
//              Supports all burst accesses but only on aligned addresses and with full data width.
//              Assertions should guide you if there is something unsupported happening.
//
// Modified to interface as behavioural replacement for Xilinx DDR controller and memory

module xlnx_mig_7_ddr_nexys4_ddr(
  inout [15:0]  ddr2_dq,
  inout [1:0]   ddr2_dqs_n,
  inout [1:0]   ddr2_dqs_p,
  output logic [12:0] ddr2_addr,
  output logic [2:0]  ddr2_ba,
  output logic        ddr2_ras_n,
  output logic        ddr2_cas_n,
  output logic        ddr2_we_n,
  output logic [0:0]  ddr2_ck_p,
  output logic [0:0]  ddr2_ck_n,
  output logic [0:0]  ddr2_cke,
  output logic [0:0]  ddr2_cs_n,
  output logic [1:0]  ddr2_dm,
  output logic [0:0]  ddr2_odt,
  input         sys_clk_i,
  output logic        ui_clk,
  output logic        ui_clk_sync_rst,
  output logic        ui_addn_clk_0,
  output logic        ui_addn_clk_1,
  output logic        ui_addn_clk_2,
  output logic        ui_addn_clk_3,
  output logic        ui_addn_clk_4,
  output logic        mmcm_locked,
  input         aresetn,
  input         app_sr_req,
  input         app_ref_req,
  input         app_zq_req,
  output logic        app_sr_active,
  output logic        app_ref_ack,
  output logic        app_zq_ack,
  input [4:0]   s_axi_awid,
  input [31:0]  s_axi_awaddr,
  input [7:0]   s_axi_awlen,
  input [2:0]   s_axi_awsize,
  input [1:0]   s_axi_awburst,
  input [0:0]   s_axi_awlock,
  input [3:0]   s_axi_awcache,
  input [2:0]   s_axi_awprot,
  input [3:0]   s_axi_awqos,
  input         s_axi_awvalid,
  output logic        s_axi_awready,
  input [63:0]  s_axi_wdata,
  input [7:0]   s_axi_wstrb,
  input         s_axi_wlast,
  input         s_axi_wvalid,
  output logic        s_axi_wready,
  input         s_axi_bready,
  output logic [4:0]  s_axi_bid,
  output logic [1:0]  s_axi_bresp,
  output logic        s_axi_bvalid,
  input [4:0]   s_axi_arid,
  input [31:0]  s_axi_araddr,
  input [7:0]   s_axi_arlen,
  input [2:0]   s_axi_arsize,
  input [1:0]   s_axi_arburst,
  input [0:0]   s_axi_arlock,
  input [3:0]   s_axi_arcache,
  input [2:0]   s_axi_arprot,
  input [3:0]   s_axi_arqos,
  input         s_axi_arvalid,
  output logic        s_axi_arready,
  input         s_axi_rready,
  output logic [4:0]  s_axi_rid,
  output logic [63:0] s_axi_rdata,
  output logic [1:0]  s_axi_rresp,
  output logic        s_axi_rlast,
  output logic        s_axi_rvalid,
  output logic        init_calib_complete,
  input [11:0]  device_temp_i,
  input         sys_rst);
   
   parameter int unsigned AXI_ID_WIDTH      = 5;
   parameter int unsigned AXI_ADDR_WIDTH    = 64;
   parameter int unsigned AXI_DATA_WIDTH    = 64;
   parameter int unsigned AXI_USER_WIDTH    = 1;
   parameter int unsigned NUM_WORDS         = 1048576;
   
   logic [3:0] ui_cnt;
   
   assign ui_clk = ui_cnt[1];
   
   always @(posedge sys_clk_i)
     if (!sys_rst)
       begin
          ui_cnt <= 0;
          ui_clk_sync_rst <= 1;
       end
     else
       begin
          ui_cnt <= ui_cnt + 1;
          if (ui_cnt[3])
            ui_clk_sync_rst <= 0;
       end
   
   wire                   clk_i = ui_clk;
    // Clock
    wire  rst_ni = aresetn;  // Asynchronous reset active low
    logic                        req_o;
    logic [AXI_ADDR_WIDTH-1:0]   addr_o;
    logic [AXI_DATA_WIDTH/8-1:0] we_o;
    logic [AXI_DATA_WIDTH-1:0]   data_o;
    logic [AXI_DATA_WIDTH-1:0]    data_i;

  sram #(
    .DATA_WIDTH ( AXI_DATA_WIDTH ),
    .NUM_WORDS  ( NUM_WORDS      )
  ) i_sram (
    .clk_i      ( clk_i                                                                         ),
    .rst_ni     ( rst_ni                                                                        ),
    .req_i      ( req_o                                                                         ),
    .we_i       ( |we_o                                                                         ),
    .addr_i     ( addr_o[$clog2(NUM_WORDS)-1+$clog2(AXI_DATA_WIDTH/8):$clog2(AXI_DATA_WIDTH/8)] ),
    .wdata_i    ( data_o                                                                        ),
    .be_i       ( |we_o ? we_o : -1                                                             ),
    .rdata_o    ( data_i                                                                        )
  );

AXI_BUS #(
        .ADDR_WIDTH  (AXI_ADDR_WIDTH),
        .DATA_WIDTH  (AXI_DATA_WIDTH),
        .RELAX_CHECK (1'b1)
    ) outgoing_if ();

slave_adapter  #(
    .ID_WIDTH(AXI_ID_WIDTH),                 // id width
    .ADDR_WIDTH(AXI_ADDR_WIDTH),             // address width
    .DATA_WIDTH(AXI_DATA_WIDTH),             // width of data
    .USER_WIDTH(AXI_USER_WIDTH)              // width of user field, must > 0, let synthesizer trim it if not in use
    )
 sadapt(
  .clk(clk_i),
  .rstn(rst_ni),
  .s_axi_awid(s_axi_awid),
  .s_axi_awaddr(s_axi_awaddr),
  .s_axi_awlen(s_axi_awlen),
  .s_axi_awsize(s_axi_awsize),
  .s_axi_awburst(s_axi_awburst),
  .s_axi_awlock(s_axi_awlock),
  .s_axi_awcache(s_axi_awcache),
  .s_axi_awprot(s_axi_awprot),
  .s_axi_awregion(s_axi_awregion),
  .s_axi_awqos(s_axi_awqos),
  .s_axi_awuser(s_axi_awuser),
  .s_axi_awvalid(s_axi_awvalid),
  .s_axi_awready(s_axi_awready),
  .s_axi_wdata(s_axi_wdata),
  .s_axi_wstrb(s_axi_wstrb),
  .s_axi_wlast(s_axi_wlast),
  .s_axi_wuser(s_axi_wuser),
  .s_axi_wvalid(s_axi_wvalid),
  .s_axi_wready(s_axi_wready),
  .s_axi_bid(s_axi_bid),
  .s_axi_bresp(s_axi_bresp),
  .s_axi_buser(s_axi_buser),
  .s_axi_bvalid(s_axi_bvalid),
  .s_axi_bready(s_axi_bready),
  .s_axi_arid(s_axi_arid),
  .s_axi_araddr(s_axi_araddr),
  .s_axi_arlen(s_axi_arlen),
  .s_axi_arsize(s_axi_arsize),
  .s_axi_arburst(s_axi_arburst),
  .s_axi_arlock(s_axi_arlock),
  .s_axi_arcache(s_axi_arcache),
  .s_axi_arprot(s_axi_arprot),
  .s_axi_arregion('0),
  .s_axi_arqos(s_axi_arqos),
  .s_axi_aruser('0),
  .s_axi_arvalid(s_axi_arvalid),
  .s_axi_arready(s_axi_arready),
  .s_axi_rid(s_axi_rid),
  .s_axi_rdata(s_axi_rdata),
  .s_axi_rresp(s_axi_rresp),
  .s_axi_rlast(s_axi_rlast),
  .s_axi_ruser(s_axi_ruser),
  .s_axi_rvalid(s_axi_rvalid),
  .s_axi_rready(s_axi_rready),
      .m_axi_awid           ( outgoing_if.aw_id      ),
      .m_axi_awaddr         ( outgoing_if.aw_addr    ),
      .m_axi_awlen          ( outgoing_if.aw_len     ),
      .m_axi_awsize         ( outgoing_if.aw_size    ),
      .m_axi_awburst        ( outgoing_if.aw_burst   ),
      .m_axi_awlock         ( outgoing_if.aw_lock    ),
      .m_axi_awcache        ( outgoing_if.aw_cache   ),
      .m_axi_awprot         ( outgoing_if.aw_prot    ),
      .m_axi_awqos          ( outgoing_if.aw_qos     ),
      .m_axi_awuser         ( outgoing_if.aw_user    ),
      .m_axi_awregion       ( outgoing_if.aw_region  ),
      .m_axi_awvalid        ( outgoing_if.aw_valid   ),
      .m_axi_awready        ( outgoing_if.aw_ready   ),
      .m_axi_wdata          ( outgoing_if.w_data     ),
      .m_axi_wstrb          ( outgoing_if.w_strb     ),
      .m_axi_wlast          ( outgoing_if.w_last     ),
      .m_axi_wuser          ( outgoing_if.w_user     ),
      .m_axi_wvalid         ( outgoing_if.w_valid    ),
      .m_axi_wready         ( outgoing_if.w_ready    ),
      .m_axi_bid            ( outgoing_if.b_id       ),
      .m_axi_bresp          ( outgoing_if.b_resp     ),
      .m_axi_buser          ( outgoing_if.b_user     ),
      .m_axi_bvalid         ( outgoing_if.b_valid    ),
      .m_axi_bready         ( outgoing_if.b_ready    ),
      .m_axi_arid           ( outgoing_if.ar_id      ),
      .m_axi_araddr         ( outgoing_if.ar_addr    ),
      .m_axi_arlen          ( outgoing_if.ar_len     ),
      .m_axi_arsize         ( outgoing_if.ar_size    ),
      .m_axi_arburst        ( outgoing_if.ar_burst   ),
      .m_axi_arlock         ( outgoing_if.ar_lock    ),
      .m_axi_arcache        ( outgoing_if.ar_cache   ),
      .m_axi_arprot         ( outgoing_if.ar_prot    ),
      .m_axi_arqos          ( outgoing_if.ar_qos     ),
      .m_axi_aruser         ( outgoing_if.ar_user    ),
      .m_axi_arregion       ( outgoing_if.ar_region  ),
      .m_axi_arvalid        ( outgoing_if.ar_valid   ),
      .m_axi_arready        ( outgoing_if.ar_ready   ),
      .m_axi_rid            ( outgoing_if.r_id       ),
      .m_axi_rdata          ( outgoing_if.r_data     ),
      .m_axi_rresp          ( outgoing_if.r_resp     ),
      .m_axi_rlast          ( outgoing_if.r_last     ),
      .m_axi_ruser          ( outgoing_if.r_user     ),
      .m_axi_rvalid         ( outgoing_if.r_valid    ),
      .m_axi_rready         ( outgoing_if.r_ready    )
                      );

axi_bram_ctrl #(
    .ADDR_WIDTH(AXI_ADDR_WIDTH)     ,
    .DATA_WIDTH(AXI_DATA_WIDTH)     ,
    .ID_WIDTH(AXI_ID_WIDTH)       ,
    .USER_WIDTH(AXI_USER_WIDTH)     ,
    .BRAM_ADDR_WIDTH($clog2(NUM_WORDS)),
    .HIGH_PERFORMANCE(1)
) ctrl1 (
    .clk(clk_i),
    .rstn(rst_ni),
    .master(outgoing_if),

    .bram_en(req_o),
    .bram_we(we_o),
    .bram_addr(addr_o),
    .bram_wrdata(data_o),
    .bram_rddata(data_i)
);
                                 
endmodule
