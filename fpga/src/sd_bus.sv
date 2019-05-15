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

module sd_bus
  (
 input wire         clk_200MHz,
 input wire         msoc_clk,
 input wire         rstn,
 output wire        sd_sclk,
 input wire         sd_detect,
 inout wire [3:0]   sd_dat,
 inout wire         sd_cmd,
 output reg         sd_reset,
 output reg         sd_irq,
 input wire         spisd_en,
 input wire         spisd_we,
 input wire [7:0]   spisd_be,
 input wire [15:0]  spisd_addr,
 input wire [63:0]  spisd_wrdata,
 output reg [63:0]  spisd_rddata
 );

//----------------------------------------------------------------------------//

   wire       tx_rd, rx_wr_en;
   wire       sd_dat_oe;
   wire [3:0] sd_dat_to_mem, sd_dat_to_host, sd_dat_to_host_maj;
   wire       sd_cmd_to_mem, sd_cmd_to_host, sd_cmd_to_host_maj, sd_cmd_oe;
   wire       sd_clk_o;       
   wire       sd_cmd_finish, sd_data_finish, sd_cmd_crc_ok, sd_cmd_index_ok;

   reg [2:0]  sd_data_start_reg;
   reg [1:0]  sd_align_reg;
   reg [15:0] sd_blkcnt_reg;
   reg [11:0] sd_blksize_reg;
   
   reg [2:0]  sd_cmd_setting_reg;
   reg [5:0]  sd_cmd_i_reg;
   reg [31:0] sd_cmd_arg_reg;
   reg [31:0] sd_cmd_timeout_reg;

   reg sd_cmd_start_reg;

   reg [2:0]  sd_data_start;
   reg [1:0]  sd_align;
   reg [15:0] sd_blkcnt;
   reg [11:0] sd_blksize;
   
   reg [2:0]  sd_cmd_setting;
   reg [5:0]  sd_cmd_i;
   reg [31:0] sd_cmd_arg;
   reg [31:0] sd_cmd_timeout;

   reg 	   sd_cmd_start, sd_cmd_rst, sd_data_rst, sd_clk_rst;
   wire [9:0] sd_xfr_addr;
   
   logic [6:0] sd_clk_daddr;
   logic       sd_clk_dclk, sd_clk_den, sd_clk_drdy, sd_clk_dwe, sd_clk_locked;
   logic [15:0] sd_clk_din, sd_clk_dout;
   logic [3:0]  sd_irq_en_reg, sd_irq_stat_reg;
   logic [133:0] sd_cmd_response, sd_cmd_response_reg;
   logic [31:0]  sd_cmd_resp_sel, sd_status_reg;
   logic [31:0]  sd_status, sd_cmd_wait, sd_data_wait, sd_cmd_wait_reg, sd_data_wait_reg;
   logic [6:0]   sd_cmd_crc_val;
   logic [47:0]  sd_cmd_packet, sd_cmd_packet_reg;
   logic [15:0]  sd_transf_cnt, sd_transf_cnt_reg;
   logic         sd_detect_reg;
   logic         sd_xfr_addr_prev, spisd_addr_prev_15;
   
assign sd_clk_dclk = msoc_clk;

