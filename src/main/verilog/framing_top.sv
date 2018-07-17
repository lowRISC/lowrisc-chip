// See LICENSE for license details.
`default_nettype none

module framing_top
  (
  input wire rstn, msoc_clk, clk_rmii,
  input wire [14:0] core_lsu_addr,
  input wire [63:0] core_lsu_wdata,
  input wire [7:0] core_lsu_be,
  input wire       ce_d,
  input wire   we_d,
  input wire framing_sel,
  output logic [63:0] framing_rdata,

  //! Ethernet MAC PHY interface signals
output wire   o_erefclk     , // RMII clock out
input wire [1:0] i_erxd    ,
input wire  i_erx_dv       ,
input wire  i_erx_er       ,
output wire [1:0] o_etxd   ,
output wire o_etx_en      ,
output wire   o_emdc        ,
input wire i_emdio ,
output reg  o_emdio   ,
output reg  oe_emdio   ,
output wire   o_erstn    ,   

output reg eth_irq
   );

logic [14:0] core_lsu_addr_dly;   

logic tx_enable_i;
logic [47:0] mac_address, rx_dest_mac;
logic  [7:0] mii_rx_data_i;
logic [10:0] tx_frame_addr, rx_length_axis[0:7], tx_packet_length;
logic [12:0] axis_tx_frame_size;
logic        ce_d_dly, avail;
logic [63:0] framing_rdata_pkt, framing_wdata_pkt;
logic [3:0] tx_enable_dly, firstbuf, nextbuf, lastbuf;

reg [12:0] addr_tap, nxt_addr;
reg [23:0] rx_byte, rx_nxt, rx_byte_dly;
reg  [2:0] rx_pair;
reg        mii_rx_byte_received_i, full, byte_sync, sync, irq_en, mii_rx_frame_i, tx_busy;

   wire [7:0] m_enb = (we_d ? core_lsu_be : 8'hFF);
   logic emdio, o_emdclk, o_erst, cooked, tx_enable_old, loopback, promiscuous;
   logic [3:0] spare;   
   logic [10:0] rx_addr_axis;
   
       /*
        * AXI input
        */
        reg         tx_axis_tvalid;
        reg         tx_axis_tvalid_dly;
        reg 	    tx_axis_tlast;
        wire [7:0]  tx_axis_tdata;
        wire        tx_axis_tready;
        wire        tx_axis_tuser = 0;
   
       /*
        * AXI output
        */
       wire [7:0]  rx_axis_tdata;
       wire        rx_axis_tvalid;
       wire        rx_axis_tlast;
       wire        rx_axis_tuser;
   
       /*
        * GMII interface
        */
        wire        gmii_rx_er = loopback ? 1'b0 : i_erx_er;
        wire [7:0]  gmii_txd;
        wire        gmii_tx_en;
        wire        gmii_tx_er;
      /*
        * AXIS Status
        */
         wire        axis_error_bad_frame;
         wire        axis_error_bad_fcs;
         wire [31:0] tx_fcs_reg_rev, rx_fcs_reg_rev;
   
   always @(posedge clk_rmii)
     if (rstn == 1'b0)
       begin
	  byte_sync <= 1'b0;
	  addr_tap <= 'H0;
	  rx_byte_dly <= {8{3'H1}};
       end
     else
       begin
	  mii_rx_byte_received_i <= 0;
	  rx_pair <= loopback ? {o_etx_en,o_etxd} : {i_erx_dv,i_erxd[1:0]};
	  full = &addr_tap;
	  rx_nxt = {rx_pair,rx_byte[23:3]};
	  rx_byte <= rx_nxt;
	  if ((rx_nxt == {3'H7,{7{3'H5}}}) && (byte_sync == 0) && (nextbuf != (firstbuf+lastbuf)&15))
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
	  if (rx_axis_tlast)
            begin
	       byte_sync <= 1'b0;
	       addr_tap <= 'H0;
            end
       end

   always @(posedge clk_rmii)
       tx_enable_old <= tx_enable_i;

   logic [1:0] rx_wr = rx_axis_tvalid << rx_addr_axis[2];
   logic [15:0] douta;
   assign tx_axis_tdata = douta >> {tx_frame_addr[2],3'b000};
   
   dualmem_widen8 RAMB16_inst_rx (
                                    .clka(clk_rmii),              // Port A Clock
                                    .clkb(msoc_clk),              // Port A Clock
                                    .douta(),                     // Port A 8-bit Data Output
                                    .addra({nextbuf[2:0],rx_addr_axis[10:3],rx_addr_axis[1:0]}),    // Port A 11-bit Address Input
                                    .dina({rx_axis_tdata,rx_axis_tdata}), // Port A 8-bit Data Input
                                    .ena(rx_axis_tvalid),         // Port A RAM Enable Input
                                    .wea(rx_wr),                  // Port A Write Enable Input
                                    .doutb(framing_rdata_pkt),    // Port B 32-bit Data Output
                                    .addrb(core_lsu_addr[13:3]),  // Port B 9-bit Address Input
                                    .dinb(core_lsu_wdata),        // Port B 32-bit Data Input
                                    .enb(ce_d & framing_sel & core_lsu_addr[14]),
                                                                  // Port B RAM Enable Input
                                    .web(we_d ? {(|core_lsu_be[7:4]),(|core_lsu_be[3:0])} : 2'b0) // Port B Write Enable Input
                                    );

    dualmem_widen RAMB16_inst_tx (
                                   .clka(~clk_rmii),             // Port A Clock
                                   .clkb(msoc_clk),              // Port A Clock
                                   .douta(douta),                // Port A 8-bit Data Output
                                   .addra({1'b0,tx_frame_addr[10:3],tx_frame_addr[1:0]}),  // Port A 11-bit Address Input
                                   .dina(16'b0),                 // Port A 8-bit Data Input
                                   .ena(tx_axis_tvalid),         // Port A RAM Enable Input
                                   .wea(2'b0),                  // Port A Write Enable Input
                                   .doutb(framing_wdata_pkt),    // Port B 32-bit Data Output
                                   .addrb(core_lsu_addr[11:3]),  // Port B 9-bit Address Input
                                   .dinb(core_lsu_wdata), // Port B 32-bit Data Input
                                   .enb(ce_d & framing_sel & (core_lsu_addr[14:12]==3'b001)),
				                                 // Port B RAM Enable Input
                                   .web(we_d ? {(|core_lsu_be[7:4]),(|core_lsu_be[3:0])} : 2'b0) // Port B Write Enable Input
                                   );

assign o_emdc = o_emdclk;
assign o_erefclk = clk_rmii; // was i_clk50_quad;

always @(posedge msoc_clk)
  if (!rstn)
    begin
    core_lsu_addr_dly <= 0;
    mac_address <= 48'H230100890702;
    tx_packet_length <= 0;
    tx_enable_dly <= 0;
    cooked <= 1'b0;
    loopback <= 1'b0;
    spare <= 4'b0;
    promiscuous <= 1'b0;
    oe_emdio <= 1'b0;
    o_emdio <= 1'b0;
    o_emdclk <= 1'b0;
    o_erst <= 1'b0;
    sync <= 1'b0;
    firstbuf <= 4'b0;
    lastbuf <= 4'b0;
    nextbuf <= 4'b0;
    eth_irq <= 1'b0;
    irq_en <= 1'b0;
    ce_d_dly <= 1'b0;
    tx_busy <= 1'b0;
    avail = 1'b0;         
    end
  else
    begin
    core_lsu_addr_dly <= core_lsu_addr;
    emdio <= i_emdio;
    ce_d_dly <= ce_d;
    avail = nextbuf != firstbuf;
    eth_irq <= avail & irq_en; // make eth_irq go away immediately if irq_en is low
    if (framing_sel&we_d&(core_lsu_addr[14:11]==4'b0001))
      case(core_lsu_addr[6:3])
        0: mac_address[31:0] <= core_lsu_wdata;
        1: {irq_en,promiscuous,spare,loopback,cooked,mac_address[47:32]} <= core_lsu_wdata;
        2: begin tx_enable_dly <= 10; tx_packet_length <= core_lsu_wdata; end /* tx payload size */
        3: begin tx_enable_dly <= 0; tx_packet_length <= 0; end
        4: begin {o_erst,oe_emdio,o_emdio,o_emdclk} <= core_lsu_wdata; end
        5: begin lastbuf <= core_lsu_wdata[3:0]; end
        6: begin firstbuf <= core_lsu_wdata[3:0]; end
      endcase
       if (byte_sync & (~rx_pair[2]) & ~sync)
         begin
         // check broadcast/multicast address
	     sync <= (rx_dest_mac[47:24]==24'h01005E) | (&rx_dest_mac) | (mac_address == rx_dest_mac) | promiscuous;
         end
       else if (~byte_sync)
         begin
         if (sync) nextbuf <= nextbuf + 1'b1;
         sync <= 1'b0;
         end
       if (gmii_tx_en && tx_axis_tlast)
         begin
            tx_enable_dly <= 0;
         end
       else if (1'b1 == |tx_enable_dly)
         begin
         tx_busy <= 1'b1;
         tx_enable_dly <= tx_enable_dly + 1'b1;
         end
       else if (~gmii_tx_en)
         tx_busy <= 1'b0;         
    end

always @(posedge clk_rmii)
  if (!rstn)
    begin
    tx_enable_i <= 1'b0;
    end
  else
    begin
    if (gmii_tx_en && tx_axis_tlast)
       begin
       tx_enable_i <= 1'b0;
       end
    else if (1'b1 == &tx_enable_dly)
         tx_enable_i <= 1'b1;
    end

   always @* casez({ce_d_dly,core_lsu_addr_dly[14:3]})
    13'b10001????0000 : framing_rdata = mac_address[31:0];
    13'b10001????0001 : framing_rdata = {irq_en, promiscuous, spare, loopback, cooked, mac_address[47:32]};
    13'b1000?????0010 : framing_rdata = {tx_busy, 4'b0, tx_frame_addr, 5'b0, tx_packet_length};
    13'b10001????0011 : framing_rdata = tx_fcs_reg_rev;
    13'b10001????0100 : framing_rdata = {i_emdio,oe_emdio,o_emdio,o_emdclk};
    13'b10001????0101 : framing_rdata = rx_fcs_reg_rev;
    13'b10001????0110 : framing_rdata = {eth_irq, avail, lastbuf, nextbuf, firstbuf};
    13'b10001????1??? : framing_rdata = rx_length_axis[core_lsu_addr_dly[5:3]];
    13'b10010???????? : framing_rdata = framing_wdata_pkt;
    13'b11??????????? : framing_rdata = framing_rdata_pkt;
    default: framing_rdata = 'h0;
    endcase

   assign o_erstn = ~o_erst;
  
   parameter dly = 0;
   
   reg [1:0] 	    axis_etxd ;
   reg 		    axis_etx_en;
   reg [31:0] 	    tx_fcs_reg, rx_fcs_reg;
   assign 	    tx_fcs_reg_rev = {tx_fcs_reg[0],tx_fcs_reg[1],tx_fcs_reg[2],tx_fcs_reg[3],
                                          tx_fcs_reg[4],tx_fcs_reg[5],tx_fcs_reg[6],tx_fcs_reg[7],
                                          tx_fcs_reg[8],tx_fcs_reg[9],tx_fcs_reg[10],tx_fcs_reg[11],
                                          tx_fcs_reg[12],tx_fcs_reg[13],tx_fcs_reg[14],tx_fcs_reg[15],
                                          tx_fcs_reg[16],tx_fcs_reg[17],tx_fcs_reg[18],tx_fcs_reg[19],
                                          tx_fcs_reg[20],tx_fcs_reg[21],tx_fcs_reg[22],tx_fcs_reg[23],
                                          tx_fcs_reg[24],tx_fcs_reg[25],tx_fcs_reg[26],tx_fcs_reg[27],
                                          tx_fcs_reg[28],tx_fcs_reg[29],tx_fcs_reg[30],tx_fcs_reg[31]};
   assign 	    rx_fcs_reg_rev = {rx_fcs_reg[0],rx_fcs_reg[1],rx_fcs_reg[2],rx_fcs_reg[3],
                                          rx_fcs_reg[4],rx_fcs_reg[5],rx_fcs_reg[6],rx_fcs_reg[7],
                                          rx_fcs_reg[8],rx_fcs_reg[9],rx_fcs_reg[10],rx_fcs_reg[11],
                                          rx_fcs_reg[12],rx_fcs_reg[13],rx_fcs_reg[14],rx_fcs_reg[15],
                                          rx_fcs_reg[16],rx_fcs_reg[17],rx_fcs_reg[18],rx_fcs_reg[19],
                                          rx_fcs_reg[20],rx_fcs_reg[21],rx_fcs_reg[22],rx_fcs_reg[23],
                                          rx_fcs_reg[24],rx_fcs_reg[25],rx_fcs_reg[26],rx_fcs_reg[27],
                                          rx_fcs_reg[28],rx_fcs_reg[29],rx_fcs_reg[30],rx_fcs_reg[31]};
   wire axis_tx_byte_sent = &axis_tx_frame_size[1:0];
   
   always @(posedge clk_rmii)
     if (~rstn)
       begin
          rx_addr_axis <= 'b0;
          tx_axis_tvalid <= 'b0;
	  axis_tx_frame_size <= 0;
	  axis_etxd <= 'b0;
	  axis_etx_en <= 'b0;
	  tx_axis_tvalid_dly <= 'b0;
	  tx_frame_addr <= 'b0;
	  tx_axis_tlast <= 'b0;
          rx_dest_mac <= 'b0;
       end
     else
       begin
	  axis_etx_en <= gmii_tx_en;
	  if (tx_enable_i & (tx_enable_old == 0))
	    begin
	       axis_tx_frame_size <= 'b0;
	       tx_frame_addr <= 'b0;
	    end
	  else if (1'b0 == &axis_tx_frame_size)
            begin
               axis_tx_frame_size <= axis_tx_frame_size + 1;
	       axis_etxd <= gmii_txd >> {axis_tx_frame_size[1:0],1'b0};
            end
	  if (tx_axis_tready)
	    begin
	       tx_frame_addr <= tx_frame_addr + 1;
	       tx_axis_tlast <= (tx_frame_addr == tx_packet_length-2) & tx_axis_tvalid_dly;
	    end
          if (axis_tx_byte_sent)
	    begin
	       tx_axis_tvalid <= tx_axis_tvalid_dly;
	       if (tx_enable_old)
		 tx_axis_tvalid_dly <= 1'b1;
	       else if (~tx_axis_tlast)
		 tx_axis_tvalid_dly <= 1'b0;
	    end
	  if (rx_axis_tvalid)
            begin
            rx_addr_axis <= rx_addr_axis + 1;
            if (rx_addr_axis < 6)
              rx_dest_mac <= {rx_dest_mac[39:0],rx_axis_tdata};
            end
	  if (rx_axis_tlast)
            begin
	        rx_length_axis[nextbuf[2:0]] <= rx_addr_axis + 1;
	        rx_addr_axis <= 'b0;
            end
      end
 
   axis_gmii_rx gmii_rx_inst (
       .clk(clk_rmii),
       .rst(~rstn),
       .mii_select(1'b0),
       .clk_enable(mii_rx_byte_received_i),
       .gmii_rxd(mii_rx_data_i),
       .gmii_rx_dv(mii_rx_frame_i),
       .gmii_rx_er(gmii_rx_er),
       .output_axis_tdata(rx_axis_tdata),
       .output_axis_tvalid(rx_axis_tvalid),
       .output_axis_tlast(rx_axis_tlast),
       .output_axis_tuser(rx_axis_tuser),
       .error_bad_frame(axis_error_bad_frame),
       .error_bad_fcs(axis_error_bad_fcs),
       .fcs_reg(rx_fcs_reg)
   );
   
   axis_gmii_tx #(
       .ENABLE_PADDING(1),
       .MIN_FRAME_LENGTH(64)
   )
   gmii_tx_inst (
       .clk(clk_rmii),
       .rst(~rstn),
       .mii_select(1'b0),
       .clk_enable(axis_tx_byte_sent),
       .input_axis_tdata(tx_axis_tdata),
       .input_axis_tvalid(tx_axis_tvalid),
       .input_axis_tready(tx_axis_tready),
       .input_axis_tlast(tx_axis_tlast),
       .input_axis_tuser(tx_axis_tuser),
       .gmii_txd(gmii_txd),
       .gmii_tx_en(gmii_tx_en),
       .gmii_tx_er(gmii_tx_er),
       .ifg_delay(8'd12),
       .fcs_reg(tx_fcs_reg)
   );

   assign o_etxd = axis_etxd;
   assign o_etx_en = axis_etx_en;
   
endmodule // framing_top
`default_nettype wire
