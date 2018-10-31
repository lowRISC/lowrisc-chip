// See LICENSE for license details.

module nasti_ram_sim
  #(
    ID_WIDTH = 8,
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128,
    USER_WIDTH = 1,
    NUM_WORDS  = 2**24
    )
   (
    input clk, rstn,
    nasti_channel.slave nasti
    );

  parameter base = 32'h80200000;

  integer i, fd, first, last;

  reg [7:0] mem[32'h0:32'h1000000];

  // Read input arguments and initialize

`ifdef INIT_RAM_SIM   
  initial
    begin
    // JRRK hacks
        $readmemh("cnvmem.mem", mem);
        for (i = base; (i < base+32'h1000000) && (1'bx === ^mem[i-base]); i=i+8)
          ;
        first = i;
        for (i = base+32'h1000000; (i >= base) && (1'bx === ^mem[i-base]); i=i-8)
          ;
        last = (i+16);
        for (i = i+1; i < last; i=i+1)
          mem[i-base] = 0;
        $display("First = %X, Last = %X", first, last-1);
        for (i = first; i < last; i=i+1)
          if (1'bx === ^mem[i-base]) mem[i-base] = 0;
    end // initial begin
`endif
   
   function bit memory_load_mem (input string filename);

     begin
     end

   endfunction // memory_load_mem

   logic                          req;
   logic                          we;
   logic [ADDR_WIDTH-1:0]         addr;
   logic [DATA_WIDTH/8-1:0]       be;
   logic [DATA_WIDTH-1:0]         wdata;
   logic [DATA_WIDTH-1:0]         rdata;
   
   AXI_BUS #(
        .AXI_ADDR_WIDTH ( ADDR_WIDTH ),
        .AXI_DATA_WIDTH ( DATA_WIDTH ),
        .AXI_ID_WIDTH   ( ID_WIDTH   ),
        .AXI_USER_WIDTH ( USER_WIDTH )
    ) sram_if();

