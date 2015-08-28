// See LICENSE for license details.

module axi_ram_behav
  #(
    ID_WIDTH = 1,
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128
    USER_WIDTH = 1,
    FIFO_DEPTH = 16
    )
   (
    input clk, rstn,
    nasti_aw.slave aw,
    nasti_w.slave w,
    nasti_b.slave b,
    nasti_ar.slave ar,
    nasti_r.slave r
    );

   localparam aw_w = ID_WIDTH + ADDR_WIDTH + 13 + USER_WIDTH;
   logic [ID_WIDTH-1:0]   aw_id;
   logic [ADDR_WIDTH-1:0] aw_addr;
   logic [7:0]            aw_len;
   logic [2:0]            aw_size;
   logic [1:0]            aw_burst;
   logic                  aw_valid;
   logic                  aw_ready;
   fifo_ram_sync #(.Depth(FIFO_DEPTH), .Width(aw_w))
   awFIFO (
           .*,
           .write_valid   ( nasti_aw.valid                                                           ),
           .write_data    ( {nasti_aw.id, nasti_aw.addr, nasti_aw.len, nasti_aw.size, nasti_aw.user} ),
           .write_ready   ( nasti_aw.ready                                                           ),
           .read_valid    ( aw_valid                                                                 ),
           .read_data     ( {aw_id, aw_addr, aw_len, aw_size, aw_user}                               ),
           .read_ready    ( aw_ready                                                                 )
           );

   localparam w_w = DATA_WIDTH + DATA_WIDTH/8 + 1 + USER_WIDTH;
   logic [DATA_WIDTH-1:0]   w_data;
   logic [DATA_WIDTH/8-1:0] w_strb;
   logic                    w_last;
   logic [USER_WIDTH-1:0]   w_user;
   logic                    w_valid;
   logic                    w_ready;
   fifo_ram_sync #(.Depth(FIFO_DEPTH), .Width(w_w))
   wFIFO (
          .*,
          .write_valid   ( nasti_w.valid                                            ),
          .write_data    ( {nasti_w.data, nasti_w.strb, nasti_w.last, nasti_w.user} ),
          .write_ready   ( nasti_w.ready                                            ),
          .read_valid    ( w_valid                                                  ),
          .read_data     ( {w_data, w_strb, w_last, w_user}                         ),
          .read_ready    ( w_ready                                                  )
          );
   
   localparam b_w = ID_WIDTH + 2 + USER_WIDTH;
   logic [ID_WIDTH-1:0]   b_id;
   logic [1:0]            b_resp;
   logic [USER_WIDTH-1:0] b_user;
   logic                  b_valid;
   logic                  b_ready;
   fifo_ram_sync #(.Depth(FIFO_DEPTH), .Width(b_w))
   bFIFO (
          .*,
          .write_valid   ( b_valid                                  ),
          .write_data    ( {b_id, b_resp, w_user}                   ),
          .write_ready   ( b_ready                                  ),
          .read_valid    ( nasti_b.valid                            ),
          .read_data     ( {nasti_b.id, nasti_b.resp, nasti_b.user} ),
          .read_ready    ( nasti_b.ready                            )
          );
   
   localparam ar_w = ID_WIDTH + ADDR_WIDTH + 13 + USER_WIDTH;
   logic [ID_WIDTH-1:0]   ar_id;
   logic [ADDR_WIDTH-1:0] ar_addr;
   logic [7:0]            ar_len;
   logic [2:0]            ar_size;
   logic [1:0]            ar_burst;
   logic                  ar_valid;
   logic                  ar_ready;
   fifo_ram_sync #(.Depth(FIFO_DEPTH), .Width(ar_w))
   arFIFO (
           .*,
           .write_valid   ( nasti_ar.valid                                                           ),
           .write_data    ( {nasti_ar.id, nasti_ar.addr, nasti_ar.len, nasti_ar.size, nasti_ar.user} ),
           .write_ready   ( nasti_ar.ready                                                           ),
           .read_valid    ( ar_valid                                                                 ),
           .read_data     ( {ar_id, ar_addr, ar_len, ar_size, ar_user}                               ),
           .read_ready    ( ar_ready                                                                 )
           );

   localparam r_w = ID_WIDTH + DATA_WIDTH + 3 + USER_WIDTH;
   logic [ID_WIDTH-1:0]   r_id;
   logic [DATA_WIDTH-1:0] r_data;
   logic [1:0]            r_resp;
   logic                  r_last;
   logic [USER_WIDTH-1:0] r_user;
   logic                  r_valid;
   logic                  r_ready;
   fifo_ram_sync #(.Depth(FIFO_DEPTH), .Width(r_w))
   rFIFO (
          .*,
          .write_valid   ( r_valid                                                              ),
          .write_data    ( {r_id, r_data, r_resp, r_last, r_user}                               ),
          .write_ready   ( r_ready                                                              ),
          .read_valid    ( nasti_r.valid                                                        ),
          .read_data     ( {nasti_r.id, nasti_r.data, nasti_r.resp, nasti_r.last, nasti_r.user} ),
          .read_ready    ( nasti_r.ready                                                        )
          );


   localparam s_w_idle = 0, s_w_data = 1;

   always_ff @(posedge clk or negedge rstn)



   
   
endmodule // axi_ram_behav


