// See LICENSE for license details.

module host_behav
  #(nCores = 1)
   (
    input logic           clk, rstn,
    input logic           req_valid, resp_ready,
    output logic          req_ready,
    output reg            resp_valid,
    input logic [$clog2(nCores)-1:0] req_id,
    output reg [$clog2(nCores)-1:0]  resp_id,
    input logic [63:0]    req,
    output reg [63:0]     resp
    );

   localparam IDW = $clog2(nCores);

   import "DPI-C" function void host_req ( input int unsigned id, input longint unsigned data);

   assign req_ready = 0;

   initial begin
      resp = 0;
      resp_id = 0;
      resp_valid = 1'b0;
   end
   
   always @(posedge clk)
     if(rstn && req_valid)
       host_req(req_id, req);

   task host_resp (input int unsigned id, input longint unsigned data);
      resp = data;
      resp_id = id;
      resp_valid = 1'b1;
   endtask // host_resp

   always @(posedge clk)
     if(rstn && resp_ready && resp_valid)
       resp_valid = 1'b0;

endmodule // host_behav
