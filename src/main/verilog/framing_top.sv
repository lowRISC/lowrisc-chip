// See LICENSE for license details.
`default_nettype none

module framing_top
  (
  input wire rstn, msoc_clk, clk_rmii,
  input wire [12:0] core_lsu_addr,
  input wire [31:0] core_lsu_wdata,
  input wire [3:0] core_lsu_be,
  input wire       ce_d,
  input wire   we_d,
  input wire framing_sel,
  output logic [31:0] framing_rdata,

  //! Ethernet MAC PHY interface signals
output wire   o_edutrefclk     , // RMII clock out
input wire [1:0] i_edutrxd    ,
input wire  i_edutrx_dv       ,
input wire  i_edutrx_er       ,
output reg  [1:0] o_eduttxd   ,
output reg   o_eduttx_en      ,
output wire   o_edutmdc        ,
input wire i_edutmdio ,
output reg  o_edutmdio   ,
output reg  oe_edutmdio   ,
output wire   o_edutrstn    ,   

output reg eth_irq
   );

logic [12:0] core_lsu_addr_dly;   

logic tx_enable_i, tx_byte_sent_o, tx_busy_o, rx_frame_o, rx_byte_received_o, rx_error, rx_error_o;
logic mac_tx_enable, mac_tx_gap, mac_tx_byte_sent, mac_rx_frame, mac_rx_byte_received, mac_rx_error;
logic [47:0] mac_address;
logic  [7:0] rx_data_o1, rx_data_o2, rx_data_o3, rx_data_o, tx_data_i, mac_tx_data, mac_rx_data, mii_rx_data_i;
logic [10:0] rx_frame_size_o, tx_frame_addr, rx_packet_length, rx_packet_length_o;
logic [15:0] tx_packet_length, tx_frame_size;
logic        ce_d_dly, rx_fcs_err, rx_fcs_err_o;
logic [31:0] framing_rdata_pkt, framing_wdata_pkt, tx_fcs_o, rx_fcs_o;
logic [3:0] framing_rdata_pa, tx_enable_dly;

reg [12:0] addr_tap, nxt_addr;
reg [23:0] rx_byte, rx_nxt, rx_byte_dly;
reg  [2:0] rx_pair;
reg        mii_rx_byte_received_i, full, byte_sync, sync, irq_en, mii_rx_frame_i, rx_frame_old, rx_pa;

   wire [3:0] m_enb = (we_d ? core_lsu_be : 4'hF);
   logic edutmdio, o_edutmdclk, o_edutrst, cooked, tx_enable_old, loopback, loopback2, promiscuous;
   logic [1:0] data_dly;   
   logic [10:0] rx_addr;
   logic [7:0] rx_data;
   logic rx_ena, rx_wea;

   always @(posedge clk_rmii)
     if (rstn == 1'b0)
       begin
	  byte_sync = 1'b0;
	  addr_tap <= 'H0;
	  rx_byte_dly <= {8{3'H1}};
       end
     else
       begin
	  mii_rx_byte_received_i <= 0;
	  rx_pair <= loopback ? {o_eduttx_en,o_eduttxd} : {i_edutrx_dv,i_edutrxd[1:0]};
	  full = &addr_tap;
	  rx_nxt = {rx_pair,rx_byte[23:3]};
	  rx_byte <= rx_nxt;
	  if ((rx_nxt == {3'H7,{7{3'H5}}}) && (byte_sync == 0) && (sync == 0))
            begin
               byte_sync <= 1'b1;
               mii_rx_byte_received_i <= 1'b1;
               addr_tap <= {addr_tap[12:2],2'b00};
            end
	  else
            begin
               if (full == 0)
		 begin
                    nxt_addr = addr_tap+1;
                    addr_tap <= byte_sync ? nxt_addr : nxt_addr&3;
		 end
               mii_rx_byte_received_i <= &addr_tap[1:0];
            end
	  if (mii_rx_byte_received_i)
	    begin
	       rx_byte_dly <= byte_sync ? rx_byte : {8{3'H1}};
               mii_rx_frame_i <= rx_byte_dly[2];
	       mii_rx_data_i <= {rx_byte_dly[10:9],rx_byte_dly[7:6],rx_byte_dly[4:3],rx_byte_dly[1:0]};
            end
	  if (( rx_frame_o == 1'b0 ) && ( rx_frame_old == 1'b1 ))
	    begin
	       if (cooked)
		 begin
		    byte_sync = 1'b0;
		    addr_tap <= 'H0;
		 end
	    end
	  rx_frame_old = rx_frame_o;
       end

   assign mac_tx_byte_sent = &tx_frame_size[1:0];
   assign tx_frame_addr = tx_frame_size[12:2] - 7;
   
   framing framing_inst_0 (
			.rx_reset_i             ( ~rstn ),
			.tx_clock_i             ( clk_rmii ),
			.tx_reset_i             ( ~rstn ),
			.rx_clock_i             ( clk_rmii ),
			.mac_address_i          ( mac_address ),
			.tx_enable_i            ( tx_enable_i ),
			.tx_data_i              ( tx_data_i ),
			.tx_byte_sent_o         ( tx_byte_sent_o ),
			.tx_busy_o              ( tx_busy_o ),
			.tx_fcs_o               ( tx_fcs_o ),
			.rx_frame_o             ( rx_frame_o ),
			.rx_data_o              ( rx_data_o ),
			.rx_byte_received_o     ( rx_byte_received_o ),
			.rx_error_o             ( rx_error_o ),
			.rx_frame_size_o        ( rx_frame_size_o ),
			.rx_packet_length_o     ( rx_packet_length_o ),
			.rx_fcs_o               ( rx_fcs_o ),
			.rx_fcs_err_o           ( rx_fcs_err_o ),
			.mii_tx_enable_o        ( mac_tx_enable ),
			.mii_tx_gap_o           ( mac_tx_gap ),
			.mii_tx_data_o          ( mac_tx_data ),
			.mii_tx_byte_sent_i     ( mac_tx_byte_sent ),
			.mii_rx_frame_i         ( mii_rx_frame_i ),
			.mii_rx_data_i          ( mii_rx_data_i ),
			.mii_rx_byte_received_i ( mii_rx_byte_received_i ),
			.mii_rx_error_i         ( loopback ? 1'b0 : i_edutrx_er ),
                        .promiscuous_i          ( promiscuous )
		);

   always @(posedge clk_rmii)
     if (rstn == 0)
       begin
       tx_frame_size <= 0;
       o_eduttxd <= 0;
       o_eduttx_en <= 0;
       end
     else
       begin
       o_eduttx_en = mac_tx_enable & ~mac_tx_gap;
	   if (tx_enable_i & (tx_enable_old == 0))
	     tx_frame_size <= 0;
	   if (tx_busy_o)
            begin
               tx_frame_size <= tx_frame_size + 1;
	       o_eduttxd <= mac_tx_data >> {tx_frame_size[1:0],1'b0};
            end
	   tx_enable_old <= tx_enable_i;
       end

   always @(posedge clk_rmii) if (rx_byte_received_o)
     begin
	rx_data_o3 <= rx_data_o2;
	rx_data_o2 <= rx_data_o1;
	rx_data_o1 <= cooked ? rx_data_o : mii_rx_data_i;
     end
   
   always @* casez({loopback2,cooked})
     2'b1?: begin
	rx_addr = tx_frame_size[12:2];
	rx_data = mac_tx_data;
	rx_ena = tx_busy_o;
	rx_wea = mac_tx_byte_sent;
	rx_pa = 1'b0;
        end
     2'b01: begin
	rx_addr = rx_frame_size_o;
	casez(data_dly)
	  2'b00: rx_data = rx_data_o;
	  2'b01: rx_data = rx_data_o1;
	  2'b10: rx_data = rx_data_o2;
	  2'b11: rx_data = rx_data_o3;
	endcase
	rx_ena = rx_frame_o;
	rx_wea = rx_byte_received_o;
	rx_pa = 1'b0;
        end
     2'b00: begin
	rx_addr = addr_tap[12:2];
	rx_data = rx_data_o3;
	rx_ena = full==0;
	rx_wea = mii_rx_byte_received_i;
	rx_pa = mii_rx_frame_i;
        end
     endcase
           
   RAMB16_S9_S36 RAMB16_S1_inst_rx (
                                    .CLKA(clk_rmii),               // Port A Clock
                                    .CLKB(msoc_clk),              // Port A Clock
                                    .DOA(),                       // Port A 9-bit Data Output
                                    .ADDRA(rx_addr),              // Port A 11-bit Address Input
                                    .DIA(rx_data),                // Port A 8-bit Data Input
                                    .DIPA(rx_pa),                 // Port A parity unused
                                    .SSRA(1'b0),                  // Port A Synchronous Set/Reset Input
                                    .ENA(rx_ena),                 // Port A RAM Enable Input
                                    .WEA(rx_wea),                 // Port A Write Enable Input
                                    .DOB(framing_rdata_pkt),          // Port B 32-bit Data Output
                                    .DOPB(framing_rdata_pa),          // Port B parity unused
                                    .ADDRB(core_lsu_addr[10:2]),  // Port B 9-bit Address Input
                                    .DIB(core_lsu_wdata),         // Port B 32-bit Data Input
                                    .DIPB(4'b0),                  // Port B parity unused
                                    .ENB(ce_d & framing_sel & (1'b0 == ^core_lsu_addr[12:11])),
                                                                  // Port B RAM Enable Input
                                    .SSRB(1'b0),                  // Port B Synchronous Set/Reset Input
                                    .WEB(we_d)                    // Port B Write Enable Input
                                    );

   RAMB16_S9_S36 RAMB16_S1_inst_tx (
                                   .CLKA(clk_rmii),               // Port A Clock
                                   .CLKB(msoc_clk),              // Port A Clock
                                   .DOA(tx_data_i),              // Port A 9-bit Data Output
                                   .ADDRA(tx_frame_addr),        // Port A 11-bit Address Input
                                   .DIA(8'b0),                   // Port A 8-bit Data Input
                                   .DIPA(1'b0),                  // Port A parity unused
                                   .SSRA(1'b0),                  // Port A Synchronous Set/Reset Input
                                   .ENA(tx_enable_i),            // Port A RAM Enable Input
                                   .WEA(1'b0),                   // Port A Write Enable Input
                                   .DOB(framing_wdata_pkt),          // Port B 32-bit Data Output
                                   .DOPB(),                      // Port B parity unused
                                   .ADDRB(core_lsu_addr[10:2]),  // Port B 9-bit Address Input
                                   .DIB(core_lsu_wdata),         // Port B 32-bit Data Input
                                   .DIPB(4'b0),                  // Port B parity unused
                                   .ENB(ce_d & framing_sel & (core_lsu_addr[12:11]==2'b10)),
				                                 // Port B RAM Enable Input
                                   .SSRB(1'b0),                  // Port B Synchronous Set/Reset Input
                                   .WEB(we_d)                    // Port B Write Enable Input
                                   );

assign o_edutmdc = o_edutmdclk;
assign o_edutrefclk = clk_rmii; // was i_clk50_quad;

always @(posedge msoc_clk)
  if (!rstn)
    begin
    core_lsu_addr_dly <= 0;
    mac_address <= 48'H230100890702;
    tx_packet_length <= 0;
    tx_enable_dly <= 0;
    cooked <= 1'b0;
    loopback <= 1'b0;
    loopback2 <= 1'b0;
    promiscuous <= 1'b0;
    oe_edutmdio <= 1'b0;
    o_edutmdio <= 1'b0;
    o_edutmdclk <= 1'b0;
    o_edutrst <= 1'b0;
    sync <= 1'b0;
    eth_irq <= 1'b0;
    irq_en <= 1'b0;
    ce_d_dly <= 1'b0;
    data_dly <= 2'b00;
    end
  else
    begin
    core_lsu_addr_dly <= core_lsu_addr;
    edutmdio <= i_edutmdio;
    ce_d_dly <= ce_d;
    eth_irq <= sync & irq_en; // make eth_irq go away immediately if irq_en is low
    if (framing_sel&we_d&core_lsu_addr[11])
      case(core_lsu_addr[5:2])
        0: mac_address[31:0] <= core_lsu_wdata;
        1: {irq_en,promiscuous,data_dly,loopback2,loopback,cooked,mac_address[47:32]} <= core_lsu_wdata;
        2: begin tx_enable_dly <= 10; tx_packet_length <= core_lsu_wdata+6; end
        3: begin tx_enable_dly <= 0; tx_packet_length <= 0; end
        4: begin {o_edutrst,oe_edutmdio,o_edutmdio,o_edutmdclk} <= core_lsu_wdata; end
        6: begin sync = 0; end
      endcase
       if (byte_sync & (~rx_pair[2]) & ~sync)
         begin
            sync = 1'b1;
            rx_error <= rx_error_o;
            rx_fcs_err <= rx_fcs_err_o;
            rx_packet_length <= rx_packet_length_o;
         end
       if (tx_busy_o && (tx_frame_size[12:2] > tx_packet_length))
         begin
            tx_enable_dly <= 0;
         end
       else if (1'b1 == |tx_enable_dly)
         tx_enable_dly <= tx_enable_dly + 1'b1;
    end
   
always @(posedge clk_rmii)
  if (!rstn)
    begin
    tx_enable_i <= 1'b0;
    end
  else
    begin
    if (tx_busy_o && (tx_frame_size[12:2] > tx_packet_length))
       begin
       tx_enable_i <= 1'b0;
       end
    else if (1'b1 == &tx_enable_dly)
         tx_enable_i <= 1'b1;
    end

   always @* casez({ce_d_dly,core_lsu_addr_dly[12:2]})
    12'b101??????000 : framing_rdata = mac_address[31:0];
    12'b101??????001 : framing_rdata = {irq_en, promiscuous, data_dly, loopback2, loopback, cooked, mac_address[47:32]};
    12'b101??????010 : framing_rdata = {tx_busy_o, 4'b0, tx_frame_addr, tx_packet_length};
    12'b101??????011 : framing_rdata = {tx_fcs_o};
    12'b101??????100 : framing_rdata = {i_edutmdio,oe_edutmdio,o_edutmdio,o_edutmdclk};
    12'b101??????101 : framing_rdata = {rx_fcs_o};
    12'b101??????110 : framing_rdata = {eth_irq, sync};
    12'b101??????111 : framing_rdata = {rx_fcs_err, rx_error, 3'b0, rx_frame_size_o, 5'b0, rx_packet_length};
    12'b100????????? : framing_rdata = framing_rdata_pkt;
    12'b110????????? : framing_rdata = framing_wdata_pkt;
    12'b111????????? : framing_rdata = framing_rdata_pa;
    default: framing_rdata = 'h0;
    endcase

   assign o_edutrstn = ~o_edutrst;
  
endmodule // framing_top
`default_nettype wire
