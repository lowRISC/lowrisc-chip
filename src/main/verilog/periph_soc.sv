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
 output wire        sd_clk_out,
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

`include "piton_sd_define.vh"

logic sys_clk, sd_clk, init_done;
// 4-bit full SD interface
    wire    [3:0]       sd_dat_dat_i;
    wire    [3:0]       sd_dat_out_o;
    wire                sd_dat_oe_o;
    wire                sd_cmd_dat_i;
    wire                sd_cmd_out_o;
    wire                sd_cmd_oe_o;
    wire                sd_int_cmd;
    wire                sd_int_data;

 // Request Slave
 logic [`SD_ADDR_WIDTH-1:0]    req_addr_sd;    // addr in SD 
 logic [`SD_ADDR_WIDTH-1:0]    req_addr_dma;   // addr in fake memory
 logic [`SD_ADDR_WIDTH-10:0]   req_blkcnt;

 logic                         req_wr;     // HIGH write; LOW read.
 logic                         req_val;
 logic [`SD_ADDR_WIDTH-1:0]    req_addr_sd_f;    // addr in SD 
 logic [`SD_ADDR_WIDTH-1:0]    req_addr_dma_f;   // addr in fake memory
 logic                         sd_irq_en;
  logic   [31:0]      core_buffer_addr;
  logic                core_buffer_ce;
  logic                core_buffer_wr;
  logic   [1:0]       core_buffer_sz;
  logic   [`NOC_DATA_BITS]    core_buffer_data;
  logic   [`NOC_DATA_BITS]    buffer_core_data;
 
  logic sys_rst_reg;
  
 wire                         req_rdy, is_hcxc;
 wire                         sys_rst = sys_rst_reg | !rstn;
 // Response Master
 wire                         resp_ok;    // HIGH ok; LOW err.
 wire                         resp_val;
logic                         resp_rdy;
reg [15:0]                    from_dip_reg;
logic [63:0]                  resp_vec, resp_data, hid_wrdata_rev, hid_rddata_norev, hid_rddata_rev;
wire [7:0]                    init_state;
// compact FSM output
wire [23:0]                   counter;
wire [42:0]                   init_fsm; // {adr, dat, we, stb, counter_en}
wire  [5:0]                   tran_state;
// tran compact FSM output
wire [41:0]                   tran_fsm; // {adr, dat, we, stb}

for (genvar i = 0; i < 64; i += 8)
    begin
        assign hid_wrdata_rev[i +: 8] = hid_wrdata[(56-i) +: 8];
        assign hid_rddata_rev[i +: 8] = hid_rddata_norev[(56-i) +: 8];
    end
    
always @(posedge msoc_clk or negedge rstn)
  if (!rstn)
    begin
       from_dip_reg <= 0;
       sd_irq <= 0;
       sd_irq_en <= 0;
       resp_vec <= 0;
	   to_led <= 0;
	   sys_rst_reg <= 0;
   end
   else
     begin
        if (resp_val)
            resp_vec <= {resp_vec,resp_ok};
        resp_rdy <= resp_val;
        sd_irq <= sd_irq_en & req_rdy;
        from_dip_reg <= from_dip;
	 if (hid_en&(|hid_we)&one_hot_data_addr[2]&~hid_addr[14])
	  case(hid_addr[6:3])
	    0: req_addr_sd <= hid_wrdata;
	    1: req_addr_dma <= hid_wrdata;
	    2: req_blkcnt <= hid_wrdata;
	    3: {sys_rst_reg,sd_irq_en,req_wr,req_val} <= hid_wrdata;
       // Not strictly related, but can indicate SD-card activity and so on
	   15: to_led <= hid_wrdata;
	   default:;
	  endcase
	  case(hid_addr[6:3])
	    0: resp_data <= req_addr_sd_f;
	    1: resp_data <= req_addr_dma_f;
        2: resp_data <= {sd_detect,is_hcxc,init_done,req_rdy,sd_irq,sd_irq_en,req_wr,req_val};
        3: resp_data <= resp_vec;
        4: resp_data <= init_state;
        5: resp_data <= counter;
        6: resp_data <= init_fsm;
        7: resp_data <= tran_state;
        8: resp_data <= tran_fsm;
        // not really related but we can decide if we want to autoboot, and so on.
       31: resp_data <= from_dip_reg;
       default: resp_data <= 32'HDEADBEEF;
      endcase
    end

