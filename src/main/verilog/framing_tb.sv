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
`include "framing_tb.h"
  
module eth_dut (
 input wire   reset,
 input wire   phy_tx_clk,
 input wire   phy_rx_clk,
 output wire  phy_dv,
 output wire [3:0] phy_rx_data,
 input wire   phy_tx_en,
 input wire [3:0]  phy_tx_data
 );

 logic 	   loopback;
	   
 wire        uart_tx;
 wire        uart_irq;
 wire         uart_rx;
 // clock and reset
 wire         clk_200MHz;
 wire         pxl_clk;
 wire         msoc_clk;
 wire         rstn;
 logic         hid_en;
 logic         hid_we;
 logic [7:0]   hid_be;
 logic [14:0]  hid_addr;
 wire [63:0]  hid_wrdata;
 logic [7:0]   hid_cnt, hid_dly;
 logic [14:0]  pkt_len, pkt_idx;
 wire [63:0]  hid_rddata;
// SMSC ethernet PHY to framing_top connections
 wire         locked;
 wire        eth_rstn;
 wire         eth_crsdv;
 wire        eth_refclk;
 wire [3:0]  eth_txd;
 wire [3:0]   eth_rxd;
 wire         clk_mii;
 wire        eth_txer;
 wire        eth_txen;
 wire         eth_rxerr;
 wire        eth_mdc;
 wire         phy_mdio_i;
 wire        phy_mdio_o;
 wire        phy_mdio_t;
 wire        eth_irq;
 
 wire [19:0] dummy;
 wire        scan_ready, scan_released;
 wire [7:0]  scan_code, fstore_data;
 wire        keyb_empty, tx_error_no_keyboard_ack;   
 reg [31:0]  keycode;
 reg scan_ready_dly;
 wire [8:0] keyb_fifo_out;
 // signals from/to core
 reg [63:0] hid_wrdata_static;
 reg        hid_wrdata_sel;
 integer  log;
   
 assign hid_wrdata = hid_wrdata_sel ? hid_rddata : hid_wrdata_static;
   
framing_top_mii open
  (
   .clk_mii(clk_mii),
   .o_etx_er(eth_txer),
   .rstn(rstn),
   .msoc_clk(clk_mii),
   .core_lsu_addr(hid_addr),
   .core_lsu_wdata(hid_wrdata),
   .core_lsu_be(hid_be),
   .ce_d(hid_en),
   .we_d(hid_we),
   .framing_sel(hid_en),
   .framing_rdata(hid_rddata),
   .i_erxd(eth_rxd),
   .i_erx_dv(eth_crsdv),
   .i_erx_er(eth_rxerr),
   .o_etxd(eth_txd),
   .o_etx_en(eth_txen),
   .o_emdc(eth_mdc),
   .i_emdio(phy_mdio_i),
   .o_emdio(phy_mdio_o),
   .oe_emdio(phy_mdio_t),
   .o_erstn(eth_rstn),
   .eth_irq(eth_irq)
);

   assign rstn = ~reset;
   assign clk_mii = phy_tx_clk;
//   assign rx_clk = phy_rx_clk;
   assign phy_dv = eth_txen;
   assign phy_rx_data = eth_txd;
   assign eth_crsdv = loopback ? eth_txen : phy_tx_en;
   assign eth_rxd = loopback ? eth_txd : phy_tx_data;
   assign eth_rxerr = 1'b0;

   initial
     begin
        log = $fopen("eth.log", "w");
//        $dumpfile("test.vcd");
//        $dumpvars(0, axi_ethernetlite_0_exdes_tb);
     end
   
   always @(posedge clk_mii)
     if (reset) hid_cnt <= 0;
     else case(hid_cnt)
	    0:
	      begin
		 loopback <= 0;
		 hid_addr <= `RSR_OFFSET;
		 hid_wrdata_static <= 'b0;
		 hid_wrdata_sel <= 'b0;
		 hid_we <= 'b0;
		 hid_en <= 'b1;
		 hid_be <= 'h00;
		 hid_cnt <= 1;
	      end
	    1:
	      begin
		 if (hid_rddata & `RSR_RECV_DONE_MASK)
		   begin
		      hid_addr <= `RPLR_OFFSET;
		      if (loopback)
                        pkt_idx <= (pkt_idx | 'H7FF) + 1'b1;
		      else
                        pkt_idx <= 0;
		      hid_cnt <= 2;
		      loopback <= 1;
		   end
	      end
	    2:
	      begin
		 hid_addr <= `RSR_OFFSET;
		 hid_wrdata_static <= (hid_rddata & `RSR_RECV_FIRST_MASK) + 'b1;
                 hid_wrdata_sel <= 'b0;
		 hid_we <= 'b0;
		 hid_en <= 'b1;	  
		 hid_be <= 'hFF;
		 hid_cnt <= 3;
	      end
	    3:
	      begin
		 pkt_len <= hid_rddata;
		 hid_we <= 'b1;
		 hid_cnt <= 4;
	      end
	    4:
	      begin
		 hid_en <= 'b1;	  
		 hid_we <= 'b0;
		 hid_cnt <= 5;
	      end
	    5:
	      begin
		 hid_cnt <= 6;
	      end
	    6:
	      begin
		 hid_addr <= `RXBUFF_OFFSET + pkt_idx;
		 hid_we <= 'b0;
		 hid_wrdata_sel <= 1;
		 hid_cnt <= 7;		 
	      end
	    7:
	      begin
                 $fdisplay(log, "hid_addr = %X, hid_rddata = %X", hid_addr, hid_rddata);
		 hid_addr <= `TXBUFF_OFFSET + pkt_idx;
		 hid_we <= 'b1;
		 hid_be <= 'hFF;
		 hid_cnt <= 8;
		 pkt_idx <= pkt_idx + 8;
	      end
	    8:
	      begin
		 hid_addr <= `RXBUFF_OFFSET + pkt_idx;
		 hid_we <= 'b0;
		 if ((pkt_idx&'H7FF) < pkt_len+8)
		   hid_cnt <= 7;		 
		 else if (pkt_idx&'H2000)
		   hid_cnt <= 12;
		 else
		   hid_cnt <= 9;
	      end
	    9:
	      begin
		 hid_addr <= `TPLR_OFFSET;
		 hid_wrdata_static <= pkt_len;
		 hid_wrdata_sel <= 0;
		 hid_we <= 'b1;
		 hid_en <= 'b1;	  
		 hid_be <= 'hFF;
		 hid_cnt <= 10;
	      end
	    10:
	      begin
		 hid_addr <= `MACHI_OFFSET;
		 hid_wrdata_static <= `MACHI_ALLPKTS_MASK;
		 hid_wrdata_sel <= 0;
		 hid_we <= 'b1;
		 hid_en <= 'b1;	  
		 hid_be <= 'hFF;
		 hid_cnt <= 11;
		 hid_dly <= 0;
	      end
	    11:
	      begin
		 hid_en <= 'b1;	  
		 hid_we <= 'b0;
		 hid_addr <= `RSR_OFFSET;
		 hid_wrdata_static <= 'b0;
		 hid_dly <= hid_dly + 1;
		 if (hid_dly >= 16)
		   hid_cnt <= 1;
	      end
	    12:
              begin
		 hid_en <= 'b0;	  
		 hid_we <= 'b0;
	         hid_addr = 'b0;
		 hid_cnt <= 13;
                 $fclose(log);
              end
	    default:
	      begin
	      end
	  endcase
   
endmodule // chip_top
`default_nettype wire
