/*
This file is part of the ethernet_mac project. https://github.com/pkerling/ethernet_mac
MAC sublayer functionality (en-/decapsulation, FCS, IPG)
 
Copyright (c) 2015, Philipp Kerling
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of ethernet_mac nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

* Neither the source code, nor any derivative product, may be used to operate
  weapons, nuclear facilities, life support or other mission critical
  applications where human life or property may be at stake or endangered.
  
* Neither the source code, nor any derivative product, may be used for military
  purposes.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This Verilog version generated using 
vhdl2verilog -in ../ethernet_mac/framing.vhd -out framing.v -top framing -arch rtl

vhdl2verilog is available from: http://www.edautils.com/vhdl2verilog.html
 
Corrections to pass formality verification by Jonathan Kimmitt, to whom all enquiries should be directed
 */

`default_nettype none

module framing(
	input wire		tx_reset_i,
	input wire		tx_clock_i,
	input wire		rx_reset_i,
	input wire		rx_clock_i,
	input wire	[47:0] 	mac_address_i,
	input wire		tx_enable_i,
	input wire	[7:0] 	tx_data_i,
	output wire		tx_byte_sent_o,
	output reg	[31:0] 	tx_fcs_o,
	output reg		tx_busy_o,
	output reg		rx_frame_o,
	output reg	[7:0] 	rx_data_o,
	output reg		rx_byte_received_o,
	output reg		rx_error_o,
	output wire	[10:0] 	rx_frame_size_o,
	output reg	[31:0] 	rx_fcs_o,
	output reg		mii_tx_enable_o,
	output reg	[7:0] 	mii_tx_data_o,
	input wire		mii_tx_byte_sent_i,
	output reg		mii_tx_gap_o,
	input wire		mii_rx_frame_i,
	input wire	[7:0] 	mii_rx_data_i,
	input wire		mii_rx_byte_received_i,
	input wire		mii_rx_error_i,
   	output wire 		rx_fcs_err_o,
   	output reg 	[10:0]	rx_packet_length_o,
        input wire              promiscuous_i);
   
localparam CRC32_POSTINVERT_MAGIC = 32'b11000111000001001101110101111011;
localparam CRC32_BYTES = (((31)-(0)+1) / 8);
localparam [2:0]  MAC_ADDRESS_BYTES = 3'b110;
localparam BROADCAST_MAC_ADDRESS = 48'b111111111111111111111111111111111111111111111111;
localparam SPEED_1000MBPS = 2'b10;
localparam SPEED_100MBPS = 2'b01;
localparam SPEED_10MBPS = 2'b00;
localparam SPEED_UNSPECIFIED = 2'b11;
localparam PREAMBLE_DATA = 8'b01010101;
localparam START_FRAME_DELIMITER_DATA = 8'b11010101;
localparam PADDING_DATA = 8'b00000000;
localparam MIN_FRAME_DATA_BYTES = ((46 + 2) + 6) + 6;
localparam MAX_FRAME_DATA_BYTES = ((1500 + 2) + 6) + 6;
localparam INTERPACKET_GAP_BYTES = 12;
localparam PACKET_LENGTH_BITS = 11;
localparam MAX_PACKET_LENGTH = (1 << PACKET_LENGTH_BITS) - 1;
wire [32:0] CRC32_POLYNOMIAL = (1<<32)|(1<<26)|(1<<23)|(1<<22)|(1<<16)|(1<<12)|(1<<11)|(1<<10)|(1<<8)|(1<<7)|(1<<5)|(1<<4)|(1<<2)|(1<<1)|(1<<0);
wire [3:0] TX_IDLE=0,
TX_PREAMBLE2=1,
TX_PREAMBLE3=2,
TX_PREAMBLE4=3,
TX_PREAMBLE5=4,
TX_PREAMBLE6=5,
TX_PREAMBLE7=6,
TX_START_FRAME_DELIMITER=7,
TX_CLIENT_DATA_WAIT_SOURCE_ADDRESS=8,
TX_SOURCE_ADDRESS=9,
TX_CLIENT_DATA=10,
TX_PAD=11,
TX_FRAME_CHECK_SEQUENCE2=12,
TX_FRAME_CHECK_SEQUENCE3=13,
TX_FRAME_CHECK_SEQUENCE4=14,
TX_INTERPACKET_GAP=15;
wire [2:0] RX_WAIT_START_FRAME_DELIMITER=0,
RX_DATA=1,
RX_ERROR=2,
RX_SKIP_FRAME=3,
RX_WAIT=4;
   
wire FALSE=1'b0,TRUE=1'b1;
   
    function [7:0] extract_byte;
       input [47:0] vec;
       input [2:0]  byteno;
       begin
	  extract_byte = vec >> {byteno,3'b000};
       end
    endfunction 

    function [7:0] fcs_output_byte;
       input [31:0] fcs;
       input [31:0] byteno;
       reg [31:0] reversed;
       integer 	  i;
       
       begin
	  for (i = 0; i < 32; i=i+1)
	    reversed[31-i] = fcs[i];
	  fcs_output_byte = ~(reversed >> {byteno,3'b000});
       end
    endfunction 

    function [31:0] update_crc32;
        input [31:0] old_crc;
        input [7:0] input0;
        reg [7:0] data_out;
        reg 	 feedback;
        reg [31:0] poly, new_crc;
       
        integer 	 i;
       
        begin
	  poly = (1<<26)|(1<<23)|(1<<22)|(1<<16)|
		   (1<<12)|(1<<11)|(1<<10)|(1<<8)|(1<<7)|(1<<5)|(1<<4)|(1<<2)|(1<<1)|(1<<0);
	  new_crc = old_crc;
	  for (i = 0; i < 8; i=i+1)
	    begin
	       feedback = new_crc[31] ^ input0[i];
	       new_crc = feedback ? {new_crc[30:0],1'b0} ^ poly : {new_crc[30:0],1'b0};
	    end
	   update_crc32 = new_crc;
	end
       
    endfunction 

    reg [3:0]tx_state;
    reg [6:0]tx_padding_required;
    reg [31:0]tx_frame_check_sequence;
    reg [2:0]tx_mac_address_byte;
    reg [3:0]tx_interpacket_gap_counter;
    reg [2:0]rx_state;
    reg [2:0]rx_padding;
    reg [2:0]rx_mac_address_byte;
    reg rx_is_group_address;
    reg [10:0]rx_frame_size;
    reg [31:0]rx_frame_check_sequence;
    reg [1:0]  update_fcs;
    reg [7:0]  data_out;
    wire rx_fcs_err;

    assign rx_frame_size_o = rx_frame_size;
    assign rx_fcs_err_o = rx_fcs_err;
    assign rx_fcs_err = rx_frame_check_sequence != CRC32_POSTINVERT_MAGIC;
    assign tx_byte_sent_o = (((tx_state == TX_CLIENT_DATA | tx_state == TX_CLIENT_DATA_WAIT_SOURCE_ADDRESS) | tx_state == TX_SOURCE_ADDRESS) && mii_tx_byte_sent_i ==  1'b1) ?  1'b1 :  1'b0;

    always @ ( posedge tx_clock_i)
  if (tx_reset_i ==  1'b1)
        begin
  tx_state <= TX_IDLE;
            mii_tx_enable_o <= 1'b0;
            tx_busy_o <= 1'b1;
            tx_padding_required <= 0;
            tx_fcs_o <= 32'b0;
            mii_tx_data_o <= 8'b0;
        end
        else
        begin 
            begin
                mii_tx_enable_o <= 1'b0;
                tx_busy_o <= 1'b0;
  if (tx_state == TX_IDLE)
                begin
                    if ( tx_enable_i == 1'b1 ) 
                    begin
        tx_state <= TX_PREAMBLE2;
          mii_tx_data_o <= PREAMBLE_DATA;
                        mii_tx_enable_o <= 1'b1;
                        mii_tx_gap_o <= 1'b0;
                        tx_busy_o <= 1'b1;
                    end
                end
                else
                begin 
                    mii_tx_enable_o <= 1'b1;
                    tx_busy_o <= 1'b1;
                    if ( mii_tx_byte_sent_i == 1'b1 ) 
                    begin
                        mii_tx_gap_o <= 1'b0;
                        data_out = 8'b0;
                        update_fcs = 'b0;
                        case ( tx_state ) 
            TX_IDLE:
                        begin
                        end
            TX_PREAMBLE2, TX_PREAMBLE3, TX_PREAMBLE4, TX_PREAMBLE5, TX_PREAMBLE6:
                        begin
            tx_state <= tx_state+1;
              data_out = PREAMBLE_DATA;
                        end
            TX_PREAMBLE7:
                        begin
            tx_state <= TX_START_FRAME_DELIMITER;
              data_out = PREAMBLE_DATA;
                        end
            TX_START_FRAME_DELIMITER:
                        begin
            tx_state <= TX_CLIENT_DATA;
              data_out = START_FRAME_DELIMITER_DATA;
              tx_padding_required <= MIN_FRAME_DATA_BYTES;

                            tx_frame_check_sequence <= { 32{1'b1} };
                            tx_mac_address_byte <= 3'b000;
                        end
            TX_CLIENT_DATA_WAIT_SOURCE_ADDRESS:
                        begin
            data_out = tx_data_i;
              update_fcs = TRUE;
              if (tx_mac_address_byte < MAC_ADDRESS_BYTES)
                            begin
                tx_mac_address_byte <= tx_mac_address_byte + 3'b001;
                            end
                            else
                            begin 
                                if ( tx_data_i == 8'b11111111 ) 
                                begin
                    tx_state <= TX_SOURCE_ADDRESS;
                      data_out = mac_address_i[7:0] ;
                                    tx_mac_address_byte <= 3'b001;
                                end
                                else
                                begin 
                    tx_state <= TX_CLIENT_DATA;
                                end
                            end
                            if ( tx_enable_i == 1'b0 ) 
                            begin
                tx_state <= TX_PAD;
                  data_out = PADDING_DATA;
                            end
                        end
            TX_SOURCE_ADDRESS:
                        begin
            data_out = extract_byte(mac_address_i, tx_mac_address_byte);
              update_fcs = TRUE;
              if (tx_mac_address_byte < (MAC_ADDRESS_BYTES - 3'b001))
                            begin
                tx_mac_address_byte <= tx_mac_address_byte + 3'b001;
                            end
                            else
                            begin 
                tx_state <= TX_CLIENT_DATA;
                            end
                        end
            TX_CLIENT_DATA:
                        begin
            data_out = tx_data_i;
              update_fcs = TRUE;
                            if ( tx_enable_i == 1'b0 ) 
                            begin
                                if ( tx_padding_required == 0 ) 
                                begin
                    tx_state <= TX_FRAME_CHECK_SEQUENCE2;
                      data_out = fcs_output_byte(tx_frame_check_sequence, 0);
                      update_fcs = FALSE;
                                end
                                else
                                begin 
                    tx_state <= TX_PAD;
                      data_out = PADDING_DATA;
                                end
                            end
                        end
            TX_PAD:
                        begin
            data_out = PADDING_DATA;
              update_fcs = TRUE;
                            if ( tx_padding_required == 0 ) 
                            begin
                tx_state <= TX_FRAME_CHECK_SEQUENCE2;
                  data_out = fcs_output_byte(tx_frame_check_sequence, 0);
                  update_fcs = FALSE;
                            end
                        end
            TX_FRAME_CHECK_SEQUENCE2:
                        begin
            tx_state <= tx_state+1;
              data_out = fcs_output_byte(tx_frame_check_sequence, 1);
                        end
            TX_FRAME_CHECK_SEQUENCE3:
                        begin
            tx_state <= tx_state+1;
              data_out = fcs_output_byte(tx_frame_check_sequence, 2);
                        end
            TX_FRAME_CHECK_SEQUENCE4:
                        begin
            tx_state <= TX_INTERPACKET_GAP;
              data_out = fcs_output_byte(tx_frame_check_sequence, 3);
              tx_interpacket_gap_counter <= 1'b0;
                        end
            TX_INTERPACKET_GAP:
                        begin
                            mii_tx_gap_o <= 1'b1;
              if (tx_interpacket_gap_counter == INTERPACKET_GAP_BYTES - 1)
                            begin
			       tx_fcs_o <= tx_frame_check_sequence;
                  tx_state <= TX_IDLE;
                            end
                            else
                            begin 
                tx_interpacket_gap_counter <= tx_interpacket_gap_counter + 1;
                            end
                        end
                        endcase
                        mii_tx_data_o <= data_out;
                        if ( update_fcs ) 
                        begin
                            tx_frame_check_sequence <= update_crc32(tx_frame_check_sequence,data_out);
                        end
if (((tx_state == TX_CLIENT_DATA_WAIT_SOURCE_ADDRESS | tx_state == TX_SOURCE_ADDRESS) | tx_state == TX_CLIENT_DATA) | tx_state == TX_PAD)
                        begin
                            if ( tx_padding_required > 0 ) 
                            begin
                tx_padding_required <= tx_padding_required - 1;
                            end
                        end
                    end
                end
            end
        end

    always @ ( posedge rx_clock_i)
  if (rx_reset_i ==  1'b1)
        begin
  rx_state <= RX_WAIT_START_FRAME_DELIMITER;

           rx_fcs_o <= 32'b0;
        end
        else
        begin 
            begin
                rx_error_o <= 1'b0;
                rx_data_o <= mii_rx_data_i;
                rx_byte_received_o <= 1'b0;
                rx_frame_o <= 1'b0;
                case ( rx_state ) 
    RX_WAIT_START_FRAME_DELIMITER:
                begin
                    rx_mac_address_byte <= 3'b000;
                    rx_is_group_address <= 1'b1;
                    rx_frame_check_sequence <= { 32{1'b1} };
                    if ( mii_rx_frame_i == 1'b1 ) 
                    begin
                       rx_frame_size <= 0;
		       rx_packet_length_o <= 0;
                       if ( mii_rx_byte_received_i == 1'b1 ) 
                         begin
                            case ( mii_rx_data_i ) 
                START_FRAME_DELIMITER_DATA:
                rx_state <= RX_DATA;
                
                PREAMBLE_DATA:
                begin end
                            default :
                rx_state <= RX_SKIP_FRAME;
                            endcase
                         end
                       if ( mii_rx_error_i == 1'b1 ) 
                         begin
            rx_state <= RX_SKIP_FRAME;
                         end
                    end
                end
    RX_DATA:
                begin
                    rx_frame_o <= 1'b1;
                    rx_byte_received_o <= mii_rx_byte_received_i;
                    if ( mii_rx_frame_i == 1'b0 ) 
                    begin
        rx_state <= RX_WAIT;

                        rx_padding <= 'b100;
		        rx_fcs_o <= rx_frame_check_sequence;
		        if ( rx_fcs_err == 0)
			  rx_packet_length_o <= rx_frame_size;
                        if ( ( ( ( mii_rx_error_i == 1'b1 ) |
 rx_fcs_err ) |
 ( rx_frame_size < MIN_FRAME_DATA_BYTES + CRC32_BYTES) |
 ( rx_frame_size > MAX_FRAME_DATA_BYTES + CRC32_BYTES ) ) )
                        begin
                          rx_error_o <= 1'b1;
                        end
                    end
                    else
                    begin 
                        if ( mii_rx_byte_received_i == 1'b1 ) 
                        begin
                            rx_frame_check_sequence <= update_crc32(rx_frame_check_sequence,mii_rx_data_i);
                            if ( rx_frame_size < 1500 + 2 + 6 + 6 + 4 + 1 ) 
                            begin
                              rx_frame_size <= rx_frame_size + 1;
                            end
                          if (rx_mac_address_byte < MAC_ADDRESS_BYTES)
                            begin
                                if ( rx_mac_address_byte == 3'b000 ) 
                                begin
                                    if ( ( mii_rx_data_i[0] == 1'b0 ) && ( promiscuous_i == 1'b0) )
                                    begin
                                        rx_is_group_address <= 1'b0;
                                        if ( mii_rx_data_i != extract_byte(mac_address_i,rx_mac_address_byte) ) 
                                        begin
                                          rx_state <= RX_ERROR;
                                        end
                                    end
                                end
                                else
                                begin 
                                    if ( rx_is_group_address == 1'b0 ) 
                                    begin
                                        if ( mii_rx_data_i != extract_byte(mac_address_i,rx_mac_address_byte) ) 
                                        begin
                                          rx_state <= RX_ERROR;
                                        end
                                    end
                                end
                                rx_mac_address_byte <= ( rx_mac_address_byte + 3'b001 );
                            end
                        end
                        if ( mii_rx_error_i == 1'b1 ) 
                        begin
            rx_state <= RX_ERROR;
                        end
                    end
                end
                RX_SKIP_FRAME:
                begin
                    if ( mii_rx_frame_i == 1'b0 ) 
                    begin
                      rx_state <= RX_WAIT_START_FRAME_DELIMITER;
                    end
                end
                RX_ERROR:
                begin
                    rx_frame_o <= 1'b1;
                    rx_error_o <= 1'b1;
                    if ( mii_rx_frame_i == 1'b0 ) 
                    begin
                      rx_state <= RX_WAIT_START_FRAME_DELIMITER;
                    end
                end
                RX_WAIT:
                begin
                    rx_frame_o <= 1'b1;
                    rx_byte_received_o <= mii_rx_byte_received_i;
                    if (rx_padding == 3'b000)
                      begin
                        rx_state <= RX_WAIT_START_FRAME_DELIMITER;
                      end
		    else if ( mii_rx_byte_received_i == 1'b1 ) 
                      begin
                        rx_padding <= rx_padding - 3'b001;
                        rx_frame_size <= rx_frame_size + 1;
                      end
                end
                endcase
            end
        end

endmodule 
