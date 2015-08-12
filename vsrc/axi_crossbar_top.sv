// See LICENSE for license details.

// shame that Vivado does not support array of interfaces

module axi_crossbar_1x2_top
  #(
    ADDR_WIDTH = 32,
    DATA_WIDTH = 128,
    ID_WIDTH = 8
    )
  (
   input clk, rstn,

   // input AXI port
   nasti_aw.slave   aw_i,
   nasti_w.slave    w_i,
   nasti_b.slave    b_i,
   nasti_ar.slave   ar_i,
   nasti_r.slave    r_i,

   // output AXI port 0
   nasti_aw.master  aw_o_0,
   nasti_w.master   w_o_0,
   nasti_b.master   b_o_0,
   nasti_ar.master  ar_o_0,
   nasti_r.master   r_o_0,

   // output AXI port 1
   nasti_aw.master  aw_o_1,
   nasti_w.master   w_o_1,
   nasti_b.master   b_o_1,
   nasti_ar.master  ar_o_1,
   nasti_r.master   r_o_1
   );

   wire [ID_WIDTH-1:0]          s_axi_awid;
   wire [ADDR_WIDTH-1:0]        s_axi_awaddr;
   wire [7:0]                   s_axi_awlen;
   wire [2:0]                   s_axi_awsize;
   wire [1:0]                   s_axi_awburst;
   wire                         s_axi_awlock;
   wire [3:0]                   s_axi_awcache;
   wire [2:0]                   s_axi_awprot;
   wire [3:0]                   s_axi_awqos;
   wire [3:0]                   s_axi_awregion;
   wire                         s_axi_awvalid;
   wire                         s_axi_awready;

   wire [DATA_WIDTH-1:0]        s_axi_wdata;
   wire [DATA_WIDTH/8-1:0]      s_axi_wstrb;
   wire                         s_axi_wlast;
   wire                         s_axi_wvalid;
   wire                         s_axi_wready;

   wire [ID_WIDTH-1:0]          s_axi_bid;
   wire [1:0]                   s_axi_bresp;
   wire                         s_axi_bvalid;
   wire                         s_axi_bready;

   wire [ID_WIDTH-1:0]          s_axi_arid;
   wire [ADDR_WIDTH-1:0]        s_axi_araddr;
   wire [7:0]                   s_axi_arlen;
   wire [2:0]                   s_axi_arsize;
   wire [1:0]                   s_axi_arburst;
   wire                         s_axi_arlock;
   wire [3:0]                   s_axi_arcache;
   wire [2:0]                   s_axi_arprot;
   wire [3:0]                   s_axi_arqos;
   wire [3:0]                   s_axi_arregion;
   wire                         s_axi_arvalid;
   wire                         s_axi_arready;

   wire [ID_WIDTH-1:0]          s_axi_rid;
   wire [DATA_WIDTH-1:0]        s_axi_rdata;
   wire [1:0]                   s_axi_rresp;
   wire                         s_axi_rlast;
   wire                         s_axi_rvalid;
   wire                         s_axi_rready;

   wire [1:0][ID_WIDTH-1:0]     m_axi_awid;
   wire [1:0][ADDR_WIDTH-1:0]   m_axi_awaddr;
   wire [1:0][7:0]              m_axi_awlen;
   wire [1:0][2:0]              m_axi_awsize;
   wire [1:0][1:0]              m_axi_awburst;
   wire [1:0]                   m_axi_awlock;
   wire [1:0][3:0]              m_axi_awcache;
   wire [1:0][2:0]              m_axi_awprot;
   wire [1:0][3:0]              m_axi_awqos;
   wire [1:0][3:0]              m_axi_awregion;
   wire [1:0]                   m_axi_awvalid;
   wire [1:0]                   m_axi_awready;

   wire [1:0][DATA_WIDTH-1:0]   m_axi_wdata;
   wire [1:0][DATA_WIDTH/8-1:0] m_axi_wstrb;
   wire [1:0]                   m_axi_wlast;
   wire [1:0]                   m_axi_wvalid;
   wire [1:0]                   m_axi_wready;

   wire [1:0][ID_WIDTH-1:0]     m_axi_bid;
   wire [1:0][1:0]              m_axi_bresp;
   wire [1:0]                   m_axi_bvalid;
   wire [1:0]                   m_axi_bready;

   wire [1:0][ID_WIDTH-1:0]     m_axi_arid;
   wire [1:0][ADDR_WIDTH-1:0]   m_axi_araddr;
   wire [1:0][7:0]              m_axi_arlen;
   wire [1:0][2:0]              m_axi_arsize;
   wire [1:0][1:0]              m_axi_arburst;
   wire [1:0]                   m_axi_arlock;
   wire [1:0][3:0]              m_axi_arcache;
   wire [1:0][2:0]              m_axi_arprot;
   wire [1:0][3:0]              m_axi_arqos;
   wire [1:0][3:0]              m_axi_arregion;
   wire [1:0]                   m_axi_arvalid;
   wire [1:0]                   m_axi_arready;

   wire [1:0][ID_WIDTH-1:0]     m_axi_rid;
   wire [1:0][DATA_WIDTH-1:0]   m_axi_rdata;
   wire [1:0][1:0]              m_axi_rresp;
   wire [1:0]                   m_axi_rlast;
   wire [1:0]                   m_axi_rvalid;
   wire [1:0]                   m_axi_rready;

   axi_crossbar_0 cb
     (
      .*,
      .aclk     ( clk   ),
      .aresetn  ( rstn  )
      );

   assign s_axi_awid = aw_i.id;
   assign s_axi_awaddr = aw_i.addr;
   assign s_axi_awlen = aw_i.len;
   assign s_axi_awsize = aw_i.size;
   assign s_axi_awburst = aw_i.burst;
   assign s_axi_awlock = aw_i.lock;
   assign s_axi_awcache = aw_i.cache;
   assign s_axi_awprot = aw_i.prot;
   assign s_axi_awqos = aw_i.qos;
   assign s_axi_awregion = aw_i.region;
   assign s_axi_awvalid = aw_i.valid;
   assign aw_i.ready = s_axi_awready;

   assign s_axi_wdata = w_i.data;
   assign s_axi_wstrb = w_i.strb;
   assign s_axi_wlast = w_i.last;
   assign s_axi_wvalid = w_i.valid;
   assign w_i.ready = s_axi_wready;

   assign b_i.id = s_axi_bid;
   assign b_i.resp = s_axi_bresp;
   assign b_i.valid = s_axi_bvalid;
   assign s_axi_bready = b_i.ready;

   assign s_axi_arid = ar_i.id;
   assign s_axi_araddr = ar_i.addr;
   assign s_axi_arlen = ar_i.len;
   assign s_axi_arsize = ar_i.size;
   assign s_axi_arburst = ar_i.burst;
   assign s_axi_arlock = ar_i.lock;
   assign s_axi_arcache = ar_i.cache;
   assign s_axi_arprot = ar_i.prot;
   assign s_axi_arqos = ar_i.qos;
   assign s_axi_arregion = ar_i.region;
   assign s_axi_arvalid = ar_i.valid;
   assign ar_i.ready = s_axi_arready;

   assign r_i.id = s_axi_rid;
   assign r_i.data = s_axi_rdata;
   assign r_i.resp = s_axi_rresp;
   assign r_i.last = s_axi_rlast;
   assign r_i.valid = s_axi_rvalid;
   assign s_axi_rready = r_i.ready;

   assign aw_o_0.id = m_axi_awid[0];
   assign aw_o_0.addr = m_axi_awaddr[0];
   assign aw_o_0.len = m_axi_awlen[0];
   assign aw_o_0.size = m_axi_awsize[0];
   assign aw_o_0.burst = m_axi_awburst[0];
   assign aw_o_0.lock = m_axi_awlock[0];
   assign aw_o_0.cache = m_axi_awcache[0];
   assign aw_o_0.prot = m_axi_awprot[0];
   assign aw_o_0.qos = m_axi_awqos[0];
   assign aw_o_0.region = m_axi_awregion[0];
   assign aw_o_0.valid = m_axi_awvalid[0];
   assign m_axi_awready[0] = aw_o_0.ready;

   assign w_o_0.data = m_axi_wdata[0];
   assign w_o_0.strb = m_axi_wstrb[0];
   assign w_o_0.last = m_axi_wlast[0];
   assign w_o_0.valid = m_axi_wvalid[0];
   assign m_axi_wready[0] = w_o_0.ready;

   assign m_axi_bid[0] = b_o_0.id;
   assign m_axi_bresp[0] = b_o_0.resp;
   assign m_axi_bvalid[0] = b_o_0.valid;
   assign b_o_0.ready= m_axi_bready[0];

   assign ar_o_0.id = m_axi_arid[0];
   assign ar_o_0.addr = m_axi_araddr[0];
   assign ar_o_0.len = m_axi_arlen[0];
   assign ar_o_0.size = m_axi_arsize[0];
   assign ar_o_0.burst = m_axi_arburst[0];
   assign ar_o_0.lock = m_axi_arlock[0];
   assign ar_o_0.cache = m_axi_arcache[0];
   assign ar_o_0.prot = m_axi_arprot[0];
   assign ar_o_0.qos = m_axi_arqos[0];
   assign ar_o_0.region = m_axi_arregion[0];
   assign ar_o_0.valid = m_axi_arvalid[0];
   assign m_axi_arready[0] = ar_o_0.ready;

   assign m_axi_rid[0] = r_o_0.id;
   assign m_axi_rdata[0] = r_o_0.data;
   assign m_axi_rresp[0] = r_o_0.resp;
   assign m_axi_rlast[0] = r_o_0.last;
   assign m_axi_rvalid[0] = r_o_0.valid;
   assign r_o_0.ready = m_axi_rready[0];

   assign aw_o_1.id = m_axi_awid[1];
   assign aw_o_1.addr = m_axi_awaddr[1];
   assign aw_o_1.len = m_axi_awlen[1];
   assign aw_o_1.size = m_axi_awsize[1];
   assign aw_o_1.burst = m_axi_awburst[1];
   assign aw_o_1.lock = m_axi_awlock[1];
   assign aw_o_1.cache = m_axi_awcache[1];
   assign aw_o_1.prot = m_axi_awprot[1];
   assign aw_o_1.qos = m_axi_awqos[1];
   assign aw_o_1.region = m_axi_awregion[1];
   assign aw_o_1.valid = m_axi_awvalid[1];
   assign m_axi_awready[1] = aw_o_1.ready;

   assign w_o_1.data = m_axi_wdata[1];
   assign w_o_1.strb = m_axi_wstrb[1];
   assign w_o_1.last = m_axi_wlast[1];
   assign w_o_1.valid = m_axi_wvalid[1];
   assign m_axi_wready[1] = w_o_1.ready;

   assign m_axi_bid[1] = b_o_1.id;
   assign m_axi_bresp[1] = b_o_1.resp;
   assign m_axi_bvalid[1] = b_o_1.valid;
   assign b_o_1.ready = m_axi_bready[1];

   assign ar_o_1.id = m_axi_arid[1];
   assign ar_o_1.addr = m_axi_araddr[1];
   assign ar_o_1.len = m_axi_arlen[1];
   assign ar_o_1.size = m_axi_arsize[1];
   assign ar_o_1.burst = m_axi_arburst[1];
   assign ar_o_1.lock = m_axi_arlock[1];
   assign ar_o_1.cache = m_axi_arcache[1];
   assign ar_o_1.prot = m_axi_arprot[1];
   assign ar_o_1.qos = m_axi_arqos[1];
   assign ar_o_1.region = m_axi_arregion[1];
   assign ar_o_1.valid = m_axi_arvalid[1];
   assign m_axi_arready[1] = ar_o_1.ready;

   assign m_axi_rid[1] = r_o_1.id;
   assign m_axi_rdata[1] = r_o_1.data;
   assign m_axi_rresp[1] = r_o_1.resp;
   assign m_axi_rlast[1] = r_o_1.last;
   assign m_axi_rvalid[1] = r_o_1.valid;
   assign r_o_1.ready = m_axi_rready[1];

endmodule // axi_crossbar_top