module ram_reader_behav
  #(
    ID_WIDTH = 1,
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128,
    USER_WIDTH = 1
    )
   (
    input logic                    clk, rstn,
    input logic [ID_WIDTH-1:0]     ar_id,
    input logic [USER_WIDTH-1:0]   ar_user,
    input logic [7:0]              ar_len,
    input logic [2:0]              ar_size,
    input logic [1:0]              ar_burst,
    input reg   [DATA_WIDTH-1:0]   r_data,
    input logic [DATA_WIDTH/8-1:0] r_strb,
    input logic                    r_last,
    output logic [ID_WIDTH-1:0]    r_id,
    output logic [USER_WIDTH-1:0]  r_user,
    output logic [1:0]             r_resp,
    input logic                    ar_valid, r_ready,
    output logic                   ar_ready, r_valid,
    );

   localparam
     s_req = 0,
     s_resp = 1;

   initial assert(DATA_WIDTH%32 == 0, "Error: DATA_WIDTH should be integer times of 32 bits!")
   
   reg [3:0]                       state;
   reg [DATA_WIDTH/32-1:0]         memory_ready;
   logic                           data_ready;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
        state <= s_req;
     else
       case(state)
          s_req:  if(ar_valid && ar_ready)            state <= s_resp;
          s_resp: if(r_valid && r_ready && len == 0)  state <= s_req;
       endcase // case (state)

   assign ar_ready = state == s_req;
   assign data_ready = |memory_ready;
   assign r_valid = satte == s_resp && data_ready;

   logic [ID_WIDTH-1:0]            id;
   logic [USER_WIDTH-1:0]          user;
   logic [7:0]                     len;
   logic [2:0]                     size;
   logic [ADDR_WIDTH:0]            addr;

   always_ff @(posedge clk)
     if(ar_valid && ar_ready) begin
        id <= ar_id;
        user <= ar_user;
        len <= ar_len;
        size <= ar_size;
        addr <= ar_addr;
     end else if(r_valid && r_ready) begin
        len <= len - 1;
        addr <= addr + addr_step(size);
     end

   function logic [7:0] addr_step (logic [2:0] s) begin
      case(s) beign
        3'b000: return 1;
        3'b001: return 2;
        3'b010: return 4;
        3'b011: return 8;
        3'b100: return 16;
        3'b101: return 32;
        3'b110: return 64;
        3'b111: return 128;
      endcase // case (s)
   endfunction
   
   assign r_user = user;
   assign r_id = id;
   assign r_resp = 0;
   assign r_last = len == 0;
   
   genvar i;

   generate 
      for(i=0; i<DATA_WIDTH/32; i++) begin
         always @(posedge clk or negedge rstn)
           if(!rstn)
             memory_ready[i] <= 1'b0;
           else if(state == s_resp) begin
             if(i*4 < addr_step(size)) begin
                if(!memory_ready[i] || (r_valid && r_ready && len != 0))
                   memory_ready[i] <= memory_read(addr + i*4, r_data[i*4*8 +: 32]);
             end else
               memory_ready[i] <= 1'b1;
           end else
             memory_ready[i] <= 1'b0;
      end
   endgenerate

endmodule // ram_writer_behav

module ram_writer_behav
  #(
    ID_WIDTH = 1,
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128,
    USER_WIDTH = 1
    )
   (
    input logic                    clk, rstn,
    input logic [ID_WIDTH-1:0]     aw_id,
    input logic [USER_WIDTH-1:0]   aw_user,
    input logic [7:0]              aw_len,
    input logic [2:0]              aw_size,
    input logic [1:0]              aw_burst,
    input logic [DATA_WIDTH-1:0]   w_data,
    input logic [DATA_WIDTH/8-1:0] w_strb,
    input logic                    w_last,
    output logic [ID_WIDTH-1:0]    b_id,
    output logic [USER_WIDTH-1:0]  b_user,
    output logic [1:0]             b_resp,
    input logic                    aw_valid, aw_valid, b_ready,
    output logic                   aw_ready, w_ready, b_valid,
    );

   localparam
     s_req = 0,
     s_data = 1,
     s_resp = 2;

   initial assert(DATA_WIDTH%32 == 0, "Error: DATA_WIDTH should be integer times of 32 bits!")

   reg [3:0]                       state;

   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
        state <= s_req;
     else
       case(state)
          s_req:  if(aw_valid && aw_ready)            state <= s_data;
          s_data: if(w_valid && w_ready && len == 0)  begin
             state <= s_resp;
             assert(w_last, "Error: w_last should be high!");
          end
          s_resp: if(b_valid && b_ready)              state <= s_req;
       endcase // case (state)

   assign aw_ready = state == s_req;
   assign w_ready = state == s_data;
   assign b_valid = satte == s_resp;

   logic [ID_WIDTH-1:0]            id;
   logic [USER_WIDTH-1:0]          user;
   logic [7:0]                     len;
   logic [2:0]                     size;
   logic [ADDR_WIDTH:0]            addr;

   always_ff @(posedge clk)
     if(aw_valid && aw_ready) begin
        id <= aw_id;
        user <= aw_user;
        len <= aw_len;
        size <= aw_size;
        addr <= aw_addr;
     end else if(w_valid && w_ready) begin
        len <= len - 1;
        addr <= addr + addr_step(size);
     end

   function logic [7:0] addr_step (logic [2:0] s) begin
      case(s) beign
        3'b000: return 1;
        3'b001: return 2;
        3'b010: return 4;
        3'b011: return 8;
        3'b100: return 16;
        3'b101: return 32;
        3'b110: return 64;
        3'b111: return 128;
      endcase // case (s)
   endfunction
   
   assign b_user = user;
   assign b_id = id;
   assign b_resp = 0;

   genvar i;

   generate 
      for(i=0; i<DATA_WIDTH/32; i++) begin
         always @(posedge clk)
           if(i*4 < addr_step(size) && w_valid && w_ready) begin
              memory_write(addr + i*4, w_data[i*4*8 +: 32], w_strb[i*4 +: 4]);
           end
      end
   endgenerate

endmodule // ram_writer_behav

   
            
                                 
   

