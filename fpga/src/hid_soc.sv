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

module hid_soc
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
`endif
  //keyboard
    inout wire         PS2_CLK     ,
    inout wire         PS2_DATA    ,
  // display
    output wire        VGA_HS_O    ,
    output wire        VGA_VS_O    ,
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
 
 wire        scan_ready, scan_released;
 wire [7:0]  scan_code, fstore_data;
 wire        keyb_empty, tx_error_no_keyboard_ack;   
 reg [31:0]  keycode;
 reg scan_ready_dly;
 wire [8:0] keyb_fifo_out;
 // signals from/to core
logic [7:0] one_hot_data_addr, one_hot_data_addr_dly;
logic [63:0] doutg, one_hot_rdata[7:0];
logic haddr19;

    ps2 keyb_mouse(
      .clk(clk_i),
      .rst(~rst_ni),
      .PS2_K_CLK_IO(PS2_CLK),
      .PS2_K_DATA_IO(PS2_DATA),
      .PS2_M_CLK_IO(),
      .PS2_M_DATA_IO(),
      .rx_released(scan_released),
      .rx_scan_ready(scan_ready),
      .rx_scan_code(scan_code),
      .rx_scan_read(scan_ready),
      .tx_error_no_keyboard_ack(tx_error_no_keyboard_ack));
 
 always @(negedge clk_i)
    begin
        scan_ready_dly <= scan_ready;
    end
       
FIFO18E1 #(
      .ALMOST_EMPTY_OFFSET(13'h0080),    // Sets the almost empty threshold
      .ALMOST_FULL_OFFSET(13'h0080),     // Sets almost full threshold
      .DATA_WIDTH(9),                    // Sets data width to 4-36
      .DO_REG(0),                        // Enable output register (1-0) Must be 1 if EN_SYN = FALSE
      .EN_SYN("TRUE"),                   // Specifies FIFO as dual-clock (FALSE) or Synchronous (TRUE)
      .FIFO_MODE("FIFO18"),              // Sets mode to FIFO18 or FIFO18_36
      .FIRST_WORD_FALL_THROUGH("FALSE"), // Sets the FIFO FWFT to FALSE, TRUE
      .INIT(36'h000000000),              // Initial values on output port
      .SIM_DEVICE("7SERIES"),            // Must be set to "7SERIES" for simulation behavior
      .SRVAL(36'h000000000)              // Set/Reset value for output port
      )
      FIFO18E1_inst_18 (
                        // Read Data: 32-bit (each) output: Read output data
                        .DO(keyb_fifo_out[7:0]),   // 32-bit output: Data output
                        .DOP(keyb_fifo_out[8]),    // 4-bit output: Parity data output
                        // Status: 1-bit (each) output: Flags and other FIFO status outputs
                        .ALMOSTEMPTY(),            // 1-bit output: Almost empty flag
                        .ALMOSTFULL(),             // 1-bit output: Almost full flag
                        .EMPTY(keyb_empty),        // 1-bit output: Empty flag
                        .FULL(),                   // 1-bit output: Full flag
                        .RDCOUNT(),                // 12-bit output: Read count
                        .RDERR(),                  // 1-bit output: Read error
                        .WRCOUNT(),                // 12-bit output: Write count
                        .WRERR(),                  // 1-bit output: Write error
                        // Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
                        .RDCLK(~clk_i),         // 1-bit input: Read clock
                        .RDEN(hid_en&(|hid_we)&one_hot_data_addr[6]&~hid_addr[14]), // 1-bit input: Read enable
                        .REGCE(1'b1),              // 1-bit input: Clock enable
                        .RST(~rst_ni),               // 1-bit input: Asynchronous Reset
                        .RSTREG(1'b0),             // 1-bit input: Output register set/reset
                        // Write Control Signals: 1-bit (each) input: Write clock and enable input signals
                        .WRCLK(~clk_i),         // 1-bit input: Write clock
                        .WREN(scan_ready & ~scan_ready_dly),               // 1-bit input: Write enable
                        // Write Data: 32-bit (each) input: Write input data
                        .DI(scan_code),                   // 32-bit input: Data input
                        .DIP(scan_released)                  // 4-bit input: Parity input
                        );
  
    wire [7:0] red,  green, blue;
 
    fstore2 the_fstore(
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
