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
    inout wire         PS2_CLK     ,
    inout wire         PS2_DATA    ,
  // mouse
    inout wire         PS2_MCLK    ,
    inout wire         PS2_MDATA   ,
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
 
 wire        keyb_scan_ready, keyb_scan_released;
 wire [7:0]  keyb_scan_code, fstore_data;
 wire        keyb_empty, tx_error_no_keyboard_ack;
 reg [31:0]  keycode;
 reg keyb_scan_ready_dly, rx_mouse_data_ready_dly;
 wire [8:0] keyb_fifo_out;
 // signals from/to core
logic [7:0] one_hot_data_addr, one_hot_data_addr_dly;
logic [63:0] doutg, one_hot_rdata[7:0];
logic haddr19;
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
      FIFO18E1_inst_keyboard (
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
                        .WREN(keyb_scan_ready & ~keyb_scan_ready_dly),               // 1-bit input: Write enable
                        // Write Data: 32-bit (each) input: Write input data
                        .DI(keyb_scan_code),                   // 32-bit input: Data input
                        .DIP(keyb_scan_released)                  // 4-bit input: Parity input
                        );

// =======================================================================================
// 							  	      Mouse Implementation
// =======================================================================================

wire [9:0]   X, Y;
wire [3:0]   Z;

wire [8*7-1:0] digits;
wire           left, middle, right, new_event, mouse_empty;
logic [31:0] mouse_scan_code_dly, mouse_fifo_out;
wire [31:0] mouse_scan_code = {left, middle, right, new_event, Z,2'b0,Y,2'b0,X};
wire rst = (hid_en&(&hid_we)&one_hot_data_addr[5]&hid_addr[14]) || ~rst_ni;
   
assign one_hot_rdata[5] = {mouse_empty,mouse_fifo_out};

always @(posedge clk_i)
     begin
	mouse_scan_code_dly <= mouse_scan_code;
     end

FIFO18E1 #(
      .ALMOST_EMPTY_OFFSET(13'h0080),    // Sets the almost empty threshold
      .ALMOST_FULL_OFFSET(13'h0080),     // Sets almost full threshold
      .DATA_WIDTH(36),                   // Sets data width to 4-36
      .DO_REG(0),                        // Enable output register (1-0) Must be 1 if EN_SYN = FALSE
      .EN_SYN("TRUE"),                   // Specifies FIFO as dual-clock (FALSE) or Synchronous (TRUE)
      .FIFO_MODE("FIFO18_36"),           // Sets mode to FIFO18 or FIFO18_36
      .FIRST_WORD_FALL_THROUGH("FALSE"), // Sets the FIFO FWFT to FALSE, TRUE
      .INIT(36'h000000000),              // Initial values on output port
      .SIM_DEVICE("7SERIES"),            // Must be set to "7SERIES" for simulation behavior
      .SRVAL(36'h000000000)              // Set/Reset value for output port
      )
      FIFO18E1_inst_mouse (
                        // Read Data: 32-bit (each) output: Read output data
                        .DO(mouse_fifo_out),       // 32-bit output: Data output
                        .DOP(),                    // 4-bit output: Parity data output
                        // Status: 1-bit (each) output: Flags and other FIFO status outputs
                        .ALMOSTEMPTY(),            // 1-bit output: Almost empty flag
                        .ALMOSTFULL(),             // 1-bit output: Almost full flag
                        .EMPTY(mouse_empty),       // 1-bit output: Empty flag
                        .FULL(),                   // 1-bit output: Full flag
                        .RDCOUNT(),                // 12-bit output: Read count
                        .RDERR(),                  // 1-bit output: Read error
                        .WRCOUNT(),                // 12-bit output: Write count
                        .WRERR(),                  // 1-bit output: Write error
                        // Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
                        .RDCLK(~clk_i),         // 1-bit input: Read clock
                        .RDEN(hid_en&(|hid_we)&one_hot_data_addr[5]&~hid_addr[14]), // 1-bit input: Read enable
                        .REGCE(1'b1),              // 1-bit input: Clock enable
                        .RST(rst),               // 1-bit input: Asynchronous Reset
                        .RSTREG(1'b0),             // 1-bit input: Output register set/reset
                        // Write Control Signals: 1-bit (each) input: Write clock and enable input signals
                        .WRCLK(~clk_i),         // 1-bit input: Write clock
                        .WREN(new_event),               // 1-bit input: Write enable
                        // Write Data: 32-bit (each) input: Write input data
                        .DI(mouse_scan_code),                   // 32-bit input: Data input
                        .DIP(1'b0)                  // 4-bit input: Parity input
                        );

   for (genvar i = 0; i < 8; i = i + 1) begin
      sevensegment
                   u_seg(.in  (mouse_scan_code[(i+1)*4-1:i*4]),
                         .out (digits[(i+1)*7-1:i*7]));
   end

nexys4ddr_display
  #(.FREQ(50000000))
u_display(.clk       (clk_i),
          .rst       (!rst_ni),
          .digits    (digits),
          .decpoints (8'b00000000),
          .CA        (CA),
          .CB        (CB),
          .CC        (CC),
          .CD        (CD),
          .CE        (CE),
          .CF        (CF),
          .CG        (CG),
          .DP        (DP),
          .AN        (AN));

	//--------------------------------------
	//			Mouse Reference Component
	//--------------------------------------
   MouseRefComp C0(
				.CLK(clk_i),
				.RESOLUTION(1'b0),
				.SWITCH(1'b0),
				.RST(rst),
				.LEFT(left),
				.MIDDLE(middle),
				.NEW_EVENT(new_event),
				.RIGHT(right),
				.XPOS(X),
				.YPOS(Y),
				.ZPOS(Z),
				.PS2_CLK(PS2_MCLK),
				.PS2_DATA(PS2_MDATA)
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
