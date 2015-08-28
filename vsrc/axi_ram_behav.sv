// See LICENSE for license details.

module axi_ram_behav
  #(
    ID_WIDTH = 1,
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128
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

   initial assert(ID_WIDTH <= 16, "Error: ID_WIDTH > 16 is not supported!");
   initial assert(ADDR_WIDTH <= 64, "Error: ADDR_WIDTH > 64 is not supported!");
   initial assert(DATA_WIDTH <= 256, "Error: DATA_WIDTH > 256 is not supported!");
   initial assert(USER_WIDTH <= 16, "Error: USER_WIDTH > 16 is not supported!");
   
   import "DPI-C" function bit memory_write_req (
                                                 input logic [15:0] id,
                                                 input logic [63:0] addr,
                                                 input logic [7:0]  len,
                                                 input logic [2:0]  size,
                                                 input logic [15:0] user
                                                 );

   import "DPI-C" function bit memory_write_data (
                                                  input logic [255:0] data,
                                                  input logic [31:0]  strb,
                                                  input logic         last
                                                  );
   
   import "DPI-C" function bit memory_write_resp (
                                                  output logic [15:0] id,
                                                  output logic [1:0]  resp,
                                                  output logic [15:0] user
                                                  );
   
   import "DPI-C" function bit memory_read_req (
                                                input logic [15:0] id,
                                                input logic [63:0] addr,
                                                input logic [7:0]  len,
                                                input logic [2:0]  size,
                                                input logic [15:0] user
                                                );
   
   import "DPI-C" function bit memory_read_resp (
                                                 output logic [15:0]  id,
                                                 output logic [255:0] data,
                                                 output logic [1:0]   resp,
                                                 output logic         last,
                                                 output logic [15:0]  user
                                                 );
   
   always_comb
     if(nasti_aw.valid)
       nasti_aw.ready = memory_write_req(nasti_aw.id, nasti_aw.addr, nasti_aw.len, nasti_aw.size, nasti_aw.user);
     else
       nasti_aw.ready = 0;

   always_comb
     if(nasti_w.valid)
       nasti_w.ready = memory_write_data(nasti_w.data, nasti_w.strb, nasti_w.last);
     else
       nasti_w.ready = 0;
      
   logic [ID_WIDTH-1:0]   b_id;
   logic [1:0]            b_resp;
   logic [USER_WIDTH-1:0] b_user;
   logic                  b_valid;
   
   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       b_valid <= 0;
     else if(!b_valid || nasti_b.ready)
       b_valid <= memory_write_resp(b_id, b_resp, b_user);
   
   assign nasti_b.valid = b_valid;
   assign nasti_b.id = b_id;
   assign nasti_b.resp = b_resp;
   assign nasti_b.user = b_user;

   always_comb
     if(nasti_ar.valid)
       nasti_ar.ready = memory_read_req(nasti_ar.id, nasti_ar.addr, nasti_ar.len, nasti_ar.size, nasti_ar.user);
     else
       nasti_ar.ready = 0;

   logic [ID_WIDTH-1:0]   r_id;
   logic [DATA_WIDTH-1:0] r_data;
   logic [1:0]            r_resp;
   logic                  r_last;
   logic [USER_WIDTH-1:0] r_user;
   logic                  r_valid;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       r_valid <= 0;
     else if(!b_valid || nasti_b.ready)
       r_valid <= memory_read_resp(r_id, r_data, r_resp, r_last, r_user);
   
   assign nasti_r.valid = r_valid;
   assign nasti_r.data = r_data;
   assign nasti_r.last = r_last;
   assign nasti_r.id = r_id;
   assign nasti_r.resp = r_resp;
   assign nasti_r.user = r_user;
   
endmodule // axi_ram_behav

   
            
                                 
   

