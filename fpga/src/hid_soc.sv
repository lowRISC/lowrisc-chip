// Copyright 2015 ETH Zurich, University of Bologna, and University of Cambridge
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
// See LICENSE for license details.

`default_nettype none

module hid_soc #(
   parameter graphmax = 20,
   parameter UBAUD_DEFAULT=54
)
(
`ifdef GENESYSII
    // display
    output wire [4:0]  VGA_RED_O,
    output wire [4:0]  VGA_BLUE_O,
    output wire [5:0]  VGA_GREEN_O,
`elsif NEXYS4DDR
    output wire   [3:0] VGA_RED_O   ,
    output wire   [3:0] VGA_BLUE_O  ,
    output wire   [3:0] VGA_GREEN_O ,
   output wire        CA,
   output wire        CB,
   output wire        CC,
   output wire        CD,
   output wire        CE,
   output wire        CF,
   output wire        CG,
   output wire        DP,
   output wire [7:0]  AN,
`endif
  // keyboard
    inout wire         PS2_CLK,
    inout wire         PS2_DATA,
  // display
    output wire        VGA_HS_O,
    output wire        VGA_VS_O,
 // clock and reset
 input wire         pxl_clk,
 input wire         clk_i,
 input wire         rst_ni,
 input wire         hid_en,
 input wire [7:0]   hid_we,
 input wire [19:0]  hid_addr,
 input wire [63:0]  hid_wrdata,
 output reg [63:0]  hid_rddata
 );
 
 wire        keyb_scan_ready, keyb_scan_released;
 wire [7:0]  keyb_scan_code, fstore_data;
 wire        keyb_empty, tx_error_no_keyboard_ack;
 reg [31:0]  keycode;
 reg keyb_scan_ready_dly, rx_mouse_data_ready_dly;
 wire [8:0] keyb_fifo_out;
 // signals from/to core
logic [7:0] one_hot_data_addr, one_hot_data_addr_dly;
logic [63:0] doutg, one_hot_rdata[7:0];
logic haddr13, haddr19;
logic [7:0] rx_scan_code, rx_mouse_data;
   
    ps2 keyb_mouse(
      .clk(clk_i),
      .rst(~rst_ni),
      .PS2_K_CLK_IO(PS2_CLK),
      .PS2_K_DATA_IO(PS2_DATA),
      .PS2_M_CLK_IO(),
      .PS2_M_DATA_IO(),
      .rx_released(keyb_scan_released),
      .rx_scan_ready(keyb_scan_ready),
      .rx_scan_code(keyb_scan_code),
      .rx_scan_read(keyb_scan_ready),
      .tx_error_no_keyboard_ack);
 
 always @(negedge clk_i)
    begin
        keyb_scan_ready_dly <= keyb_scan_ready;
    end

xlnx_char_fifo fifo_keyboard (
  .clk(~clk_i),      // input wire clk
  .srst(~rst_ni),    // input wire srst
  .din({keyb_scan_released,keyb_scan_code}),      // input wire [8 : 0] din
  .wr_en(keyb_scan_ready & ~keyb_scan_ready_dly),  // input wire wr_en
  .rd_en(hid_en&(|hid_we)&one_hot_data_addr[6]&~hid_addr[14]),  // input wire rd_en
  .dout(keyb_fifo_out[8:0]),    // output wire [8 : 0] dout
  .full(),    // output wire full
  .empty(keyb_empty)  // output wire empty
);
   
//
// Frame store
//   
    wire [7:0] red, green, blue;
 
    fstore2 #(.graphmax(graphmax)) the_fstore(
      .pxl_clk,
      .vsyn(VGA_VS_O),
      .hsyn(VGA_HS_O),
      .red,
      .green,
      .blue,
      .hid_en,
      .hid_we,
      .one_hot_data_addr,
      .hid_addr,
      .hid_wrdata,
      .doutb(one_hot_rdata[7]),
      .doutg(doutg),
      .rst_ni,
      .clk_i
     );

`ifdef GENESYSII   
 assign VGA_RED_O = red[7:3];
 assign VGA_GREEN_O = green[7:2];
 assign VGA_BLUE_O = blue[7:3];
`elsif NEXYS4DDR
 assign VGA_RED_O = red[7:5];
 assign VGA_GREEN_O = green[7:5];
 assign VGA_BLUE_O = blue[7:5];
`endif

   assign one_hot_rdata[6] = {tx_error_no_keyboard_ack,keyb_empty,keyb_fifo_out[8:0]};
   
//----------------------------------------------------------------------------//

   always @(posedge clk_i)
     begin
        haddr19 <= hid_addr[19];
        haddr13 <= hid_addr[13];
	one_hot_data_addr_dly <= one_hot_data_addr;
     end
   
always_comb
  begin:onehot
     integer i;
     hid_rddata = haddr19 ? doutg : 64'b0;
     for (i = 0; i < 8; i++)
       begin
	   one_hot_data_addr[i] = hid_addr[19:15] == i;
	   hid_rddata |= (one_hot_data_addr_dly[i] ? one_hot_rdata[i] : 64'b0);
       end
  end
   
endmodule // chip_top
`default_nettype wire
