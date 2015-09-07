// See LICENSE for license details.

module axi_ram_behav
  #(
    ID_WIDTH = 1,
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128,
    USER_WIDTH = 1
    )
   (
    input clk, rstn,
    nasti_aw.slave aw,
    nasti_w.slave w,
    nasti_b.slave b,
    nasti_ar.slave ar,
    nasti_r.slave r
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
   
   always_comb
     if(aw.valid && rstn)
       aw.ready = memory_write_req(aw.id, aw.addr, aw.len, aw.size, aw.user);
     else
       aw.ready = 0;

   always_comb
     if(w.valid && rstn)
       w.ready = memory_write_data(w.data, w.strb, w.last);
     else
       w.ready = 0;
      
   logic [15:0]   b_id;
   logic [1:0]    b_resp;
   logic [15:0]   b_user;
   logic          b_valid;
   
   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       b_valid <= 0;
     else if(!b_valid || b.ready)
       b_valid <= memory_write_resp(b_id, b_resp, b_user);
   
   assign b.valid = b_valid;
   assign b.id = b_id;
   assign b.resp = b_resp;
   assign b.user = b_user;

   always_comb
     if(ar.valid && rstn)
       ar.ready = memory_read_req(ar.id, ar.addr, ar.len, ar.size, ar.user);
     else
       ar.ready = 0;

   logic [15:0]   r_id;
   logic [255:0]  r_data;
   logic [1:0]    r_resp;
   logic          r_last;
   logic [15:0]   r_user;
   logic          r_valid;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       r_valid <= 0;
     else if(!b_valid || b.ready)
       r_valid <= memory_read_resp(r_id, r_data, r_resp, r_last, r_user);
   
   assign r.valid = r_valid;
   assign r.data = r_data;
   assign r.last = r_last;
   assign r.id = r_id;
   assign r.resp = r_resp;
   assign r.user = r_user;
   
endmodule // axi_ram_behav

   
            
                                 
   

