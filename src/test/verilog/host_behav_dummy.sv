// See LICENSE for license details.

module host_behav
  #(
    ID_WIDTH = 1,               // id width
    USER_WIDTH = 1              // width of user field
    )
   (
    input logic           clk, rstn,
    input logic           req_valid, resp_ready,
    nasti_channel.slave   nasti
    );

   import "DPI-C" function void host_req ( input int unsigned id, input longint unsigned data);
   import "DPI-C" function int check_exit ();

   assign nasti.ar_ready = 0;
   assign nasti.r_valid = 0;

   logic                  aw_fire;
   logic [ID_WIDTH-1:0]   b_id;
   logic [USER_WIDTH-1:0] b_user;

   always_ff @(posedge clk or negedge rstn)
   if(!rstn)
     aw_fire <= 0;
   else if(nasti.aw_valid && nasti.aw_ready) begin
      aw_fire <= 1;
      b_id <= nasti.aw_id;
      b_user <= nasti.aw_user;
   end else if(nasti.w_valid && nasti.w_ready)
     aw_fire <= 0;

   assign nasti.aw_ready = !aw_fire;
   assign nasti.w_ready = aw_fire;

   logic                  b_fire;
   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       b_fire <= 0;
     else if(nasti.b_valid && !nasti.b_ready)
       b_fire <= 1;
     else
       b_fire <= 0;

   assign nasti.b_valid = nasti.w_valid && nasti.w_ready || b_fire;

   assign nasti.b_id = b_id;
   assign nasti.b_resp = 0;
   assign nasti.b_user = b_user;

   logic [15:0]           msg_id, msg_data;
   assign msg_id = nasti.w_data >> 16;
   assign msg_data = nasti.w_data;

   always @(posedge clk)
     if(nasti.w_valid && nasti.w_ready)
       host_req(msg_id, msg_data);

endmodule // host_behav