slave_adapter  #(
    .ID_WIDTH(ID_WIDTH),                 // id width
    .ADDR_WIDTH(ADDR_WIDTH),             // address width
    .DATA_WIDTH(DATA_WIDTH),             // width of data
    .USER_WIDTH(USER_WIDTH)              // width of user field, must > 0, let synthesizer trim it if not in use
    )
 sadapt(
  .s_axi_awid(nasti.aw_id),
  .s_axi_awaddr(nasti.aw_addr),
  .s_axi_awlen(nasti.aw_len),
  .s_axi_awsize(nasti.aw_size),
  .s_axi_awburst(nasti.aw_burst),
  .s_axi_awlock(nasti.aw_lock),
  .s_axi_awcache(nasti.aw_cache),
  .s_axi_awprot(nasti.aw_prot),
  .s_axi_awregion(nasti.aw_region),
  .s_axi_awqos(nasti.aw_qos),
  .s_axi_awuser(nasti.aw_user),
  .s_axi_awvalid(nasti.aw_valid),
  .s_axi_awready(nasti.aw_ready),
  .s_axi_wdata(nasti.w_data),
  .s_axi_wstrb(nasti.w_strb),
  .s_axi_wlast(nasti.w_last),
  .s_axi_wuser(nasti.w_user),
  .s_axi_wvalid(nasti.w_valid),
  .s_axi_wready(nasti.w_ready),
  .s_axi_bid(nasti.b_id),
  .s_axi_bresp(nasti.b_resp),
  .s_axi_buser(nasti.b_user),
  .s_axi_bvalid(nasti.b_valid),
  .s_axi_bready(nasti.b_ready),
  .s_axi_arid(nasti.ar_id),
  .s_axi_araddr(nasti.ar_addr),
  .s_axi_arlen(nasti.ar_len),
  .s_axi_arsize(nasti.ar_size),
  .s_axi_arburst(nasti.ar_burst),
  .s_axi_arlock(nasti.ar_lock),
  .s_axi_arcache(nasti.ar_cache),
  .s_axi_arprot(nasti.ar_prot),
  .s_axi_arregion(nasti.ar_region),
  .s_axi_arqos(nasti.ar_qos),
  .s_axi_aruser(nasti.ar_user),
  .s_axi_arvalid(nasti.ar_valid),
  .s_axi_arready(nasti.ar_ready),
  .s_axi_rid(nasti.r_id),
  .s_axi_rdata(nasti.r_data),
  .s_axi_rresp(nasti.r_resp),
  .s_axi_rlast(nasti.r_last),
  .s_axi_ruser(nasti.r_user),
  .s_axi_rvalid(nasti.r_valid),
  .s_axi_rready(nasti.r_ready),
      .m_axi_awid           ( sram_if.aw_id      ),
      .m_axi_awaddr         ( sram_if.aw_addr    ),
      .m_axi_awlen          ( sram_if.aw_len     ),
      .m_axi_awsize         ( sram_if.aw_size    ),
      .m_axi_awburst        ( sram_if.aw_burst   ),
      .m_axi_awlock         ( sram_if.aw_lock    ),
      .m_axi_awcache        ( sram_if.aw_cache   ),
      .m_axi_awprot         ( sram_if.aw_prot    ),
      .m_axi_awqos          ( sram_if.aw_qos     ),
      .m_axi_awuser         ( sram_if.aw_user    ),
      .m_axi_awregion       ( sram_if.aw_region  ),
      .m_axi_awvalid        ( sram_if.aw_valid   ),
      .m_axi_awready        ( sram_if.aw_ready   ),
      .m_axi_wdata          ( sram_if.w_data     ),
      .m_axi_wstrb          ( sram_if.w_strb     ),
      .m_axi_wlast          ( sram_if.w_last     ),
      .m_axi_wuser          ( sram_if.w_user     ),
      .m_axi_wvalid         ( sram_if.w_valid    ),
      .m_axi_wready         ( sram_if.w_ready    ),
      .m_axi_bid            ( sram_if.b_id       ),
      .m_axi_bresp          ( sram_if.b_resp     ),
      .m_axi_buser          ( sram_if.b_user     ),
      .m_axi_bvalid         ( sram_if.b_valid    ),
      .m_axi_bready         ( sram_if.b_ready    ),
      .m_axi_arid           ( sram_if.ar_id      ),
      .m_axi_araddr         ( sram_if.ar_addr    ),
      .m_axi_arlen          ( sram_if.ar_len     ),
      .m_axi_arsize         ( sram_if.ar_size    ),
      .m_axi_arburst        ( sram_if.ar_burst   ),
      .m_axi_arlock         ( sram_if.ar_lock    ),
      .m_axi_arcache        ( sram_if.ar_cache   ),
      .m_axi_arprot         ( sram_if.ar_prot    ),
      .m_axi_arqos          ( sram_if.ar_qos     ),
      .m_axi_aruser         ( sram_if.ar_user    ),
      .m_axi_arregion       ( sram_if.ar_region  ),
      .m_axi_arvalid        ( sram_if.ar_valid   ),
      .m_axi_arready        ( sram_if.ar_ready   ),
      .m_axi_rid            ( sram_if.r_id       ),
      .m_axi_rdata          ( sram_if.r_data     ),
      .m_axi_rresp          ( sram_if.r_resp     ),
      .m_axi_rlast          ( sram_if.r_last     ),
      .m_axi_ruser          ( sram_if.r_user     ),
      .m_axi_rvalid         ( sram_if.r_valid    ),
      .m_axi_rready         ( sram_if.r_ready    )
                      );

    axi2mem #(
        .AXI_ID_WIDTH   ( ID_WIDTH   ),
        .AXI_ADDR_WIDTH ( ADDR_WIDTH ),
        .AXI_DATA_WIDTH ( DATA_WIDTH ),
        .AXI_USER_WIDTH ( USER_WIDTH )
    ) i_axi2mem (
        .clk_i  ( clk     ),
        .rst_ni ( rstn    ),
        .slave  ( sram_if ),
        .req_o  ( req        ),
        .we_o   ( we         ),
        .addr_o ( addr       ),
        .be_o   ( be         ),
        .data_o ( wdata      ),
        .data_i ( rdata      )
    );

   sram #(
        .DATA_WIDTH ( DATA_WIDTH ),
        .NUM_WORDS  ( NUM_WORDS  )
    ) i_sram (
        .clk_i      ( clk                                                                         ),
        .rst_ni     ( rstn                                                                        ),
        .req_i      ( req                                                                         ),
        .we_i       ( we                                                                          ),
        .addr_i     ( addr[$clog2(NUM_WORDS)-1+$clog2(DATA_WIDTH/8):$clog2(DATA_WIDTH/8)]         ),
        .wdata_i    ( wdata                                                                       ),
        .be_i       ( be                                                                          ),
        .rdata_o    ( rdata                                                                       )
    );
   
endmodule // nasti_ram_sim
