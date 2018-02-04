`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.02.2018 14:12:22
// Design Name: 
// Module Name: infer_bram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module infer_bram #(BRAM_SIZE=16, BRAM_WIDTH=128, IO_DAT_WIDTH=64)
(
input ram_clk, ram_en,
input [IO_DAT_WIDTH/8:0] ram_we,
input [BRAM_SIZE+$clog2(IO_DAT_WIDTH/8)-1:0] ram_addr,
input [IO_DAT_WIDTH-1:0] ram_wrdata,
output [IO_DAT_WIDTH-1:0] ram_rddata);

   localparam BRAM_LINE          = 2 ** BRAM_SIZE / (BRAM_WIDTH/8);
   localparam BRAM_OFFSET_BITS   = $clog2(IO_DAT_WIDTH/8);
   localparam BRAM_ADDR_LSB_BITS = $clog2(BRAM_WIDTH / IO_DAT_WIDTH);
   localparam BRAM_ADDR_BLK_BITS = BRAM_SIZE - BRAM_ADDR_LSB_BITS - BRAM_OFFSET_BITS;
   localparam WID_MULT = (BRAM_WIDTH / IO_DAT_WIDTH);
   
   initial assert (BRAM_OFFSET_BITS < 7) else $fatal(1, "Do not support BRAM AXI width > 64-bit!");

   reg   [BRAM_WIDTH-1:0]         ram [0 : BRAM_LINE-1];
   logic [BRAM_ADDR_BLK_BITS-1:0] ram_block_addr, ram_block_addr_delay;
   logic [BRAM_ADDR_LSB_BITS-1:0] ram_lsb_addr, ram_lsb_addr_delay;
   logic [BRAM_WIDTH/8-1:0]       ram_we_full;
   logic [BRAM_WIDTH-1:0]         ram_wrdata_full, ram_rddata_full;
   int                            ram_rddata_shift, ram_we_shift;

   assign ram_block_addr = ram_addr >> BRAM_ADDR_LSB_BITS + BRAM_OFFSET_BITS;
   assign ram_lsb_addr = ram_addr >> BRAM_OFFSET_BITS;
   assign ram_we_shift = ram_lsb_addr << BRAM_OFFSET_BITS; // avoid ISim error
   assign ram_we_full = ram_we << ram_we_shift;
   assign ram_wrdata_full = {WID_MULT{ram_wrdata}};

   always @(posedge ram_clk)
    begin
     if(ram_en) begin
        ram_block_addr_delay <= ram_block_addr;
        ram_lsb_addr_delay <= ram_lsb_addr;
        foreach (ram_we_full[i])
          if(ram_we_full[i]) ram[ram_block_addr][i*8 +:8] <= ram_wrdata_full[i*8 +: 8];
     end
    end

   assign ram_rddata_full = ram[ram_block_addr_delay];
   assign ram_rddata_shift = ram_lsb_addr_delay << (BRAM_OFFSET_BITS + 3); // avoid ISim error
   assign ram_rddata = ram_rddata_full >> ram_rddata_shift;

endmodule
