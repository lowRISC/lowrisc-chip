// See LICENSE for license details.

module tb;

   logic clk, rst;

   chip_top
     DUT(
         .clk_p(clk),
         .clk_n(!clk),
         .rst_top(rst), 
         .rxd(1'b1)
         );
   
   initial begin
      rst = 0;
      #3;
      rst = 1;
      #130;
      rst = 0;
   end

   initial begin
      clk = 0;
      forever clk = #5 !clk;
   end // initial begin
   
endmodule // tb
