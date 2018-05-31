/*
Copyright 2015-2017 University of Cambridge
Copyright and related rights are licensed under the Solderpad Hardware
License, Version 0.51 (the “License”); you may not use this file except in
compliance with the License. You may obtain a copy of the License at
http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
or agreed to in writing, software, hardware and materials distributed under
this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
*/

// ASCII character set ROM (like the good old RO-3-2513)

module chargen_7x5_rachel(input clk, input [7:0] ascii, input[3:0] row, output [7:0] pixels_out);
`ifndef FPGA

   reg[7:0] lower [0:32*12-1];
   reg[7:0] upper [0:64*8-1];
   reg inverse;
   wire [5:0] char6 = ascii[5:0];
   wire[15:0] l_address = (ascii[4:0] ^ 0) * 12 + row; // 32 chars in lower case generator.
   wire[15:0] u_address = (ascii[5:0] ^ 32) * 8 + row; // 64 chars in upper case generator
   reg [7:0] ld, ud;
   reg [1:0] sel;
   reg blank_upper, blank_lower;
   always @(posedge clk) begin
      ld <= lower [l_address];
      ud <= upper [u_address];      
      sel <= ascii[6:5];
      blank_upper <= row >= 8;   // Upper case does not have the extra four lines, so needs blanking.
      blank_lower <= row >= 12;
      inverse <= ascii [7];
   end

   assign pixels_out =  // Msb is first bit to render (leftmost).
    (inverse ? 8'hff:8'h00) ^
    ((sel==2'b00) ? (blank_lower ? 8'h00: 8'h3E):// Control chars - display as BLOB
     (sel==2'b11) ? (blank_lower ? 8'h00: ld):   // Lower case is 0x60 to 0x7F.
                    (blank_upper ? 8'h00: ud));  // Upper data is from 0x20 to 0x5F (capitals and punctuation)

   initial begin // Initialise ROM.
 lower[12*8'h00 + 0] <= 8'h00; // backtick - ASCII character : ASCII 0x60
 lower[12*8'h00 + 1] <= 8'h00;
 lower[12*8'h00 + 2] <= 8'h20;
 lower[12*8'h00 + 3] <= 8'h10;
 lower[12*8'h00 + 4] <= 8'h08;
 lower[12*8'h00 + 5] <= 8'h00;
 lower[12*8'h00 + 6] <= 8'h00;
 lower[12*8'h00 + 7] <= 8'h00;
 lower[12*8'h00 + 8] <= 8'h00;
 lower[12*8'h00 + 9] <= 8'h00;
 lower[12*8'h00 + 10] <= 8'h00;
 lower[12*8'h00 + 11] <= 8'h00;
 lower[12*8'h01 + 0] <= 8'h00;
 lower[12*8'h01 + 1] <= 8'h00;
 lower[12*8'h01 + 2] <= 8'h00;
 lower[12*8'h01 + 3] <= 8'h30;
 lower[12*8'h01 + 4] <= 8'h08;
 lower[12*8'h01 + 5] <= 8'h04;
 lower[12*8'h01 + 6] <= 8'h3C;
 lower[12*8'h01 + 7] <= 8'h44;
 lower[12*8'h01 + 8] <= 8'h3A;
 lower[12*8'h01 + 9] <= 8'h00;
 lower[12*8'h01 + 10] <= 8'h00;
 lower[12*8'h01 + 11] <= 8'h00;
 lower[12*8'h02 + 0] <= 8'h00;
 lower[12*8'h02 + 1] <= 8'h00;
 lower[12*8'h02 + 2] <= 8'h40;
 lower[12*8'h02 + 3] <= 8'h40;
 lower[12*8'h02 + 4] <= 8'h58;
 lower[12*8'h02 + 5] <= 8'h64;
 lower[12*8'h02 + 6] <= 8'h44;
 lower[12*8'h02 + 7] <= 8'h64;
 lower[12*8'h02 + 8] <= 8'h98;
 lower[12*8'h02 + 9] <= 8'h00;
 lower[12*8'h02 + 10] <= 8'h00;
 lower[12*8'h02 + 11] <= 8'h00;
 lower[12*8'h03 + 0] <= 8'h00;
 lower[12*8'h03 + 1] <= 8'h00;
 lower[12*8'h03 + 2] <= 8'h00;
 lower[12*8'h03 + 3] <= 8'h00;
 lower[12*8'h03 + 4] <= 8'h38;
 lower[12*8'h03 + 5] <= 8'h44;
 lower[12*8'h03 + 6] <= 8'h40;
 lower[12*8'h03 + 7] <= 8'h44;
 lower[12*8'h03 + 8] <= 8'h38;
 lower[12*8'h03 + 9] <= 8'h00;
 lower[12*8'h03 + 10] <= 8'h00;
 lower[12*8'h03 + 11] <= 8'h00;
 lower[12*8'h04 + 0] <= 8'h00;
 lower[12*8'h04 + 1] <= 8'h00;
 lower[12*8'h04 + 2] <= 8'h04;
 lower[12*8'h04 + 3] <= 8'h04;
 lower[12*8'h04 + 4] <= 8'h34;
 lower[12*8'h04 + 5] <= 8'h4C;
 lower[12*8'h04 + 6] <= 8'h44;
 lower[12*8'h04 + 7] <= 8'h4C;
 lower[12*8'h04 + 8] <= 8'h32;
 lower[12*8'h04 + 9] <= 8'h00;
 lower[12*8'h04 + 10] <= 8'h00;
 lower[12*8'h04 + 11] <= 8'h00;
 lower[12*8'h05 + 0] <= 8'h00;
 lower[12*8'h05 + 1] <= 8'h00;
 lower[12*8'h05 + 2] <= 8'h00;
 lower[12*8'h05 + 3] <= 8'h00;
 lower[12*8'h05 + 4] <= 8'h38;
 lower[12*8'h05 + 5] <= 8'h44;
 lower[12*8'h05 + 6] <= 8'h78;
 lower[12*8'h05 + 7] <= 8'h40;
 lower[12*8'h05 + 8] <= 8'h38;
 lower[12*8'h05 + 9] <= 8'h00;
 lower[12*8'h05 + 10] <= 8'h00;
 lower[12*8'h05 + 11] <= 8'h00;
 lower[12*8'h06 + 0] <= 8'h00;
 lower[12*8'h06 + 1] <= 8'h00;
 lower[12*8'h06 + 2] <= 8'h18;
 lower[12*8'h06 + 3] <= 8'h24;
 lower[12*8'h06 + 4] <= 8'h70;
 lower[12*8'h06 + 5] <= 8'h20;
 lower[12*8'h06 + 6] <= 8'h20;
 lower[12*8'h06 + 7] <= 8'h20;
 lower[12*8'h06 + 8] <= 8'h20;
 lower[12*8'h06 + 9] <= 8'h00;
 lower[12*8'h06 + 10] <= 8'h00;
 lower[12*8'h06 + 11] <= 8'h00;
 lower[12*8'h07 + 0] <= 8'h00;
 lower[12*8'h07 + 1] <= 8'h00;
 lower[12*8'h07 + 2] <= 8'h00;
 lower[12*8'h07 + 3] <= 8'h00;
 lower[12*8'h07 + 4] <= 8'h38;
 lower[12*8'h07 + 5] <= 8'h44;
 lower[12*8'h07 + 6] <= 8'h44;
 lower[12*8'h07 + 7] <= 8'h4C;
 lower[12*8'h07 + 8] <= 8'h34;
 lower[12*8'h07 + 9] <= 8'h04;
 lower[12*8'h07 + 10] <= 8'h44;
 lower[12*8'h07 + 11] <= 8'h38;
 lower[12*8'h08 + 0] <= 8'h00;
 lower[12*8'h08 + 1] <= 8'h00;
 lower[12*8'h08 + 2] <= 8'h40;
 lower[12*8'h08 + 3] <= 8'h40;
 lower[12*8'h08 + 4] <= 8'h58;
 lower[12*8'h08 + 5] <= 8'h64;
 lower[12*8'h08 + 6] <= 8'h44;
 lower[12*8'h08 + 7] <= 8'h44;
 lower[12*8'h08 + 8] <= 8'h44;
 lower[12*8'h08 + 9] <= 8'h00;
 lower[12*8'h08 + 10] <= 8'h00;
 lower[12*8'h08 + 11] <= 8'h00;
 lower[12*8'h09 + 0] <= 8'h00;
 lower[12*8'h09 + 1] <= 8'h00;
 lower[12*8'h09 + 2] <= 8'h10;
 lower[12*8'h09 + 3] <= 8'h00;
 lower[12*8'h09 + 4] <= 8'h30;
 lower[12*8'h09 + 5] <= 8'h10;
 lower[12*8'h09 + 6] <= 8'h10;
 lower[12*8'h09 + 7] <= 8'h10;
 lower[12*8'h09 + 8] <= 8'h38;
 lower[12*8'h09 + 9] <= 8'h00;
 lower[12*8'h09 + 10] <= 8'h00;
 lower[12*8'h09 + 11] <= 8'h00;
 lower[12*8'h0A + 0] <= 8'h00;
 lower[12*8'h0A + 1] <= 8'h00;
 lower[12*8'h0A + 2] <= 8'h08;
 lower[12*8'h0A + 3] <= 8'h00;
 lower[12*8'h0A + 4] <= 8'h18;
 lower[12*8'h0A + 5] <= 8'h08;
 lower[12*8'h0A + 6] <= 8'h08;
 lower[12*8'h0A + 7] <= 8'h08;
 lower[12*8'h0A + 8] <= 8'h08;
 lower[12*8'h0A + 9] <= 8'h48;
 lower[12*8'h0A + 10] <= 8'h30;
 lower[12*8'h0A + 11] <= 8'h00;
 lower[12*8'h0B + 0] <= 8'h00;
 lower[12*8'h0B + 1] <= 8'h00;
 lower[12*8'h0B + 2] <= 8'h40;
 lower[12*8'h0B + 3] <= 8'h40;
 lower[12*8'h0B + 4] <= 8'h44;
 lower[12*8'h0B + 5] <= 8'h48;
 lower[12*8'h0B + 6] <= 8'h70;
 lower[12*8'h0B + 7] <= 8'h48;
 lower[12*8'h0B + 8] <= 8'h44;
 lower[12*8'h0B + 9] <= 8'h00;
 lower[12*8'h0B + 10] <= 8'h00;
 lower[12*8'h0B + 11] <= 8'h00;
 lower[12*8'h0C + 0] <= 8'h00;
 lower[12*8'h0C + 1] <= 8'h00;
 lower[12*8'h0C + 2] <= 8'h30;
 lower[12*8'h0C + 3] <= 8'h10;
 lower[12*8'h0C + 4] <= 8'h10;
 lower[12*8'h0C + 5] <= 8'h10;
 lower[12*8'h0C + 6] <= 8'h10;
 lower[12*8'h0C + 7] <= 8'h10;
 lower[12*8'h0C + 8] <= 8'h38;
 lower[12*8'h0C + 9] <= 8'h00;
 lower[12*8'h0C + 10] <= 8'h00;
 lower[12*8'h0C + 11] <= 8'h00;
 lower[12*8'h0D + 0] <= 8'h00;
 lower[12*8'h0D + 1] <= 8'h00;
 lower[12*8'h0D + 2] <= 8'h00;
 lower[12*8'h0D + 3] <= 8'h00;
 lower[12*8'h0D + 4] <= 8'h38;
 lower[12*8'h0D + 5] <= 8'h54;
 lower[12*8'h0D + 6] <= 8'h54;
 lower[12*8'h0D + 7] <= 8'h54;
 lower[12*8'h0D + 8] <= 8'h54;
 lower[12*8'h0D + 9] <= 8'h00;
 lower[12*8'h0D + 10] <= 8'h00;
 lower[12*8'h0D + 11] <= 8'h00;
 lower[12*8'h0E + 0] <= 8'h00;
 lower[12*8'h0E + 1] <= 8'h00;
 lower[12*8'h0E + 2] <= 8'h00;
 lower[12*8'h0E + 3] <= 8'h00;
 lower[12*8'h0E + 4] <= 8'h58;
 lower[12*8'h0E + 5] <= 8'h64;
 lower[12*8'h0E + 6] <= 8'h44;
 lower[12*8'h0E + 7] <= 8'h44;
 lower[12*8'h0E + 8] <= 8'h44;
 lower[12*8'h0E + 9] <= 8'h00;
 lower[12*8'h0E + 10] <= 8'h00;
 lower[12*8'h0E + 11] <= 8'h00;
 lower[12*8'h0F + 0] <= 8'h00;
 lower[12*8'h0F + 1] <= 8'h00;
 lower[12*8'h0F + 2] <= 8'h00;
 lower[12*8'h0F + 3] <= 8'h00;
 lower[12*8'h0F + 4] <= 8'h38;
 lower[12*8'h0F + 5] <= 8'h44;
 lower[12*8'h0F + 6] <= 8'h44;
 lower[12*8'h0F + 7] <= 8'h44;
 lower[12*8'h0F + 8] <= 8'h38;
 lower[12*8'h0F + 9] <= 8'h00;
 lower[12*8'h0F + 10] <= 8'h00;
 lower[12*8'h0F + 11] <= 8'h00;
 lower[12*8'h10 + 0] <= 8'h00;
 lower[12*8'h10 + 1] <= 8'h00;
 lower[12*8'h10 + 2] <= 8'h00;
 lower[12*8'h10 + 3] <= 8'h00;
 lower[12*8'h10 + 4] <= 8'h98;
 lower[12*8'h10 + 5] <= 8'h64;
 lower[12*8'h10 + 6] <= 8'h44;
 lower[12*8'h10 + 7] <= 8'h64;
 lower[12*8'h10 + 8] <= 8'h58;
 lower[12*8'h10 + 9] <= 8'h40;
 lower[12*8'h10 + 10] <= 8'h40;
 lower[12*8'h10 + 11] <= 8'h40;
 lower[12*8'h11 + 0] <= 8'h00;
 lower[12*8'h11 + 1] <= 8'h00;
 lower[12*8'h11 + 2] <= 8'h00;
 lower[12*8'h11 + 3] <= 8'h00;
 lower[12*8'h11 + 4] <= 8'h34;
 lower[12*8'h11 + 5] <= 8'h4C;
 lower[12*8'h11 + 6] <= 8'h44;
 lower[12*8'h11 + 7] <= 8'h4C;
 lower[12*8'h11 + 8] <= 8'h34;
 lower[12*8'h11 + 9] <= 8'h04;
 lower[12*8'h11 + 10] <= 8'h06;
 lower[12*8'h11 + 11] <= 8'h04;
 lower[12*8'h12 + 0] <= 8'h00;
 lower[12*8'h12 + 1] <= 8'h00;
 lower[12*8'h12 + 2] <= 8'h00;
 lower[12*8'h12 + 3] <= 8'h00;
 lower[12*8'h12 + 4] <= 8'h58;
 lower[12*8'h12 + 5] <= 8'h64;
 lower[12*8'h12 + 6] <= 8'h40;
 lower[12*8'h12 + 7] <= 8'h40;
 lower[12*8'h12 + 8] <= 8'h40;
 lower[12*8'h12 + 9] <= 8'h00;
 lower[12*8'h12 + 10] <= 8'h00;
 lower[12*8'h12 + 11] <= 8'h00;
 lower[12*8'h13 + 0] <= 8'h00;
 lower[12*8'h13 + 1] <= 8'h00;
 lower[12*8'h13 + 2] <= 8'h00;
 lower[12*8'h13 + 3] <= 8'h00;
 lower[12*8'h13 + 4] <= 8'h38;
 lower[12*8'h13 + 5] <= 8'h40;
 lower[12*8'h13 + 6] <= 8'h38;
 lower[12*8'h13 + 7] <= 8'h04;
 lower[12*8'h13 + 8] <= 8'h38;
 lower[12*8'h13 + 9] <= 8'h00;
 lower[12*8'h13 + 10] <= 8'h00;
 lower[12*8'h13 + 11] <= 8'h00;
 lower[12*8'h14 + 0] <= 8'h00;
 lower[12*8'h14 + 1] <= 8'h00;
 lower[12*8'h14 + 2] <= 8'h10;
 lower[12*8'h14 + 3] <= 8'h10;
 lower[12*8'h14 + 4] <= 8'h38;
 lower[12*8'h14 + 5] <= 8'h10;
 lower[12*8'h14 + 6] <= 8'h10;
 lower[12*8'h14 + 7] <= 8'h12;
 lower[12*8'h14 + 8] <= 8'h0C;
 lower[12*8'h14 + 9] <= 8'h00;
 lower[12*8'h14 + 10] <= 8'h00;
 lower[12*8'h14 + 11] <= 8'h00;
 lower[12*8'h15 + 0] <= 8'h00;
 lower[12*8'h15 + 1] <= 8'h00;
 lower[12*8'h15 + 2] <= 8'h00;
 lower[12*8'h15 + 3] <= 8'h00;
 lower[12*8'h15 + 4] <= 8'h44;
 lower[12*8'h15 + 5] <= 8'h44;
 lower[12*8'h15 + 6] <= 8'h44;
 lower[12*8'h15 + 7] <= 8'h4C;
 lower[12*8'h15 + 8] <= 8'h34;
 lower[12*8'h15 + 9] <= 8'h00;
 lower[12*8'h15 + 10] <= 8'h00;
 lower[12*8'h15 + 11] <= 8'h00;
 lower[12*8'h16 + 0] <= 8'h00;
 lower[12*8'h16 + 1] <= 8'h00;
 lower[12*8'h16 + 2] <= 8'h00;
 lower[12*8'h16 + 3] <= 8'h00;
 lower[12*8'h16 + 4] <= 8'h44;
 lower[12*8'h16 + 5] <= 8'h44;
 lower[12*8'h16 + 6] <= 8'h44;
 lower[12*8'h16 + 7] <= 8'h28;
 lower[12*8'h16 + 8] <= 8'h10;
 lower[12*8'h16 + 9] <= 8'h00;
 lower[12*8'h16 + 10] <= 8'h00;
 lower[12*8'h16 + 11] <= 8'h00;
 lower[12*8'h17 + 0] <= 8'h00;
 lower[12*8'h17 + 1] <= 8'h00;
 lower[12*8'h17 + 2] <= 8'h00;
 lower[12*8'h17 + 3] <= 8'h00;
 lower[12*8'h17 + 4] <= 8'h44;
 lower[12*8'h17 + 5] <= 8'h54;
 lower[12*8'h17 + 6] <= 8'h54;
 lower[12*8'h17 + 7] <= 8'h54;
 lower[12*8'h17 + 8] <= 8'h38;
 lower[12*8'h17 + 9] <= 8'h00;
 lower[12*8'h17 + 10] <= 8'h00;
 lower[12*8'h17 + 11] <= 8'h00;
 lower[12*8'h18 + 0] <= 8'h00;
 lower[12*8'h18 + 1] <= 8'h00;
 lower[12*8'h18 + 2] <= 8'h00;
 lower[12*8'h18 + 3] <= 8'h00;
 lower[12*8'h18 + 4] <= 8'h44;
 lower[12*8'h18 + 5] <= 8'h28;
 lower[12*8'h18 + 6] <= 8'h10;
 lower[12*8'h18 + 7] <= 8'h28;
 lower[12*8'h18 + 8] <= 8'h44;
 lower[12*8'h18 + 9] <= 8'h00;
 lower[12*8'h18 + 10] <= 8'h00;
 lower[12*8'h18 + 11] <= 8'h00;
 lower[12*8'h19 + 0] <= 8'h00;
 lower[12*8'h19 + 1] <= 8'h00;
 lower[12*8'h19 + 2] <= 8'h00;
 lower[12*8'h19 + 3] <= 8'h00;
 lower[12*8'h19 + 4] <= 8'h44;
 lower[12*8'h19 + 5] <= 8'h44;
 lower[12*8'h19 + 6] <= 8'h44;
 lower[12*8'h19 + 7] <= 8'h44;
 lower[12*8'h19 + 8] <= 8'h34;
 lower[12*8'h19 + 9] <= 8'h04;
 lower[12*8'h19 + 10] <= 8'h44;
 lower[12*8'h19 + 11] <= 8'h38;
 lower[12*8'h1A + 0] <= 8'h00;
 lower[12*8'h1A + 1] <= 8'h00;
 lower[12*8'h1A + 2] <= 8'h00;
 lower[12*8'h1A + 3] <= 8'h00;
 lower[12*8'h1A + 4] <= 8'h7C;
 lower[12*8'h1A + 5] <= 8'h08;
 lower[12*8'h1A + 6] <= 8'h10;
 lower[12*8'h1A + 7] <= 8'h20;
 lower[12*8'h1A + 8] <= 8'h7C;
 lower[12*8'h1A + 9] <= 8'h00;
 lower[12*8'h1A + 10] <= 8'h00;
 lower[12*8'h1A + 11] <= 8'h00;
 lower[12*8'h1B + 0] <= 8'h00;
 lower[12*8'h1B + 1] <= 8'h00;
 lower[12*8'h1B + 2] <= 8'h0C;
 lower[12*8'h1B + 3] <= 8'h10;
 lower[12*8'h1B + 4] <= 8'h10;
 lower[12*8'h1B + 5] <= 8'h60;
 lower[12*8'h1B + 6] <= 8'h10;
 lower[12*8'h1B + 7] <= 8'h10;
 lower[12*8'h1B + 8] <= 8'h0C;
 lower[12*8'h1B + 9] <= 8'h00;
 lower[12*8'h1B + 10] <= 8'h00;
 lower[12*8'h1B + 11] <= 8'h00;
 lower[12*8'h1C + 0] <= 8'h00;
 lower[12*8'h1C + 1] <= 8'h00;
 lower[12*8'h1C + 2] <= 8'h10;
 lower[12*8'h1C + 3] <= 8'h10;
 lower[12*8'h1C + 4] <= 8'h10;
 lower[12*8'h1C + 5] <= 8'h00;
 lower[12*8'h1C + 6] <= 8'h10;
 lower[12*8'h1C + 7] <= 8'h10;
 lower[12*8'h1C + 8] <= 8'h10;
 lower[12*8'h1C + 9] <= 8'h00;
 lower[12*8'h1C + 10] <= 8'h00;
 lower[12*8'h1C + 11] <= 8'h00;
 lower[12*8'h1D + 0] <= 8'h00;
 lower[12*8'h1D + 1] <= 8'h00;
 lower[12*8'h1D + 2] <= 8'h60;
 lower[12*8'h1D + 3] <= 8'h10;
 lower[12*8'h1D + 4] <= 8'h10;
 lower[12*8'h1D + 5] <= 8'h0C;
 lower[12*8'h1D + 6] <= 8'h10;
 lower[12*8'h1D + 7] <= 8'h10;
 lower[12*8'h1D + 8] <= 8'h60;
 lower[12*8'h1D + 9] <= 8'h00;
 lower[12*8'h1D + 10] <= 8'h00;
 lower[12*8'h1D + 11] <= 8'h00;
 lower[12*8'h1E + 0] <= 8'h00;
 lower[12*8'h1E + 1] <= 8'h00;
 lower[12*8'h1E + 2] <= 8'h00;
 lower[12*8'h1E + 3] <= 8'h7E;
 lower[12*8'h1E + 4] <= 8'h02;
 lower[12*8'h1E + 5] <= 8'h02;
 lower[12*8'h1E + 6] <= 8'h00;
 lower[12*8'h1E + 7] <= 8'h00;
 lower[12*8'h1E + 8] <= 8'h00;
 lower[12*8'h1E + 9] <= 8'h00;
 lower[12*8'h1E + 10] <= 8'h00;
 lower[12*8'h1E + 11] <= 8'h00;
 lower[12*8'h1F + 0] <= 8'h00;
 lower[12*8'h1F + 1] <= 8'h00;
 lower[12*8'h1F + 2] <= 8'h00;
 lower[12*8'h1F + 3] <= 8'h00;
 lower[12*8'h1F + 4] <= 8'h7C;
 lower[12*8'h1F + 5] <= 8'h7C;
 lower[12*8'h1F + 6] <= 8'h7C;
 lower[12*8'h1F + 7] <= 8'h7C;
 lower[12*8'h1F + 8] <= 8'h00;
 lower[12*8'h1F + 9] <= 8'h00;
 lower[12*8'h1F + 10] <= 8'h00;
 lower[12*8'h1F + 11] <= 8'h00;


 upper[8*8'h00 + 0] <= 8'h00; // Space character: ASCII character 0x20
 upper[8*8'h00 + 1] <= 8'h00;
 upper[8*8'h00 + 2] <= 8'h00;
 upper[8*8'h00 + 3] <= 8'h00;
 upper[8*8'h00 + 4] <= 8'h00;
 upper[8*8'h00 + 5] <= 8'h00;
 upper[8*8'h00 + 6] <= 8'h00;
 upper[8*8'h00 + 7] <= 8'h00;
 upper[8*8'h01 + 0] <= 8'h10; // Pling character !: ASCII character 0x21
 upper[8*8'h01 + 1] <= 8'h10;
 upper[8*8'h01 + 2] <= 8'h10;
 upper[8*8'h01 + 3] <= 8'h10;
 upper[8*8'h01 + 4] <= 8'h10;
 upper[8*8'h01 + 5] <= 8'h00;
 upper[8*8'h01 + 6] <= 8'h10;
 upper[8*8'h01 + 7] <= 8'h00;
 upper[8*8'h02 + 0] <= 8'h28;
 upper[8*8'h02 + 1] <= 8'h28;
 upper[8*8'h02 + 2] <= 8'h00;
 upper[8*8'h02 + 3] <= 8'h00;
 upper[8*8'h02 + 4] <= 8'h00;
 upper[8*8'h02 + 5] <= 8'h00;
 upper[8*8'h02 + 6] <= 8'h00;
 upper[8*8'h02 + 7] <= 8'h00;
 upper[8*8'h03 + 0] <= 8'h28;
 upper[8*8'h03 + 1] <= 8'h28;
 upper[8*8'h03 + 2] <= 8'h7C;
 upper[8*8'h03 + 3] <= 8'h28;
 upper[8*8'h03 + 4] <= 8'h7C;
 upper[8*8'h03 + 5] <= 8'h28;
 upper[8*8'h03 + 6] <= 8'h28;
 upper[8*8'h03 + 7] <= 8'h00;
 upper[8*8'h04 + 0] <= 8'h10;
 upper[8*8'h04 + 1] <= 8'h3C;
 upper[8*8'h04 + 2] <= 8'h50;
 upper[8*8'h04 + 3] <= 8'h70;
 upper[8*8'h04 + 4] <= 8'h1C;
 upper[8*8'h04 + 5] <= 8'h14;
 upper[8*8'h04 + 6] <= 8'h78;
 upper[8*8'h04 + 7] <= 8'h10;
 upper[8*8'h05 + 0] <= 8'h52;
 upper[8*8'h05 + 1] <= 8'h24;
 upper[8*8'h05 + 2] <= 8'h08;
 upper[8*8'h05 + 3] <= 8'h10;
 upper[8*8'h05 + 4] <= 8'h24;
 upper[8*8'h05 + 5] <= 8'h4A;
 upper[8*8'h05 + 6] <= 8'h04;
 upper[8*8'h05 + 7] <= 8'h00;
 upper[8*8'h06 + 0] <= 8'h30;
 upper[8*8'h06 + 1] <= 8'h48;
 upper[8*8'h06 + 2] <= 8'h50;
 upper[8*8'h06 + 3] <= 8'h20;
 upper[8*8'h06 + 4] <= 8'h54;
 upper[8*8'h06 + 5] <= 8'h48;
 upper[8*8'h06 + 6] <= 8'h34;
 upper[8*8'h06 + 7] <= 8'h00;
 upper[8*8'h07 + 0] <= 8'h18;
 upper[8*8'h07 + 1] <= 8'h18;
 upper[8*8'h07 + 2] <= 8'h20;
 upper[8*8'h07 + 3] <= 8'h00;
 upper[8*8'h07 + 4] <= 8'h00;
 upper[8*8'h07 + 5] <= 8'h00;
 upper[8*8'h07 + 6] <= 8'h00;
 upper[8*8'h07 + 7] <= 8'h00;
 upper[8*8'h08 + 0] <= 8'h08;
 upper[8*8'h08 + 1] <= 8'h10;
 upper[8*8'h08 + 2] <= 8'h20;
 upper[8*8'h08 + 3] <= 8'h20;
 upper[8*8'h08 + 4] <= 8'h20;
 upper[8*8'h08 + 5] <= 8'h10;
 upper[8*8'h08 + 6] <= 8'h08;
 upper[8*8'h08 + 7] <= 8'h00;
 upper[8*8'h09 + 0] <= 8'h20;
 upper[8*8'h09 + 1] <= 8'h10;
 upper[8*8'h09 + 2] <= 8'h08;
 upper[8*8'h09 + 3] <= 8'h08;
 upper[8*8'h09 + 4] <= 8'h08;
 upper[8*8'h09 + 5] <= 8'h10;
 upper[8*8'h09 + 6] <= 8'h20;
 upper[8*8'h09 + 7] <= 8'h00;
 upper[8*8'h0A + 0] <= 8'h10;
 upper[8*8'h0A + 1] <= 8'h54;
 upper[8*8'h0A + 2] <= 8'h38;
 upper[8*8'h0A + 3] <= 8'h7C;
 upper[8*8'h0A + 4] <= 8'h38;
 upper[8*8'h0A + 5] <= 8'h54;
 upper[8*8'h0A + 6] <= 8'h10;
 upper[8*8'h0A + 7] <= 8'h00;
 upper[8*8'h0B + 0] <= 8'h00;
 upper[8*8'h0B + 1] <= 8'h00;
 upper[8*8'h0B + 2] <= 8'h10;
 upper[8*8'h0B + 3] <= 8'h10;
 upper[8*8'h0B + 4] <= 8'h7C;
 upper[8*8'h0B + 5] <= 8'h10;
 upper[8*8'h0B + 6] <= 8'h10;
 upper[8*8'h0B + 7] <= 8'h00;
 upper[8*8'h0C + 0] <= 8'h00;
 upper[8*8'h0C + 1] <= 8'h00;
 upper[8*8'h0C + 2] <= 8'h00;
 upper[8*8'h0C + 3] <= 8'h00;
 upper[8*8'h0C + 4] <= 8'h00;
 upper[8*8'h0C + 5] <= 8'h18;
 upper[8*8'h0C + 6] <= 8'h18;
 upper[8*8'h0C + 7] <= 8'h20;
 upper[8*8'h0D + 0] <= 8'h00;
 upper[8*8'h0D + 1] <= 8'h00;
 upper[8*8'h0D + 2] <= 8'h00;
 upper[8*8'h0D + 3] <= 8'h00;
 upper[8*8'h0D + 4] <= 8'h7C;
 upper[8*8'h0D + 5] <= 8'h00;
 upper[8*8'h0D + 6] <= 8'h00;
 upper[8*8'h0D + 7] <= 8'h00;
 upper[8*8'h0E + 0] <= 8'h00;
 upper[8*8'h0E + 1] <= 8'h00;
 upper[8*8'h0E + 2] <= 8'h00;
 upper[8*8'h0E + 3] <= 8'h00;
 upper[8*8'h0E + 4] <= 8'h00;
 upper[8*8'h0E + 5] <= 8'h00;
 upper[8*8'h0E + 6] <= 8'h18;
 upper[8*8'h0E + 7] <= 8'h18;
 upper[8*8'h0F + 0] <= 8'h04;
 upper[8*8'h0F + 1] <= 8'h04;
 upper[8*8'h0F + 2] <= 8'h08;
 upper[8*8'h0F + 3] <= 8'h10;
 upper[8*8'h0F + 4] <= 8'h20;
 upper[8*8'h0F + 5] <= 8'h40;
 upper[8*8'h0F + 6] <= 8'h40;
 upper[8*8'h0F + 7] <= 8'h00;
 upper[8*8'h10 + 0] <= 8'h38;
 upper[8*8'h10 + 1] <= 8'h44;
 upper[8*8'h10 + 2] <= 8'h4C;
 upper[8*8'h10 + 3] <= 8'h54;
 upper[8*8'h10 + 4] <= 8'h64;
 upper[8*8'h10 + 5] <= 8'h44;
 upper[8*8'h10 + 6] <= 8'h38;
 upper[8*8'h10 + 7] <= 8'h00;
 upper[8*8'h11 + 0] <= 8'h10;
 upper[8*8'h11 + 1] <= 8'h30;
 upper[8*8'h11 + 2] <= 8'h10;
 upper[8*8'h11 + 3] <= 8'h10;
 upper[8*8'h11 + 4] <= 8'h10;
 upper[8*8'h11 + 5] <= 8'h10;
 upper[8*8'h11 + 6] <= 8'h38;
 upper[8*8'h11 + 7] <= 8'h00;
 upper[8*8'h12 + 0] <= 8'h38;
 upper[8*8'h12 + 1] <= 8'h44;
 upper[8*8'h12 + 2] <= 8'h04;
 upper[8*8'h12 + 3] <= 8'h08;
 upper[8*8'h12 + 4] <= 8'h10;
 upper[8*8'h12 + 5] <= 8'h20;
 upper[8*8'h12 + 6] <= 8'h7C;
 upper[8*8'h12 + 7] <= 8'h00;
 upper[8*8'h13 + 0] <= 8'h38;
 upper[8*8'h13 + 1] <= 8'h44;
 upper[8*8'h13 + 2] <= 8'h04;
 upper[8*8'h13 + 3] <= 8'h18;
 upper[8*8'h13 + 4] <= 8'h04;
 upper[8*8'h13 + 5] <= 8'h44;
 upper[8*8'h13 + 6] <= 8'h38;
 upper[8*8'h13 + 7] <= 8'h00;
 upper[8*8'h14 + 0] <= 8'h08;
 upper[8*8'h14 + 1] <= 8'h18;
 upper[8*8'h14 + 2] <= 8'h28;
 upper[8*8'h14 + 3] <= 8'h48;
 upper[8*8'h14 + 4] <= 8'h7C;
 upper[8*8'h14 + 5] <= 8'h08;
 upper[8*8'h14 + 6] <= 8'h08;
 upper[8*8'h14 + 7] <= 8'h00;
 upper[8*8'h15 + 0] <= 8'h7C;
 upper[8*8'h15 + 1] <= 8'h40;
 upper[8*8'h15 + 2] <= 8'h78;
 upper[8*8'h15 + 3] <= 8'h44;
 upper[8*8'h15 + 4] <= 8'h04;
 upper[8*8'h15 + 5] <= 8'h44;
 upper[8*8'h15 + 6] <= 8'h38;
 upper[8*8'h15 + 7] <= 8'h00;
 upper[8*8'h16 + 0] <= 8'h18;
 upper[8*8'h16 + 1] <= 8'h20;
 upper[8*8'h16 + 2] <= 8'h40;
 upper[8*8'h16 + 3] <= 8'h78;
 upper[8*8'h16 + 4] <= 8'h44;
 upper[8*8'h16 + 5] <= 8'h44;
 upper[8*8'h16 + 6] <= 8'h38;
 upper[8*8'h16 + 7] <= 8'h00;
 upper[8*8'h17 + 0] <= 8'h7C;
 upper[8*8'h17 + 1] <= 8'h44;
 upper[8*8'h17 + 2] <= 8'h08;
 upper[8*8'h17 + 3] <= 8'h10;
 upper[8*8'h17 + 4] <= 8'h20;
 upper[8*8'h17 + 5] <= 8'h20;
 upper[8*8'h17 + 6] <= 8'h20;
 upper[8*8'h17 + 7] <= 8'h00;
 upper[8*8'h18 + 0] <= 8'h38;
 upper[8*8'h18 + 1] <= 8'h44;
 upper[8*8'h18 + 2] <= 8'h44;
 upper[8*8'h18 + 3] <= 8'h38;
 upper[8*8'h18 + 4] <= 8'h44;
 upper[8*8'h18 + 5] <= 8'h44;
 upper[8*8'h18 + 6] <= 8'h38;
 upper[8*8'h18 + 7] <= 8'h00;
 upper[8*8'h19 + 0] <= 8'h38;
 upper[8*8'h19 + 1] <= 8'h44;
 upper[8*8'h19 + 2] <= 8'h44;
 upper[8*8'h19 + 3] <= 8'h3C;
 upper[8*8'h19 + 4] <= 8'h04;
 upper[8*8'h19 + 5] <= 8'h08;
 upper[8*8'h19 + 6] <= 8'h30;
 upper[8*8'h19 + 7] <= 8'h00;
 upper[8*8'h1A + 0] <= 8'h00;
 upper[8*8'h1A + 1] <= 8'h00;
 upper[8*8'h1A + 2] <= 8'h18;
 upper[8*8'h1A + 3] <= 8'h18;
 upper[8*8'h1A + 4] <= 8'h00;
 upper[8*8'h1A + 5] <= 8'h18;
 upper[8*8'h1A + 6] <= 8'h18;
 upper[8*8'h1A + 7] <= 8'h00;
 upper[8*8'h1B + 0] <= 8'h00;
 upper[8*8'h1B + 1] <= 8'h00;
 upper[8*8'h1B + 2] <= 8'h18;
 upper[8*8'h1B + 3] <= 8'h18;
 upper[8*8'h1B + 4] <= 8'h00;
 upper[8*8'h1B + 5] <= 8'h18;
 upper[8*8'h1B + 6] <= 8'h18;
 upper[8*8'h1B + 7] <= 8'h20;
 upper[8*8'h1C + 0] <= 8'h00;
 upper[8*8'h1C + 1] <= 8'h00;
 upper[8*8'h1C + 2] <= 8'h08;
 upper[8*8'h1C + 3] <= 8'h10;
 upper[8*8'h1C + 4] <= 8'h20;
 upper[8*8'h1C + 5] <= 8'h10;
 upper[8*8'h1C + 6] <= 8'h08;
 upper[8*8'h1C + 7] <= 8'h00;
 upper[8*8'h1D + 0] <= 8'h00;
 upper[8*8'h1D + 1] <= 8'h00;
 upper[8*8'h1D + 2] <= 8'h00;
 upper[8*8'h1D + 3] <= 8'h7C;
 upper[8*8'h1D + 4] <= 8'h00;
 upper[8*8'h1D + 5] <= 8'h7C;
 upper[8*8'h1D + 6] <= 8'h00;
 upper[8*8'h1D + 7] <= 8'h00;
 upper[8*8'h1E + 0] <= 8'h00;
 upper[8*8'h1E + 1] <= 8'h00;
 upper[8*8'h1E + 2] <= 8'h20;
 upper[8*8'h1E + 3] <= 8'h10;
 upper[8*8'h1E + 4] <= 8'h08;
 upper[8*8'h1E + 5] <= 8'h10;
 upper[8*8'h1E + 6] <= 8'h20;
 upper[8*8'h1E + 7] <= 8'h00;
 upper[8*8'h1F + 0] <= 8'h30;
 upper[8*8'h1F + 1] <= 8'h48;
 upper[8*8'h1F + 2] <= 8'h08;
 upper[8*8'h1F + 3] <= 8'h30;
 upper[8*8'h1F + 4] <= 8'h20;
 upper[8*8'h1F + 5] <= 8'h00;
 upper[8*8'h1F + 6] <= 8'h20;
 upper[8*8'h1F + 7] <= 8'h00;
 upper[8*8'h20 + 0] <= 8'h1C;
 upper[8*8'h20 + 1] <= 8'h22;
 upper[8*8'h20 + 2] <= 8'h4E;
 upper[8*8'h20 + 3] <= 8'h54;
 upper[8*8'h20 + 4] <= 8'h4C;
 upper[8*8'h20 + 5] <= 8'h20;
 upper[8*8'h20 + 6] <= 8'h1C;
 upper[8*8'h20 + 7] <= 8'h00;
 upper[8*8'h21 + 0] <= 8'h10;
 upper[8*8'h21 + 1] <= 8'h28;
 upper[8*8'h21 + 2] <= 8'h44;
 upper[8*8'h21 + 3] <= 8'h7C;
 upper[8*8'h21 + 4] <= 8'h44;
 upper[8*8'h21 + 5] <= 8'h44;
 upper[8*8'h21 + 6] <= 8'h44;
 upper[8*8'h21 + 7] <= 8'h00;
 upper[8*8'h22 + 0] <= 8'h78;
 upper[8*8'h22 + 1] <= 8'h24;
 upper[8*8'h22 + 2] <= 8'h24;
 upper[8*8'h22 + 3] <= 8'h38;
 upper[8*8'h22 + 4] <= 8'h24;
 upper[8*8'h22 + 5] <= 8'h24;
 upper[8*8'h22 + 6] <= 8'h78;
 upper[8*8'h22 + 7] <= 8'h00;
 upper[8*8'h23 + 0] <= 8'h38;
 upper[8*8'h23 + 1] <= 8'h44;
 upper[8*8'h23 + 2] <= 8'h40;
 upper[8*8'h23 + 3] <= 8'h40;
 upper[8*8'h23 + 4] <= 8'h40;
 upper[8*8'h23 + 5] <= 8'h44;
 upper[8*8'h23 + 6] <= 8'h38;
 upper[8*8'h23 + 7] <= 8'h00;
 upper[8*8'h24 + 0] <= 8'h78;
 upper[8*8'h24 + 1] <= 8'h24;
 upper[8*8'h24 + 2] <= 8'h24;
 upper[8*8'h24 + 3] <= 8'h24;
 upper[8*8'h24 + 4] <= 8'h24;
 upper[8*8'h24 + 5] <= 8'h24;
 upper[8*8'h24 + 6] <= 8'h78;
 upper[8*8'h24 + 7] <= 8'h00;
 upper[8*8'h25 + 0] <= 8'h7C;
 upper[8*8'h25 + 1] <= 8'h40;
 upper[8*8'h25 + 2] <= 8'h40;
 upper[8*8'h25 + 3] <= 8'h78;
 upper[8*8'h25 + 4] <= 8'h40;
 upper[8*8'h25 + 5] <= 8'h40;
 upper[8*8'h25 + 6] <= 8'h7C;
 upper[8*8'h25 + 7] <= 8'h00;
 upper[8*8'h26 + 0] <= 8'h7C;
 upper[8*8'h26 + 1] <= 8'h40;
 upper[8*8'h26 + 2] <= 8'h40;
 upper[8*8'h26 + 3] <= 8'h78;
 upper[8*8'h26 + 4] <= 8'h40;
 upper[8*8'h26 + 5] <= 8'h40;
 upper[8*8'h26 + 6] <= 8'h40;
 upper[8*8'h26 + 7] <= 8'h00;
 upper[8*8'h27 + 0] <= 8'h38;
 upper[8*8'h27 + 1] <= 8'h44;
 upper[8*8'h27 + 2] <= 8'h40;
 upper[8*8'h27 + 3] <= 8'h5C;
 upper[8*8'h27 + 4] <= 8'h44;
 upper[8*8'h27 + 5] <= 8'h44;
 upper[8*8'h27 + 6] <= 8'h38;
 upper[8*8'h27 + 7] <= 8'h00;
 upper[8*8'h28 + 0] <= 8'h44;
 upper[8*8'h28 + 1] <= 8'h44;
 upper[8*8'h28 + 2] <= 8'h44;
 upper[8*8'h28 + 3] <= 8'h7C;
 upper[8*8'h28 + 4] <= 8'h44;
 upper[8*8'h28 + 5] <= 8'h44;
 upper[8*8'h28 + 6] <= 8'h44;
 upper[8*8'h28 + 7] <= 8'h00;
 upper[8*8'h29 + 0] <= 8'h38;
 upper[8*8'h29 + 1] <= 8'h10;
 upper[8*8'h29 + 2] <= 8'h10;
 upper[8*8'h29 + 3] <= 8'h10;
 upper[8*8'h29 + 4] <= 8'h10;
 upper[8*8'h29 + 5] <= 8'h10;
 upper[8*8'h29 + 6] <= 8'h38;
 upper[8*8'h29 + 7] <= 8'h00;
 upper[8*8'h2A + 0] <= 8'h1C;
 upper[8*8'h2A + 1] <= 8'h08;
 upper[8*8'h2A + 2] <= 8'h08;
 upper[8*8'h2A + 3] <= 8'h08;
 upper[8*8'h2A + 4] <= 8'h08;
 upper[8*8'h2A + 5] <= 8'h48;
 upper[8*8'h2A + 6] <= 8'h30;
 upper[8*8'h2A + 7] <= 8'h00;
 upper[8*8'h2B + 0] <= 8'h44;
 upper[8*8'h2B + 1] <= 8'h48;
 upper[8*8'h2B + 2] <= 8'h50;
 upper[8*8'h2B + 3] <= 8'h60;
 upper[8*8'h2B + 4] <= 8'h50;
 upper[8*8'h2B + 5] <= 8'h48;
 upper[8*8'h2B + 6] <= 8'h44;
 upper[8*8'h2B + 7] <= 8'h00;
 upper[8*8'h2C + 0] <= 8'h40;
 upper[8*8'h2C + 1] <= 8'h40;
 upper[8*8'h2C + 2] <= 8'h40;
 upper[8*8'h2C + 3] <= 8'h40;
 upper[8*8'h2C + 4] <= 8'h40;
 upper[8*8'h2C + 5] <= 8'h40;
 upper[8*8'h2C + 6] <= 8'h7C;
 upper[8*8'h2C + 7] <= 8'h00;
 upper[8*8'h2D + 0] <= 8'h44;
 upper[8*8'h2D + 1] <= 8'h6C;
 upper[8*8'h2D + 2] <= 8'h54;
 upper[8*8'h2D + 3] <= 8'h54;
 upper[8*8'h2D + 4] <= 8'h44;
 upper[8*8'h2D + 5] <= 8'h44;
 upper[8*8'h2D + 6] <= 8'h44;
 upper[8*8'h2D + 7] <= 8'h00;
 upper[8*8'h2E + 0] <= 8'h44;
 upper[8*8'h2E + 1] <= 8'h44;
 upper[8*8'h2E + 2] <= 8'h64;
 upper[8*8'h2E + 3] <= 8'h54;
 upper[8*8'h2E + 4] <= 8'h4C;
 upper[8*8'h2E + 5] <= 8'h44;
 upper[8*8'h2E + 6] <= 8'h44;
 upper[8*8'h2E + 7] <= 8'h00;
 upper[8*8'h2F + 0] <= 8'h10;
 upper[8*8'h2F + 1] <= 8'h28;
 upper[8*8'h2F + 2] <= 8'h44;
 upper[8*8'h2F + 3] <= 8'h44;
 upper[8*8'h2F + 4] <= 8'h44;
 upper[8*8'h2F + 5] <= 8'h28;
 upper[8*8'h2F + 6] <= 8'h10;
 upper[8*8'h2F + 7] <= 8'h00;
 upper[8*8'h30 + 0] <= 8'h78;
 upper[8*8'h30 + 1] <= 8'h44;
 upper[8*8'h30 + 2] <= 8'h44;
 upper[8*8'h30 + 3] <= 8'h78;
 upper[8*8'h30 + 4] <= 8'h40;
 upper[8*8'h30 + 5] <= 8'h40;
 upper[8*8'h30 + 6] <= 8'h40;
 upper[8*8'h30 + 7] <= 8'h00;
 upper[8*8'h31 + 0] <= 8'h38;
 upper[8*8'h31 + 1] <= 8'h44;
 upper[8*8'h31 + 2] <= 8'h44;
 upper[8*8'h31 + 3] <= 8'h44;
 upper[8*8'h31 + 4] <= 8'h44;
 upper[8*8'h31 + 5] <= 8'h4C;
 upper[8*8'h31 + 6] <= 8'h3C;
 upper[8*8'h31 + 7] <= 8'h00;
 upper[8*8'h32 + 0] <= 8'h78;
 upper[8*8'h32 + 1] <= 8'h44;
 upper[8*8'h32 + 2] <= 8'h44;
 upper[8*8'h32 + 3] <= 8'h78;
 upper[8*8'h32 + 4] <= 8'h50;
 upper[8*8'h32 + 5] <= 8'h48;
 upper[8*8'h32 + 6] <= 8'h44;
 upper[8*8'h32 + 7] <= 8'h00;
 upper[8*8'h33 + 0] <= 8'h38;
 upper[8*8'h33 + 1] <= 8'h44;
 upper[8*8'h33 + 2] <= 8'h40;
 upper[8*8'h33 + 3] <= 8'h38;
 upper[8*8'h33 + 4] <= 8'h04;
 upper[8*8'h33 + 5] <= 8'h44;
 upper[8*8'h33 + 6] <= 8'h38;
 upper[8*8'h33 + 7] <= 8'h00;
 upper[8*8'h34 + 0] <= 8'h7C;
 upper[8*8'h34 + 1] <= 8'h10;
 upper[8*8'h34 + 2] <= 8'h10;
 upper[8*8'h34 + 3] <= 8'h10;
 upper[8*8'h34 + 4] <= 8'h10;
 upper[8*8'h34 + 5] <= 8'h10;
 upper[8*8'h34 + 6] <= 8'h10;
 upper[8*8'h34 + 7] <= 8'h00;
 upper[8*8'h35 + 0] <= 8'h44;
 upper[8*8'h35 + 1] <= 8'h44;
 upper[8*8'h35 + 2] <= 8'h44;
 upper[8*8'h35 + 3] <= 8'h44;
 upper[8*8'h35 + 4] <= 8'h44;
 upper[8*8'h35 + 5] <= 8'h44;
 upper[8*8'h35 + 6] <= 8'h38;
 upper[8*8'h35 + 7] <= 8'h00;
 upper[8*8'h36 + 0] <= 8'h44;
 upper[8*8'h36 + 1] <= 8'h44;
 upper[8*8'h36 + 2] <= 8'h44;
 upper[8*8'h36 + 3] <= 8'h28;
 upper[8*8'h36 + 4] <= 8'h28;
 upper[8*8'h36 + 5] <= 8'h10;
 upper[8*8'h36 + 6] <= 8'h10;
 upper[8*8'h36 + 7] <= 8'h00;
 upper[8*8'h37 + 0] <= 8'h44;
 upper[8*8'h37 + 1] <= 8'h44;
 upper[8*8'h37 + 2] <= 8'h44;
 upper[8*8'h37 + 3] <= 8'h54;
 upper[8*8'h37 + 4] <= 8'h54;
 upper[8*8'h37 + 5] <= 8'h6C;
 upper[8*8'h37 + 6] <= 8'h44;
 upper[8*8'h37 + 7] <= 8'h00;
 upper[8*8'h38 + 0] <= 8'h44;
 upper[8*8'h38 + 1] <= 8'h44;
 upper[8*8'h38 + 2] <= 8'h28;
 upper[8*8'h38 + 3] <= 8'h10;
 upper[8*8'h38 + 4] <= 8'h28;
 upper[8*8'h38 + 5] <= 8'h44;
 upper[8*8'h38 + 6] <= 8'h44;
 upper[8*8'h38 + 7] <= 8'h00;
 upper[8*8'h39 + 0] <= 8'h44;
 upper[8*8'h39 + 1] <= 8'h44;
 upper[8*8'h39 + 2] <= 8'h28;
 upper[8*8'h39 + 3] <= 8'h10;
 upper[8*8'h39 + 4] <= 8'h10;
 upper[8*8'h39 + 5] <= 8'h10;
 upper[8*8'h39 + 6] <= 8'h10;
 upper[8*8'h39 + 7] <= 8'h00;
 upper[8*8'h3A + 0] <= 8'h7C;
 upper[8*8'h3A + 1] <= 8'h04;
 upper[8*8'h3A + 2] <= 8'h08;
 upper[8*8'h3A + 3] <= 8'h10;
 upper[8*8'h3A + 4] <= 8'h20;
 upper[8*8'h3A + 5] <= 8'h40;
 upper[8*8'h3A + 6] <= 8'h7C;
 upper[8*8'h3A + 7] <= 8'h00;
 upper[8*8'h3B + 0] <= 8'h38;
 upper[8*8'h3B + 1] <= 8'h20;
 upper[8*8'h3B + 2] <= 8'h20;
 upper[8*8'h3B + 3] <= 8'h20;
 upper[8*8'h3B + 4] <= 8'h20;
 upper[8*8'h3B + 5] <= 8'h20;
 upper[8*8'h3B + 6] <= 8'h38;
 upper[8*8'h3B + 7] <= 8'h00;
 upper[8*8'h3C + 0] <= 8'h00;
 upper[8*8'h3C + 1] <= 8'h40;
 upper[8*8'h3C + 2] <= 8'h20;
 upper[8*8'h3C + 3] <= 8'h10;
 upper[8*8'h3C + 4] <= 8'h08;
 upper[8*8'h3C + 5] <= 8'h04;
 upper[8*8'h3C + 6] <= 8'h00;
 upper[8*8'h3C + 7] <= 8'h00;
 upper[8*8'h3D + 0] <= 8'h1C;
 upper[8*8'h3D + 1] <= 8'h04;
 upper[8*8'h3D + 2] <= 8'h04;
 upper[8*8'h3D + 3] <= 8'h04;
 upper[8*8'h3D + 4] <= 8'h04;
 upper[8*8'h3D + 5] <= 8'h04;
 upper[8*8'h3D + 6] <= 8'h1C;
 upper[8*8'h3D + 7] <= 8'h00;
 upper[8*8'h3E + 0] <= 8'h10;
 upper[8*8'h3E + 1] <= 8'h38;
 upper[8*8'h3E + 2] <= 8'h54;
 upper[8*8'h3E + 3] <= 8'h10;
 upper[8*8'h3E + 4] <= 8'h10;
 upper[8*8'h3E + 5] <= 8'h10;
 upper[8*8'h3E + 6] <= 8'h10;
 upper[8*8'h3E + 7] <= 8'h00;
 upper[8*8'h3F + 0] <= 8'h00;
 upper[8*8'h3F + 1] <= 8'h00;
 upper[8*8'h3F + 2] <= 8'h00;
 upper[8*8'h3F + 3] <= 8'h00;
 upper[8*8'h3F + 4] <= 8'h00;
 upper[8*8'h3F + 5] <= 8'h00;
 upper[8*8'h3F + 6] <= 8'hFF;
 upper[8*8'h3F + 7] <= 8'hFF;
   end
`else

   RAMB16_S9 #(
      // The following INIT_xx declarations specify the initial contents of the RAM
      .INIT_00(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_01(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_02(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_03(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_04(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_05(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_06(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_07(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_08(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_09(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_0A(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_0B(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_0C(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_0D(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_0E(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_0F(256'h000000003E3E3E3E3E3E3E3E3E3E3E3E000000003E3E3E3E3E3E3E3E3E3E3E3E),
      .INIT_10(256'h0000000000000000001000101010101000000000000000000000000000000000),
      .INIT_11(256'h00000000000000000028287C287C282800000000000000000000000000002828),
      .INIT_12(256'h000000000000000000044A241008245200000000000000001078141C70503C10),
      .INIT_13(256'h0000000000000000000000000020181800000000000000000034485420504830),
      .INIT_14(256'h0000000000000000002010080808102000000000000000000008102020201008),
      .INIT_15(256'h00000000000000000010107C101000000000000000000000001054387C385410),
      .INIT_16(256'h00000000000000000000007C0000000000000000000000002018180000000000),
      .INIT_17(256'h0000000000000000004040201008040400000000000000001818000000000000),
      .INIT_18(256'h00000000000000000038101010103010000000000000000000384464544C4438),
      .INIT_19(256'h000000000000000000384404180444380000000000000000007C201008044438),
      .INIT_1A(256'h0000000000000000003844044478407C00000000000000000008087C48281808),
      .INIT_1B(256'h0000000000000000002020201008447C00000000000000000038444478402018),
      .INIT_1C(256'h0000000000000000003008043C44443800000000000000000038444438444438),
      .INIT_1D(256'h0000000000000000201818001818000000000000000000000018180018180000),
      .INIT_1E(256'h000000000000000000007C007C00000000000000000000000008102010080000),
      .INIT_1F(256'h0000000000000000002000203008483000000000000000000020100810200000),
      .INIT_20(256'h0000000000000000004444447C4428100000000000000000001C204C544E221C),
      .INIT_21(256'h0000000000000000003844404040443800000000000000000078242438242478),
      .INIT_22(256'h0000000000000000007C40407840407C00000000000000000078242424242478),
      .INIT_23(256'h0000000000000000003844445C4044380000000000000000004040407840407C),
      .INIT_24(256'h000000000000000000381010101010380000000000000000004444447C444444),
      .INIT_25(256'h000000000000000000444850605048440000000000000000003048080808081C),
      .INIT_26(256'h00000000000000000044444454546C440000000000000000007C404040404040),
      .INIT_27(256'h0000000000000000001028444444281000000000000000000044444C54644444),
      .INIT_28(256'h0000000000000000003C4C444444443800000000000000000040404078444478),
      .INIT_29(256'h0000000000000000003844043840443800000000000000000044485078444478),
      .INIT_2A(256'h000000000000000000384444444444440000000000000000001010101010107C),
      .INIT_2B(256'h000000000000000000446C545444444400000000000000000010102828444444),
      .INIT_2C(256'h0000000000000000001010101028444400000000000000000044442810284444),
      .INIT_2D(256'h000000000000000000382020202020380000000000000000007C40201008047C),
      .INIT_2E(256'h0000000000000000001C04040404041C00000000000000000000040810204000),
      .INIT_2F(256'h0000000000000000FFFF00000000000000000000000000000010101010543810),
      .INIT_30(256'h000000000000003A443C04083000000000000000000000000000000810200000),
      .INIT_31(256'h0000000000000038444044380000000000000000000000986444645840400000),
      .INIT_32(256'h0000000000000038407844380000000000000000000000324C444C3404040000),
      .INIT_33(256'h00000000384404344C4444380000000000000000000000202020207024180000),
      .INIT_34(256'h0000000000000038101010300010000000000000000000444444645840400000),
      .INIT_35(256'h0000000000000044487048444040000000000000003048080808081800080000),
      .INIT_36(256'h0000000000000054545454380000000000000000000000381010101010300000),
      .INIT_37(256'h0000000000000038444444380000000000000000000000444444645800000000),
      .INIT_38(256'h00000000040604344C444C340000000000000000404040586444649800000000),
      .INIT_39(256'h0000000000000038043840380000000000000000000000404040645800000000),
      .INIT_3A(256'h00000000000000344C44444400000000000000000000000C1210103810100000),
      .INIT_3B(256'h0000000000000038545454440000000000000000000000102844444400000000),
      .INIT_3C(256'h0000000038440434444444440000000000000000000000442810284400000000),
      .INIT_3D(256'h000000000000000C10106010100C0000000000000000007C2010087C00000000),
      .INIT_3E(256'h000000000000006010100C101060000000000000000000101010001010100000),
      .INIT_3F(256'h00000000000000007C7C7C7C000000000000000000000000000002027E000000)
     ) RAMB16_S1_inst_0 (
      .CLK(clk),      // Port A Clock
      .DO(pixels_out), // Port A 8-bit Data Output
      .ADDR({ascii[6:0],row}),    // Port A 11-bit Address Input
      .DI(8'b0),  // Port A 8-bit Data Input
      .EN(1'b1),        // Port A RAM Enable Input
      .SSR(1'b0),      // Port A Synchronous Set/Reset Input
      .WE(1'b0),        // Port A Write Enable Input
      .DIP(1'b0),
      .DOP()
   );

`endif
endmodule /* chargen_7x5_rachel */

`ifdef rachel_tb
`timescale 1ns/1ps

module tb();

   reg   clk;
   reg [7:0] init;
   
   reg [11:0] addr;
   wire [7:0] pixels_out;
   reg 	[7:0] contents[0:4095];

chargen_7x5_rachel rom1(.clk(clk), .ascii(addr[11:4]), .row(addr[3:0]), .pixels_out(pixels_out));

   integer  i, last;

   initial
      begin
	 clk = 0;
	 addr = 0;
	 for (i = 0; i < 4096; i=i+1)
	    begin
	       #1000 clk = 1;
	       #1000 clk = 0;
//	       $display("%X", pixels_out);
	       contents[addr] = pixels_out;
	       addr = addr + 1;
	    end;
	 for (init = 0; init < 64; init=init+1)
	   begin
	      $write("      .INIT_%X(256'h", init);
	      for (i = 31; i >= 0; i=i-1)
		$write("%X", contents[i + {init,5'b0}]);
	      if (init == 63) $display(")"); else $display("),");
	      end
      end
   
endmodule // tb

`endif
`ifdef graphic_tb
`timescale 1ns/1ps

module tb();

   reg   clk;
   reg [7:0] init;
   
   reg [11:0] addr;
   wire [7:0] pixels_out;

chargen_7x5_rachel rom1(.clk(clk), .ascii(addr[11:4]), .row(addr[3:0]), .pixels_out(pixels_out));

   integer  i, j;

   initial
      begin
	 clk = 0;
	 addr = 0;
	 for (i = 0; i < 4096; i=i+1)
	    begin
	       #1000 clk = 1;
	       #1000 clk = 0;
	       if (!addr[3:0])
		 $display("\n%d", addr[11:4]);
	       else if (addr[3:0]<12)
		 begin
		    for (j = 7; j >= 0; j=j-1)
		      $write("%c", pixels_out & (1<<j) ? "*":" ");
		    $display;
		 end
	       addr = addr + 1;
	    end;
      end
   
endmodule

`endif
   
// eof