`ifndef VCS

ila_1 ila_resp (
	.clk(msoc_clk), // input wire clk
	.probe0(req_addr_sd_f), // input wire [0:0]  probe0  
	.probe1(req_addr_dma_f), // input wire [0:0]  probe1 
	.probe2({sd_detect,is_hcxc,init_done,req_rdy,sd_irq,sd_irq_en,req_wr,req_val}), // input wire [0:0]  probe2 
	.probe3(resp_vec), // input wire [3:0]  probe3 
	.probe4(init_state), // input wire [3:0]  probe4 
	.probe5(counter), // input wire [0:0]  probe5 
	.probe6(init_fsm), // input wire [0:0]  probe6 
	.probe7(tran_state), // input wire [0:0]  probe7 
	.probe8(tran_fsm), // input wire [0:0]  probe6 
	.probe9({sys_rst_reg,sd_irq_en,req_wr,req_val}) // input wire [0:0]  probe6 
);

`endif

   assign one_hot_rdata[2] = resp_data;

   assign  sd_cmd      =   sd_cmd_oe_o ? sd_cmd_out_o : 1'bz;
   assign  sd_dat      =   sd_dat_oe_o ? sd_dat_out_o : 4'bz;
   assign  sd_cmd_dat_i    =   sd_cmd;
   assign  sd_dat_dat_i    =   sd_dat;
   assign  sd_reset    =   sys_rst;

   wire    sd_clk_out_internal;

   ODDR sd_clk_oddr (
            .Q(sd_clk_out),
            .C(sd_clk_out_internal),
            .CE(1),
            .D1(1),
            .D2(0),
            .R(0),
            .S(0)
            );

piton_sd_top dut
(
    // Clock and reset
    .sys_clk(msoc_clk),
    .sd_clk(msoc_clk),
    .sys_rst(sys_rst),

    // SD interface
    .sd_cd(sd_detect),
    .sd_reset,
    .sd_clk_out(sd_clk_out_internal),
    .sd_cmd_dat_i,
    .sd_cmd_out_o,
    .sd_cmd_oe_o,
    .sd_dat_dat_i,
    .sd_dat_out_o,
    .sd_dat_oe_o,

    .init_done,
    .req_addr_sd            (req_addr_sd),
    .req_addr_dma           (req_addr_dma),
    .req_blkcnt             (req_blkcnt),
    .req_wr                 (req_wr),
    .req_val                (req_val),
    .req_rdy                (req_rdy),
    .req_addr_sd_f          (req_addr_sd_f),
    .req_addr_dma_f         (req_addr_dma_f),

    .resp_ok                (resp_ok),
    .resp_val               (resp_val),
    .resp_rdy               (resp_rdy),
    
    .core_buffer_addr(hid_addr),
    .core_buffer_data(hid_wrdata_rev),
    .core_buffer_ce(hid_en & one_hot_data_addr[3]),
    .core_buffer_wr(|hid_we),
    .core_buffer_sz(3),
    .buffer_core_data(hid_rddata_norev),

    .is_hcxc                (is_hcxc),
    .init_state             (init_state),
    // compact FSM output
    .counter,
    .init_fsm, // {adr, dat, we, stb, counter_en}
    .tran_state             (tran_state),
    // compact FSM output
    .tran_fsm               (tran_fsm) // {adr, dat, we, stb, counter_en}
 
    );

assign one_hot_rdata[3] = hid_rddata_rev;

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
