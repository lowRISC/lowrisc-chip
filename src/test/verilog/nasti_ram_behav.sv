// See LICENSE for license details.

module nasti_ram_behav
  #(
    ID_WIDTH = 8,
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128,
    USER_WIDTH = 1
    )
   (
    input clk, rstn,
    nasti_channel.slave nasti
    );

   initial assert(ID_WIDTH <= 16) else $error("Error: ID_WIDTH > 16 is not supported!");
   initial assert(ADDR_WIDTH <= 32) else $error("Error: ADDR_WIDTH > 32 is not supported!");
   initial assert(DATA_WIDTH <= 256) else $error("Error: DATA_WIDTH > 256 is not supported!");
   initial assert(USER_WIDTH <= 16) else $error("Error: USER_WIDTH > 16 is not supported!");

`ifdef FPGA

   function bit memory_load_mem (input string filename);

     begin
     end

   endfunction // memory_load_mem

   logic ram_clk, ram_rst, ram_en;
   logic [7:0] ram_we;
   logic [18:0] ram_addr;
   logic [63:0]   ram_wrdata, ram_rddata = 'HDEADBEEF;
   logic [30:0] bram_ar_addr, bram_aw_addr;
   
   assign bram_ar_addr = nasti.ar_addr ;
   assign bram_aw_addr = nasti.aw_addr ;
   
   axi_bram_ctrl_dummy BehavCtrl
     (
      .s_axi_aclk      ( clk            ),
      .s_axi_aresetn   ( rstn           ),
      .s_axi_arid      ( nasti.ar_id    ),
      .s_axi_araddr    ( bram_ar_addr[18:0]   ),
      .s_axi_arlen     ( nasti.ar_len   ),
      .s_axi_arsize    ( nasti.ar_size  ),
      .s_axi_arburst   ( nasti.ar_burst ),
      .s_axi_arlock    ( nasti.ar_lock  ),
      .s_axi_arcache   ( nasti.ar_cache ),
      .s_axi_arprot    ( nasti.ar_prot  ),
      .s_axi_arready   ( nasti.ar_ready ),
      .s_axi_arvalid   ( nasti.ar_valid ),
      .s_axi_rid       ( nasti.r_id     ),
      .s_axi_rdata     ( nasti.r_data   ),
      .s_axi_rresp     ( nasti.r_resp   ),
      .s_axi_rlast     ( nasti.r_last   ),
      .s_axi_rready    ( nasti.r_ready  ),
      .s_axi_rvalid    ( nasti.r_valid  ),
      .s_axi_awid      ( nasti.aw_id    ),
      .s_axi_awaddr    ( bram_aw_addr[18:0]   ),
      .s_axi_awlen     ( nasti.aw_len   ),
      .s_axi_awsize    ( nasti.aw_size  ),
      .s_axi_awburst   ( nasti.aw_burst ),
      .s_axi_awlock    ( nasti.aw_lock  ),
      .s_axi_awcache   ( nasti.aw_cache ),
      .s_axi_awprot    ( nasti.aw_prot  ),
      .s_axi_awready   ( nasti.aw_ready ),
      .s_axi_awvalid   ( nasti.aw_valid ),
      .s_axi_wdata     ( nasti.w_data   ),
      .s_axi_wstrb     ( nasti.w_strb   ),
      .s_axi_wlast     ( nasti.w_last   ),
      .s_axi_wready    ( nasti.w_ready  ),
      .s_axi_wvalid    ( nasti.w_valid  ),
      .s_axi_bid       ( nasti.b_id     ),
      .s_axi_bresp     ( nasti.b_resp   ),
      .s_axi_bready    ( nasti.b_ready  ),
      .s_axi_bvalid    ( nasti.b_valid  ),
      .bram_rst_a      ( ram_rst                   ),
      .bram_clk_a      ( ram_clk                   ),
      .bram_en_a       ( ram_en                    ),
      .bram_we_a       ( ram_we                    ),
      .bram_addr_a     ( ram_addr                  ),
      .bram_wrdata_a   ( ram_wrdata                ),
      .bram_rddata_a   ( ram_rddata                )
      );
   
`else
   
   import "DPI-C" function bit memory_write_req (
                                                 input bit [15:0] id,
                                                 input bit [31:0] addr,
                                                 input bit [7:0]  len,
                                                 input bit [2:0]  size,
                                                 input bit [15:0] user
                                                 );

   import "DPI-C" function bit memory_write_data (
                                                  input bit [255:0] data,
                                                  input bit [31:0]  strb,
                                                  input bit         last
                                                  );

   import "DPI-C" function bit memory_write_resp (
                                                  output bit [15:0] id,
                                                  output bit [1:0]  resp,
                                                  output bit [15:0] user
                                                  );

   import "DPI-C" function bit memory_read_req (
                                                input bit [15:0] id,
                                                input bit [31:0] addr,
                                                input bit [7:0]  len,
                                                input bit [2:0]  size,
                                                input bit [15:0] user
                                                );

   import "DPI-C" function bit memory_read_resp (
                                                 output bit [15:0]  id,
                                                 output bit [255:0] data,
                                                 output bit [1:0]   resp,
                                                 output bit         last,
                                                 output bit [15:0]  user
                                                 );
   import "DPI-C" function bit memory_model_init ();
   import "DPI-C" function bit memory_model_step ();
   import "DPI-C" function bit memory_load_mem (input string filename);