always @(posedge msoc_clk or negedge rstn)
  if (!rstn)
    begin
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
   end
   else
     begin
        spisd_addr_prev_15 <= spisd_addr[15];
        sd_irq_stat_reg <= {~sd_detect_reg,sd_detect_reg,sd_status[10],sd_status[8]};
        sd_irq <= |(sd_irq_en_reg & sd_irq_stat_reg);
        if (spisd_en&spisd_we&(|spisd_be)&~spisd_addr[15])
	  case(spisd_addr[6:3])
	    0: sd_align_reg <= spisd_wrdata;
	    1: sd_clk_din <= spisd_wrdata;
	    2: sd_cmd_arg_reg <= spisd_wrdata;
	    3: sd_cmd_i_reg <= spisd_wrdata;
	    4: {sd_data_start_reg,sd_cmd_setting_reg[2:0]} <= spisd_wrdata;
	    5: sd_cmd_start_reg <= spisd_wrdata;
	    6: {sd_reset,sd_clk_rst,sd_data_rst,sd_cmd_rst} <= spisd_wrdata;
	    7: sd_blkcnt_reg <= spisd_wrdata;
	    8: sd_blksize_reg <= spisd_wrdata;
	    9: sd_cmd_timeout_reg <= spisd_wrdata;
	   10: {sd_clk_dwe,sd_clk_den,sd_clk_daddr} <= spisd_wrdata;
           11: sd_irq_en_reg <= spisd_wrdata;            
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
   logic [31:0] swapbein = {data_in_rx[7:0],data_in_rx[15:8],data_in_rx[23:16],data_in_rx[31:24]};
   assign spisd_rddata = spisd_addr_prev_15 ? doutb : sd_cmd_resp_sel;
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
        .addrb  ( spisd_addr[11:3]            ),     // Port B 14-bit Address Input
        .dinb   ( spisd_wrdata                ),     // Port B 1-bit Data Input
        .enb    ( spisd_en&spisd_addr[15]     ),     // Port B RAM Enable Input
        .web    ( spisd_we ? spisd_be : 4'b0  )      // Port B Write Enable Input
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
        
     case(spisd_addr[7:3])
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
      default: sd_cmd_resp_sel = 32'HDEADBEEF;
     endcase // case (spisd_addr[7:3])
     end
   
   assign sd_status[3:0] = 4'b0;

xlnx_clk_sd sd_clk_div
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

`ifdef XLNX_ILA_SD
xlnx_ila_sd sd_ila (
.clk(msoc_clk), // input wire clk   
.probe0	(1'b0),
.probe1 (rstn),
.probe2 (1'b0),
.probe3 (1'b0),
.probe4 (1'b0),
.probe5 (data_in_rx),
.probe6 (data_out_tx),
.probe7 (douta),
.probe8 (doutb),
.probe9 (rx_wr),
.probe10 (rx_wr_en),
.probe11 (sd_align),
.probe12 (sd_align_reg),
.probe13 (sd_blkcnt),
.probe14 (sd_blkcnt_reg),
.probe15 (sd_blksize),
.probe16 (sd_blksize_reg),
.probe17 (sd_clk_daddr),
.probe18 (sd_clk_dclk),
.probe19 (sd_clk_den),
.probe20 (sd_clk_din),
.probe21 (sd_clk_dout),
.probe22 (sd_clk_drdy),
.probe23 (sd_clk_dwe),
.probe24 (sd_clk_locked),
.probe25 (sd_clk_rst),
.probe26 (sd_cmd_arg),
.probe27 (sd_cmd_arg_reg),
.probe28 (sd_cmd_crc_ok),
.probe29 (sd_cmd_crc_val),
.probe30 (sd_cmd_i),
.probe31 (sd_cmd_index_ok),
.probe32 (sd_cmd_i_reg),
.probe33 (sd_cmd_oe),
.probe34 (sd_cmd_packet),
.probe35 (sd_cmd_packet_reg),
.probe36 (sd_cmd_response),
.probe37 (sd_cmd_response_reg),
.probe38 (sd_cmd_resp_sel),
.probe39 (sd_cmd_rst),
.probe40 (sd_cmd_setting),
.probe41 (sd_cmd_setting_reg),
.probe42 (sd_cmd_start),
.probe43 (sd_cmd_start_reg),
.probe44 (sd_cmd_timeout),
.probe45 (sd_cmd_timeout_reg),
.probe46 (1'b0),
.probe47 (sd_cmd_to_host_maj),
.probe48 (sd_cmd_wait),
.probe49 (sd_cmd_wait_reg),
.probe50 (4'b0),
.probe51 (sd_data_finish),
.probe52 (sd_data_rst),
.probe53 (sd_data_start),
.probe54 (sd_data_start_reg),
.probe55 (sd_data_wait),
.probe56 (sd_data_wait_reg),
.probe57 (sd_dat_oe),
.probe58 (4'b0),
.probe59 (sd_dat_to_host_maj),
.probe60 (sd_dat_to_mem),
.probe61 (sd_detect_reg),
.probe62 (sd_irq),
.probe63 (sd_irq_en_reg),
.probe64 (sd_irq_stat_reg),
.probe65 (sd_reset),
.probe66 (sd_status),
.probe67 (sd_status_reg),
.probe68 (sd_transf_cnt),
.probe69 (sd_transf_cnt_reg),
.probe70 (sd_xfr_addr),
.probe71 (sd_xfr_addr_prev),
.probe72 (spisd_addr),
.probe73 (spisd_addr_prev_15),
.probe74 (spisd_be),
.probe75 (spisd_rddata),
.probe76 (spisd_wrdata),
.probe77 (swapbein),
.probe78 (1'b0),
.probe79 (1'b0),
.probe80 (1'b0),
.probe81 (1'b0),
.probe82 (1'b0),
.probe83 (sd_cmd_finish),
.probe84 (sd_cmd_to_mem),
.probe85 (1'b0),
.probe86 (sd_detect),
.probe87 (spisd_we),
.probe88 (spisd_en),
.probe89 (tx_rd)
  );
`endif   
   
endmodule // chip_top
`default_nettype wire
