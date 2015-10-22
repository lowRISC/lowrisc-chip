// See LICENSE for license details.

module nasti_ram_behav
  #(
    ID_WIDTH = 1,
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

`ifndef VERILATOR
   initial memory_model_init();
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

   assign nasti.b_valid = b_valid;
   assign nasti.b_id = b_id;
   assign nasti.b_resp = b_resp;
   assign nasti.b_user = b_user;

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

   assign nasti.r_valid = r_valid;
   assign nasti.r_data = r_data;
   assign nasti.r_last = r_last;
   assign nasti.r_id = r_id;
   assign nasti.r_resp = r_resp;
   assign nasti.r_user = r_user;

endmodule // nasti_ram_behav