`ifndef VERILATOR

   initial begin
      #1;
      memory_model_init();
      @(negedge rstn);
      $fatal(1, "the behaviour dram model cannot be reset after the simultion is started.");
   end

`endif

   always @(posedge clk)
     memory_model_step();

`ifdef VERILATOR
   // A workaround for Verilator since it treats DPI functions as pure
   // Which leads to wrong function scheduling.
   // introduce verilog side-effect to prohibit rescheduling.
   // Issue submitted as
   // http://www.veripool.org/issues/963-Verilator-impure-function-being-scheduled-wrong

   reg dummy;

   function void write_dummy(input logic b);
      dummy = b;
   endfunction // write_dummy

`endif

   always @(negedge clk or negedge rstn)
     if(!rstn)
       nasti.aw_ready <= 0;
     else if(nasti.aw_valid) begin
        //$display("%t, aw valid", $time);
        nasti.aw_ready <= memory_write_req(nasti.aw_id, nasti.aw_addr, nasti.aw_len, nasti.aw_size, nasti.aw_user);
`ifdef VERILATOR
        write_dummy(nasti.aw_ready);
`endif
     end else
       nasti.aw_ready <= 0;

   always @(negedge clk or negedge rstn)
     if(!rstn)
       nasti.w_ready <= 0;
     else if(nasti.w_valid && rstn) begin
        //$display("%t, w valid", $time);
        nasti.w_ready <= memory_write_data(nasti.w_data, nasti.w_strb, nasti.w_last);
`ifdef VERILATOR
        write_dummy(nasti.w_ready);
`endif
     end else
       nasti.w_ready <= 0;

   logic [15:0]   b_id;
   logic [1:0]    b_resp;
   logic [15:0]   b_user;
   logic          b_valid;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       b_valid <= 0;
     else if(!b_valid || nasti.b_ready)
       b_valid <= memory_write_resp(b_id, b_resp, b_user);

   assign #1 nasti.b_valid = b_valid;
   assign #1 nasti.b_id = b_id;
   assign #1 nasti.b_resp = b_resp;
   assign #1 nasti.b_user = b_user;

   always @(negedge clk or negedge rstn)
     if(!rstn)
       nasti.ar_ready <= 0;
     else if(nasti.ar_valid && rstn) begin
        //$display("%t, ar valid", $time);
        nasti.ar_ready <= memory_read_req(nasti.ar_id, nasti.ar_addr, nasti.ar_len, nasti.ar_size, nasti.ar_user);
`ifdef VERILATOR
        write_dummy(nasti.ar_ready);
`endif
     end else
       nasti.ar_ready <= 0;

   logic [15:0]   r_id;
   logic [255:0]  r_data;
   logic [1:0]    r_resp;
   logic          r_last;
   logic [15:0]   r_user;
   logic          r_valid;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       r_valid <= 0;
     else if(!r_valid || nasti.r_ready)
       r_valid <= memory_read_resp(r_id, r_data, r_resp, r_last, r_user);

   assign #1 nasti.r_valid = r_valid;
   assign #1 nasti.r_data = r_data;
   assign #1 nasti.r_last = r_last;
   assign #1 nasti.r_id = r_id;
   assign #1 nasti.r_resp = r_resp;
   assign #1 nasti.r_user = r_user;

`endif
   
endmodule // nasti_ram_behav
