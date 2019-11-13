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
  // Bluetooth mouse module
    output wire        uart_tx,
    output wire        uart_irq,
    output wire        uart_cts,
    input wire         uart_rts,
    input wire         uart_rx,
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

// Bluetooth HID interface UART

   reg         u_trans, u_recv, uart_rx_full, uart_rx_empty, uart_tx_empty, uart_tx_full;   
   reg [15:0]  u_baud;
   wire        received, recv_err, is_recv, is_trans, uart_maj;
   wire [11:0] uart_rx_wrcount, uart_rx_rdcount, uart_tx_wrcount, uart_tx_rdcount;
   wire [8:0]  uart_rx_fifo_data_out, uart_tx_fifo_data_out;
   reg [7:0]   u_rx_byte, u_tx_byte;

   assign uart_irq = ~uart_rx_empty;
   assign uart_cts = uart_rx_full;
   
   assign one_hot_rdata[5] = haddr13 ?
                               {4'b0,uart_tx_wrcount,
                                4'b0,uart_tx_rdcount,
                                4'b0,uart_rx_wrcount,
                                4'b0,uart_rx_rdcount} : 
                             {4'b0,uart_rx_full,uart_tx_full,uart_rx_empty,uart_rx_fifo_data_out};

typedef enum {UTX_IDLE, UTX_EMPTY, UTX_INUSE, UTX_POP, UTX_START} utx_t;

   utx_t utxstate_d, utxstate_q;
   
always @(posedge clk_i)
    if (~rst_ni)
    begin
    u_baud = UBAUD_DEFAULT;
    u_recv = 0;
    u_trans = 0;
    u_tx_byte = 0;
    utxstate_q = UTX_IDLE;
    end
  else
    begin
    u_recv = 0;
    u_trans = 0;
    utxstate_q = utxstate_d;
    if (hid_en & (|hid_we) & one_hot_data_addr[5] & hid_addr[14])
        casez (hid_addr[13:12])
         2'b00: begin u_trans = 1; u_tx_byte = hid_wrdata[7:0]; end
         2'b01: begin u_recv = 1; end
         2'b10: begin u_baud = hid_wrdata; end
         2'b11: begin end
        endcase
    end // else: !if(~rst_ni)

always @*
  begin
     utxstate_d = utxstate_q;
     casez(utxstate_q)
       UTX_IDLE:
         utxstate_d = UTX_EMPTY;
       UTX_EMPTY:
         if ((~uart_rts) && (~uart_tx_empty))
           utxstate_d = UTX_POP;
       UTX_INUSE:
         if (~is_trans)
           utxstate_d = UTX_IDLE;
       UTX_POP:
         utxstate_d = UTX_START;
       UTX_START:
         utxstate_d = UTX_INUSE;
       default:;
     endcase
  end
   
//----------------------------------------------------------------------------//
rx_delay uart_rx_dly(
.clk(clk_i),
.in(uart_rx),		     
.maj(uart_maj));
// Core Instantiation
uart i_uart(
    .clk(clk_i), // The master clock for this module
    .rst(~rst_ni), // Synchronous reset.
    .rx(uart_maj), // Incoming serial line
    .tx(uart_tx), // Outgoing serial line
    .transmit(utxstate_q==UTX_START), // Signal to transmit
    .tx_byte(uart_tx_fifo_data_out[7:0]), // Byte to transmit
    .received(received), // Indicated that a byte has been received.
    .rx_byte(u_rx_byte), // Byte received
    .is_receiving(is_recv), // Low when receive line is idle.
    .is_transmitting(is_trans), // Low when transmit line is idle.
    .recv_error(recv_err), // Indicates error in receiving packet.
    .baud(u_baud),
    .recv_ack(received)
    );

 my_fifo #(.width(9)) uart_rx_fifo (
       .clk(clk_i),      // input wire read clk
       .rst(~rst_ni),      // input wire rst
       .din({recv_err,u_rx_byte}),      // input wire [8 : 0] din
       .wr_en(received),  // input wire wr_en
       .rd_en(u_recv),  // input wire rd_en
       .dout(uart_rx_fifo_data_out),    // output wire [8 : 0] dout
       .rdcount(uart_rx_rdcount),         // 12-bit output: Read count
       .wrcount(uart_rx_wrcount),         // 12-bit output: Write count
       .full(uart_rx_full),    // output wire full
       .empty(uart_rx_empty)  // output wire empty
     );

 my_fifo #(.width(9)) uart_tx_fifo (
       .clk(clk_i),      // input wire read clk
       .rst(~rst_ni),      // input wire rst
       .din({1'b0,u_tx_byte}),      // input wire [8 : 0] din
       .wr_en(u_trans),  // input wire wr_en
       .rd_en(utxstate_q==UTX_POP),  // input wire rd_en
       .dout(uart_tx_fifo_data_out),    // output wire [8 : 0] dout
       .rdcount(uart_tx_rdcount),         // 12-bit output: Read count
       .wrcount(uart_tx_wrcount),         // 12-bit output: Write count
       .full(uart_tx_full),    // output wire full
       .empty(uart_tx_empty)  // output wire empty
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
