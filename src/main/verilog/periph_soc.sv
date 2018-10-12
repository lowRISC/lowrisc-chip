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

module periph_soc #(UBAUD_DEFAULT=54)
  (
 output wire        uart_tx,
 output wire        uart_irq,
 input wire         uart_rx,
 // clock and reset
 input wire         clk_200MHz,
 input wire         pxl_clk,
 input wire         msoc_clk,
 input wire         rstn,
 output reg [21:0]  to_led,
 input wire [15:0]  from_dip,
 output wire        sd_sclk,
 input wire         sd_detect,
 inout wire [3:0]   sd_dat,
 inout wire         sd_cmd,
 output reg         sd_reset,
 output reg         sd_irq,
 input wire         hid_en,
 input wire [7:0]   hid_we,
 input wire [17:0]  hid_addr,
 input wire [63:0]  hid_wrdata,
 output reg [63:0]  hid_rddata,
 //keyboard
 inout wire         PS2_CLK,
 inout wire         PS2_DATA,
 
   // display
 output wire        VGA_HS_O,
 output wire        VGA_VS_O,
 output wire [3:0]  VGA_RED_O,
 output wire [3:0]  VGA_BLUE_O,
 output wire [3:0]  VGA_GREEN_O,
// SMSC ethernet PHY to framing_top connections
 input wire         clk_rmii,
 input wire         locked,
 output wire        eth_rstn,
 input wire         eth_crsdv,
 output wire        eth_refclk,
 output wire [1:0]  eth_txd,
 output wire        eth_txen,
 input wire [1:0]   eth_rxd,
 input wire         eth_rxerr,
 output wire        eth_mdc,
 input wire         phy_mdio_i,
 output wire        phy_mdio_o,
 output wire        phy_mdio_t,
 output wire        eth_irq,
 output wire        ram_clk,
 output wire        ram_rst,
 output wire        ram_en,
 output wire [7:0]  ram_we,
 output wire [15:0] ram_addr,
 output wire [63:0] ram_wrdata,
 input  wire [63:0] ram_rddata
 );
 
 wire [19:0] dummy;
 wire        scan_ready, scan_released;
 wire [7:0]  scan_code, fstore_data;
 wire        keyb_empty, tx_error_no_keyboard_ack;   
 reg [31:0]  keycode;
 reg scan_ready_dly;
 wire [8:0] keyb_fifo_out;
 // signals from/to core
