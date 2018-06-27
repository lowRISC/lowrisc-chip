//////////////////////////////////////////////////////////////////////
////                                                              ////
////  ps2.v                                                       ////
////                                                              ////
////  This file is part of the "ps2" project                      ////
////  http://www.opencores.org/cores/ps2/                         ////
////                                                              ////
////  Author(s):                                                  ////
////      - mihad@opencores.org                                   ////
////      - Miha Dolenc                                           ////
////                                                              ////
////  All additional information is avaliable in the README.txt   ////
////  file.                                                       ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Miha Dolenc, mihad@opencores.org          ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

module ps2(clk, rst,
           PS2_K_CLK_IO, PS2_K_DATA_IO, PS2_M_CLK_IO, PS2_M_DATA_IO,
           rx_scan_read, rx_released, rx_scan_ready, rx_scan_code, tx_error_no_keyboard_ack);

   input clk, rst;
   input rx_scan_read;

   inout PS2_K_CLK_IO;
   inout PS2_K_DATA_IO;
   inout PS2_M_CLK_IO;
   inout PS2_M_DATA_IO;

   output rx_scan_ready, rx_released, tx_error_no_keyboard_ack;
   output [7:0] rx_scan_code;

   wire             ps2_k_clk_en_o_ ;
   wire             ps2_k_data_en_o_ ;
   wire             ps2_k_clk_i ;
   wire             ps2_k_data_i ;

   wire             rx_released;
   wire [7:0]       rx_scan_code;
   wire             rx_scan_read;
   wire             rx_scan_ready;
   reg [7:0]        tx_data;
   reg              tx_write;
   wire             tx_write_ack_o;
   wire             tx_error_no_keyboard_ack;
   wire [15:0]      divide_reg = 13000;

   io_buffer_generic IOBUF_k_clk (
                          .outg(ps2_k_clk_i),     // Buffer output
                          .inoutg(PS2_K_CLK_IO),   // Buffer inout port (connect directly to top-level port)
                          .ing(ps2_k_clk_en_o_),     // Buffer input
                          .ctrl(ps2_k_clk_en_o_)      // 3-state enable input 
                          );

   io_buffer_generic IOBUF_k_data (
                           .outg(ps2_k_data_i),     // Buffer output
                           .inoutg(PS2_K_DATA_IO),   // Buffer inout port (connect directly to top-level port)
                           .ing(ps2_k_data_en_o_),     // Buffer input
                           .ctrl(ps2_k_data_en_o_)      // 3-state enable input 
                           );

   ps2_keyboard key1(
                     .clock_i(clk),
                     .reset_i(rst),
                     .ps2_clk_en_o_(ps2_k_clk_en_o_),
                     .ps2_data_en_o_(ps2_k_data_en_o_),
                     .ps2_clk_i(ps2_k_clk_i),
                     .ps2_data_i(ps2_k_data_i),
                     .rx_released(rx_released),
                     .rx_scan_code(rx_scan_code),
                     .rx_data_ready(rx_scan_ready),       // rx_read_o
                     .rx_read(rx_scan_read),             // rx_read_ack_i
                     .tx_data(tx_data),
                     .tx_write(tx_write),
                     .tx_write_ack_o(tx_write_ack_o),
                     .tx_error_no_keyboard_ack(tx_error_no_keyboard_ack),
                     .divide_reg_i(divide_reg)
                     );

   wire ps2_m_clk_en_o_ ;
   wire ps2_m_data_en_o_ ;
   wire ps2_m_clk_i ;
   wire ps2_m_data_i ;

   io_buffer_generic IOBUF_m_clk (
                          .outg(ps2_m_clk_i),     // Buffer output
                          .inoutg(PS2_M_CLK_IO),   // Buffer inout port (connect directly to top-level port)
                          .ing(ps2_m_clk_en_o_),     // Buffer input
                          .ctrl(ps2_m_clk_en_o_)      // 3-state enable input 
                          );

   io_buffer_generic IOBUF_m_data (
                           .outg(ps2_m_data_i),     // Buffer output
                           .inoutg(PS2_M_DATA_IO),   // Buffer inout port (connect directly to top-level port)
                           .ing(ps2_m_data_en_o_),     // Buffer input
                           .ctrl(ps2_m_data_en_o_)      // 3-state enable input 
                           );

endmodule