logic [7:0] one_hot_data_addr;
logic [63:0] one_hot_rdata[7:0];

    ps2 keyb_mouse(
      .clk(msoc_clk),
      .rst(~rstn),
      .PS2_K_CLK_IO(PS2_CLK),
      .PS2_K_DATA_IO(PS2_DATA),
      .PS2_M_CLK_IO(),
      .PS2_M_DATA_IO(),
      .rx_released(scan_released),
      .rx_scan_ready(scan_ready),
      .rx_scan_code(scan_code),
      .rx_scan_read(scan_ready),
      .tx_error_no_keyboard_ack(tx_error_no_keyboard_ack));
 
 always @(negedge msoc_clk)
    begin
        scan_ready_dly <= scan_ready;
    end
    
 my_fifo #(.width(9)) keyb_fifo (
       .clk(~msoc_clk),      // input wire read clk
       .rst(~rstn),      // input wire rst
       .din({scan_released, scan_code}),      // input wire [31 : 0] din
       .wr_en(scan_ready & ~scan_ready_dly),  // input wire wr_en
       .rd_en(hid_en&(|hid_we)&one_hot_data_addr[6]&~hid_addr[14]),  // input wire rd_en
       .dout(keyb_fifo_out),    // output wire [31 : 0] dout
       .rdcount(),         // 12-bit output: Read count
       .wrcount(),         // 12-bit output: Write count
       .full(),    // output wire full
       .empty(keyb_empty)  // output wire empty
     );

    wire [7:0] red,  green, blue;
 
    fstore2 the_fstore(
      .pixel2_clk(pxl_clk),
      .vsyn(VGA_VS_O),
      .hsyn(VGA_HS_O),
      .red(red),
      .green(green),
      .blue(blue),
      .web(hid_we),
      .enb(hid_en & one_hot_data_addr[7]),
      .addrb(hid_addr[14:0]),
      .dinb(hid_wrdata),
      .doutb(one_hot_rdata[7]),
      .irst(~rstn),
      .clk_data(msoc_clk)
     );

 assign VGA_RED_O = red[7:4];
 assign VGA_GREEN_O = green[7:4];
 assign VGA_BLUE_O = blue[7:4];

   reg         u_trans, u_recv, uart_rx_full, uart_rx_empty, uart_tx_empty, uart_tx_full;   
   reg [15:0]  u_baud;
   wire        received, recv_err, is_recv, is_trans, uart_maj;
   wire [11:0] uart_rx_wrcount, uart_rx_rdcount, uart_tx_wrcount, uart_tx_rdcount;
   wire [8:0]  uart_rx_fifo_data_out, uart_tx_fifo_data_out;
   reg [7:0]   u_rx_byte, u_tx_byte;

   assign uart_irq = ~uart_rx_empty;

   assign one_hot_rdata[6] = hid_addr[14] ?
                              (hid_addr[13] ?
                               {4'b0,uart_tx_wrcount,
                                4'b0,uart_tx_rdcount,
                                4'b0,uart_rx_wrcount,
                                4'b0,uart_rx_rdcount} : 
                               {4'b0,uart_rx_full,uart_tx_full,uart_rx_empty,uart_rx_fifo_data_out}) :
                              {tx_error_no_keyboard_ack,keyb_empty,keyb_fifo_out[8:0]};

typedef enum {UTX_IDLE, UTX_EMPTY, UTX_INUSE, UTX_POP, UTX_START} utx_t;

   utx_t utxstate_d, utxstate_q;
   
always @(posedge msoc_clk)
    if (~rstn)
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
    if (hid_en & (|hid_we) & one_hot_data_addr[6] & hid_addr[14])
        casez (hid_addr[13:12])
         2'b00: begin u_trans = 1; u_tx_byte = hid_wrdata[7:0]; $write("%c", u_tx_byte); $fflush(); end
         2'b01: begin u_recv = 1; end
         2'b10: begin u_baud = hid_wrdata; end
         2'b11: begin end
        endcase
    end // else: !if(~rstn)

always @*
  begin
     utxstate_d = utxstate_q;
     casez(utxstate_q)
       UTX_IDLE:
         utxstate_d = UTX_EMPTY;
       UTX_EMPTY:
         if (~uart_tx_empty)
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
.clk(msoc_clk),
.in(uart_rx),		     
.maj(uart_maj));
// Core Instantiation
uart i_uart(
    .clk(msoc_clk), // The master clock for this module
    .rst(~rstn), // Synchronous reset.
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
       .clk(msoc_clk),      // input wire read clk
       .rst(~rstn),      // input wire rst
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
       .clk(msoc_clk),      // input wire read clk
       .rst(~rstn),      // input wire rst
       .din({1'b0,u_tx_byte}),      // input wire [8 : 0] din
       .wr_en(u_trans),  // input wire wr_en
       .rd_en(utxstate_q==UTX_POP),  // input wire rd_en
       .dout(uart_tx_fifo_data_out),    // output wire [8 : 0] dout
       .rdcount(uart_tx_rdcount),         // 12-bit output: Read count
       .wrcount(uart_tx_wrcount),         // 12-bit output: Write count
       .full(uart_tx_full),    // output wire full
       .empty(uart_tx_empty)  // output wire empty
     );
   
//----------------------------------------------------------------------------//

always_comb
  begin:onehot
     integer i;
     hid_rddata = 64'b0;
     for (i = 0; i < 8; i++)
       begin
	   one_hot_data_addr[i] = hid_addr[17:15] == i;
	   hid_rddata |= (one_hot_data_addr[i] ? one_hot_rdata[i] : 64'b0);
       end
  end

   wire    tx_rd, rx_wr_en;
   wire       sd_data_busy, data_crc_ok, sd_dat_oe;
   wire [3:0] sd_dat_to_mem, sd_dat_to_host, sd_dat_to_host_maj;
   wire       sd_cmd_to_mem, sd_cmd_to_host, sd_cmd_to_host_maj, sd_cmd_oe;
   wire       sd_clk_o;       
   wire       sd_cmd_finish, sd_data_finish, sd_cmd_crc_ok, sd_cmd_index_ok;

   reg [2:0]  sd_data_start_reg;
   reg [1:0]  sd_align_reg;
   reg [15:0] sd_blkcnt_reg;
   reg [11:0] sd_blksize_reg;
   
   reg [15:0] clock_divider_sd_clk_reg;
   reg [2:0]  sd_cmd_setting_reg;
   reg [5:0]  sd_cmd_i_reg;
   reg [31:0] sd_cmd_arg_reg;
   reg [31:0] sd_cmd_timeout_reg;

   reg sd_cmd_start_reg;

   reg [2:0]  sd_data_start;
   reg [1:0]  sd_align;
   reg [15:0] sd_blkcnt;
   reg [11:0] sd_blksize;
   
   reg [15:0] clock_divider_sd_clk;
   reg [2:0]  sd_cmd_setting;
   reg [5:0]  sd_cmd_i;
   reg [31:0] sd_cmd_arg;
   reg [31:0] sd_cmd_timeout;

   reg 	   sd_cmd_start, sd_cmd_rst, sd_data_rst, sd_clk_rst;
   reg [15:0] from_dip_reg;

   wire [9:0] sd_xfr_addr;
   
logic [6:0] sd_clk_daddr;
logic       sd_clk_dclk, sd_clk_den, sd_clk_drdy, sd_clk_dwe, sd_clk_locked;
logic [15:0] sd_clk_din, sd_clk_dout;
logic [3:0] sd_irq_en_reg, sd_irq_stat_reg;
   logic [133:0]    sd_cmd_response, sd_cmd_response_reg;
   logic [31:0] 	sd_cmd_resp_sel, sd_status_reg;
   logic [31:0] 	sd_status, sd_cmd_wait, sd_data_wait, sd_cmd_wait_reg, sd_data_wait_reg;
   logic [6:0] 	    sd_cmd_crc_val;
   logic [47:0] 	sd_cmd_packet, sd_cmd_packet_reg;
   logic [15:0] 	sd_transf_cnt, sd_transf_cnt_reg;
   logic            sd_detect_reg;
   
assign sd_clk_dclk = msoc_clk;

always @(posedge msoc_clk or negedge rstn)
  if (!rstn)
    begin
       from_dip_reg <= 0;
	sd_align_reg <= 0;
	sd_blkcnt_reg <= 0;
	sd_blksize_reg <= 0;
	sd_data_start_reg <= 0;
	sd_clk_din <= 0;
	sd_clk_den <= 0;
	sd_clk_dwe <= 0;
	sd_clk_daddr <= 0;
	sd_cmd_i_reg <= 0;
	sd_cmd_arg_reg <= 0;
	sd_cmd_setting_reg <= 0;
	sd_cmd_start_reg <= 0;
	sd_reset <= 0;
	sd_data_rst <= 0;
	sd_cmd_rst <= 0;
	sd_clk_rst <= 0;
	sd_cmd_timeout_reg <= 0;
        sd_irq_stat_reg <= 0;
        sd_irq_en_reg <= 0;
        sd_irq <= 0;
	to_led <= 0;
   end
   else
     begin
        sd_irq_stat_reg <= {~sd_detect_reg,sd_detect_reg,sd_status[10],sd_status[8]};
        sd_irq <= |(sd_irq_en_reg & sd_irq_stat_reg);
        from_dip_reg <= from_dip;
	 if (hid_en&(|hid_we)&one_hot_data_addr[2]&~hid_addr[14])
	  case(hid_addr[6:3])
	    0: sd_align_reg <= hid_wrdata;
	    1: sd_clk_din <= hid_wrdata;
	    2: sd_cmd_arg_reg <= hid_wrdata;
	    3: sd_cmd_i_reg <= hid_wrdata;
	    4: {sd_data_start_reg,sd_cmd_setting_reg[2:0]} <= hid_wrdata;
	    5: sd_cmd_start_reg <= hid_wrdata;
	    6: {sd_reset,sd_clk_rst,sd_data_rst,sd_cmd_rst} <= hid_wrdata;
	    7: sd_blkcnt_reg <= hid_wrdata;
	    8: sd_blksize_reg <= hid_wrdata;
	    9: sd_cmd_timeout_reg <= hid_wrdata;
	   10: {sd_clk_dwe,sd_clk_den,sd_clk_daddr} <= hid_wrdata;
       11: sd_irq_en_reg <= hid_wrdata;            
	   // Not strictly related, but can indicate SD-card activity and so on
	   15: to_led <= hid_wrdata;
	   default:;
	  endcase
    end

always @(posedge sd_clk_o)
    begin
	sd_align <= sd_align_reg;
	sd_cmd_arg <= sd_cmd_arg_reg;
	sd_cmd_i <= sd_cmd_i_reg;
	{sd_data_start,sd_cmd_setting} <= {sd_data_start_reg,sd_cmd_setting_reg};
	sd_cmd_start <= sd_cmd_start_reg;
	sd_blkcnt <= sd_blkcnt_reg;
	sd_blksize <= sd_blksize_reg;
	sd_cmd_timeout <= sd_cmd_timeout_reg;
    end

   //Tx SD data
   wire [31:0] data_in_rx;
   //Rx SD data
   wire [31:0] data_out_tx;
   
   // tri-state gate
   io_buffer_fast IOBUF_cmd_inst (
       .outg(sd_cmd_to_host),     // Buffer output
       .inoutg(sd_cmd),   // Buffer inout port (connect directly to top-level port)
       .ing(sd_cmd_to_mem),     // Buffer input
       .ctrl(~sd_cmd_oe)      // 3-state enable input, high=input, low=output
    );

    rx_delay cmd_rx_dly(
        .clk(clk_200MHz),
        .in(sd_cmd_to_host),             
        .maj(sd_cmd_to_host_maj));

   io_buffer_fast IOBUF_clk_inst (
        .outg(),     // Buffer output
        .inoutg(sd_sclk),   // Buffer inout port (connect directly to top-level port)
        .ing(~sd_clk_o),     // Buffer input
        .ctrl(~sd_clk_rst)      // 3-state enable input, high=input, low=output
   );

    genvar sd_dat_ix;
    generate for (sd_dat_ix = 0; sd_dat_ix < 4; sd_dat_ix=sd_dat_ix+1)
        begin:sd_dat_gen
         io_buffer_fast IOBUF_dat_inst (
            .outg(sd_dat_to_host[sd_dat_ix]),     // Buffer output
            .inoutg(sd_dat[sd_dat_ix]),   // Buffer inout port (connect directly to top-level port)
            .ing(sd_dat_to_mem[sd_dat_ix]),     // Buffer input
            .ctrl(~sd_dat_oe)      // 3-state enable input, high=input, low=output
        );
        rx_delay dat_rx_dly(
            .clk(clk_200MHz),
            .in(sd_dat_to_host[sd_dat_ix]),             
            .maj(sd_dat_to_host_maj[sd_dat_ix]));
        end
        
   endgenerate
   
   logic [7:0] rx_wr = rx_wr_en ? (sd_xfr_addr[0] ? 8'hF0 : 8'hF) : 8'b0;
   logic [63:0] douta, doutb;
   logic sd_xfr_addr_prev;
   logic [31:0] swapbein = {data_in_rx[7:0],data_in_rx[15:8],data_in_rx[23:16],data_in_rx[31:24]};
   assign one_hot_rdata[3] = doutb;
   assign data_out_tx = sd_xfr_addr_prev ? {douta[39:32],douta[47:40],douta[55:48],douta[63:56]} :
                                           {douta[7:0],douta[15:8],douta[23:16],douta[31:24]};
  
   always @(negedge sd_clk_o)
       begin
       if (tx_rd) sd_xfr_addr_prev = sd_xfr_addr[0];
       end            
 
   dualmem_32K_64 RAMB16_S36_S36_inst_sd
       (
        .clka   ( ~sd_clk_o                   ),     // Port A Clock
        .douta  ( douta                       ),     // Port A 1-bit Data Output
        .addra  ( sd_xfr_addr[9:1]            ),     // Port A 9-bit Address Input
        .dina   ( {swapbein,swapbein}         ),     // Port A 1-bit Data Input
        .ena    ( tx_rd|rx_wr_en              ),     // Port A RAM Enable Input
        .wea    ( rx_wr                       ),     // Port A Write Enable Input
        .clkb   ( msoc_clk                    ),     // Port B Clock
        .doutb  ( doutb                       ),     // Port B 1-bit Data Output
        .addrb  ( hid_addr[11:3]              ),     // Port B 14-bit Address Input
        .dinb   ( hid_wrdata                  ),     // Port B 1-bit Data Input
        .enb    ( hid_en&one_hot_data_addr[3] ),     // Port B RAM Enable Input
        .web    ( hid_we                      )      // Port B Write Enable Input
        );

   always @(posedge msoc_clk)
     begin
     sd_status_reg <= sd_status;
     sd_cmd_response_reg <= sd_cmd_response;
     sd_cmd_wait_reg <= sd_cmd_wait;
     sd_data_wait_reg <= sd_data_wait;
     sd_cmd_packet_reg <= sd_cmd_packet;
     sd_transf_cnt_reg <= sd_transf_cnt;
     sd_detect_reg <= sd_detect;
        
     case(hid_addr[7:3])
       0: sd_cmd_resp_sel = sd_cmd_response_reg[38:7];
       1: sd_cmd_resp_sel = sd_cmd_response_reg[70:39];
       2: sd_cmd_resp_sel = sd_cmd_response_reg[102:71];
       3: sd_cmd_resp_sel = sd_cmd_response_reg[133:103];
       4: sd_cmd_resp_sel = sd_cmd_wait_reg;
       5: sd_cmd_resp_sel = sd_status_reg;
       6: sd_cmd_resp_sel = sd_cmd_packet_reg[31:0];
       7: sd_cmd_resp_sel = sd_cmd_packet_reg[47:32];       
       8: sd_cmd_resp_sel = sd_data_wait_reg;
       9: sd_cmd_resp_sel = sd_transf_cnt_reg;
      10: sd_cmd_resp_sel = 0;
      11: sd_cmd_resp_sel = 0;
      12: sd_cmd_resp_sel = sd_detect_reg;
      13: sd_cmd_resp_sel = sd_xfr_addr;
      14: sd_cmd_resp_sel = sd_irq_stat_reg;
      15: sd_cmd_resp_sel = {sd_clk_locked,sd_clk_drdy,sd_clk_dout};
      16: sd_cmd_resp_sel = sd_align_reg;
      17: sd_cmd_resp_sel = sd_clk_din;
      18: sd_cmd_resp_sel = sd_cmd_arg_reg;
      19: sd_cmd_resp_sel = sd_cmd_i_reg;
      20: sd_cmd_resp_sel = {sd_data_start_reg,sd_cmd_setting_reg};
      21: sd_cmd_resp_sel = sd_cmd_start_reg;
      22: sd_cmd_resp_sel = {sd_reset,sd_clk_rst,sd_data_rst,sd_cmd_rst};
      23: sd_cmd_resp_sel = sd_blkcnt_reg;
      24: sd_cmd_resp_sel = sd_blksize_reg;
      25: sd_cmd_resp_sel = sd_cmd_timeout_reg;
      26: sd_cmd_resp_sel = {sd_clk_dwe,sd_clk_den,sd_clk_daddr};
      27: sd_cmd_resp_sel = sd_irq_en_reg;
      // not really related but we can decide if we want to autoboot, and so on.
      31: sd_cmd_resp_sel = from_dip_reg;
      default: sd_cmd_resp_sel = 32'HDEADBEEF;
     endcase // case (hid_addr[7:3])
     end
   
   assign sd_status[3:0] = 4'b0;

   assign one_hot_rdata[2] = sd_cmd_resp_sel;

`ifdef FPGA_FULL
 
clk_wiz_1 sd_clk_div
     (
     // Clock in ports
      .clk_in1(msoc_clk),      // input clk_in1
      // Clock out ports
      .clk_sdclk(sd_clk_o),     // output clk_sdclk
      // Dynamic reconfiguration ports
      .daddr(sd_clk_daddr), // input [6:0] daddr
      .dclk(sd_clk_dclk), // input dclk
      .den(sd_clk_den), // input den
      .din(sd_clk_din), // input [15:0] din
      .dout(sd_clk_dout), // output [15:0] dout
      .drdy(sd_clk_drdy), // output drdy
      .dwe(sd_clk_dwe), // input dwe
      // Status and control signals
      .reset(~(sd_clk_rst&rstn)), // input reset
      .locked(sd_clk_locked));      // output locked

`else // !`ifdef FPGA

   assign sd_clk_o = msoc_clk;
   
`endif
   
sd_top sdtop(
    .sd_clk     (sd_clk_o),
    .cmd_rst    (~(sd_cmd_rst&rstn)),
    .data_rst   (~(sd_data_rst&rstn)),
    .setting_i  (sd_cmd_setting),
    .timeout_i  (sd_cmd_timeout),
    .cmd_i      (sd_cmd_i),
    .arg_i      (sd_cmd_arg),
    .start_i    (sd_cmd_start),
    .sd_data_start_i(sd_data_start),
    .sd_align_i(sd_align),
    .sd_blkcnt_i(sd_blkcnt),
    .sd_blksize_i(sd_blksize),
    .sd_data_i(data_out_tx),
    .sd_dat_to_host(sd_dat_to_host_maj),
    .sd_cmd_to_host(sd_cmd_to_host_maj),
    .finish_cmd_o(sd_cmd_finish),
    .finish_data_o(sd_data_finish),
    .response0_o(sd_cmd_response[38:7]),
    .response1_o(sd_cmd_response[70:39]),
    .response2_o(sd_cmd_response[102:71]),
    .response3_o(sd_cmd_response[133:103]),
    .crc_ok_o   (sd_cmd_crc_ok),
    .index_ok_o (sd_cmd_index_ok),
    .transf_cnt_o(sd_transf_cnt),
    .wait_o(sd_cmd_wait),
    .wait_data_o(sd_data_wait),
    .status_o(sd_status[31:4]),
    .packet0_o(sd_cmd_packet[31:0]),
    .packet1_o(sd_cmd_packet[47:32]),
    .crc_val_o(sd_cmd_crc_val),
    .crc_actual_o(sd_cmd_response[6:0]),
    .sd_rd_o(tx_rd),
    .sd_we_o(rx_wr_en),
    .sd_data_o(data_in_rx),    
    .sd_dat_to_mem(sd_dat_to_mem),
    .sd_cmd_to_mem(sd_cmd_to_mem),
    .sd_dat_oe(sd_dat_oe),
    .sd_cmd_oe(sd_cmd_oe),
    .sd_xfr_addr(sd_xfr_addr)
    );

framing_top open
  (
   .rstn(locked),
   .msoc_clk(msoc_clk),
   .clk_rmii(clk_rmii),
   .core_lsu_addr(hid_addr[14:0]),
   .core_lsu_wdata(hid_wrdata),
   .core_lsu_be(hid_we),
   .ce_d(hid_en),
   .we_d(hid_en & one_hot_data_addr[4] & (|hid_we)),
   .framing_sel(hid_en),
   .framing_rdata(one_hot_rdata[4]),
   .o_edutrefclk(eth_refclk),
   .i_edutrxd(eth_rxd),
   .i_edutrx_dv(eth_crsdv),
   .i_edutrx_er(eth_rxerr),
   .o_eduttxd(eth_txd),
   .o_eduttx_en(eth_txen),
   .o_edutmdc(eth_mdc),
   .i_edutmdio(phy_mdio_i),
   .o_edutmdio(phy_mdio_o),
   .oe_edutmdio(phy_mdio_t),
   .o_edutrstn(eth_rstn),
   .eth_irq(eth_irq)
);

   assign one_hot_rdata[1] = one_hot_rdata[0];
   assign one_hot_rdata[0] = ram_rddata;
   assign ram_wrdata = hid_wrdata;
   assign ram_addr = hid_addr[15:0];
   assign ram_we = hid_we;
   assign ram_en = hid_en&(one_hot_data_addr[1]|one_hot_data_addr[0]);
   assign ram_clk = msoc_clk;
   assign ram_rst = ~rstn;
   
endmodule // chip_top
`default_nettype wire
