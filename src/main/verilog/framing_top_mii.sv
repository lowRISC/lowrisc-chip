// See LICENSE for license details.
`default_nettype none

module framing_top_mii
  (
  input wire          i_erx_clk,
  input wire          i_etx_clk,
  input wire rstn, msoc_clk, clk_mii,
  input wire [14:0] core_lsu_addr,
  input wire [63:0] core_lsu_wdata,
  input wire [7:0] core_lsu_be,
  input wire       ce_d,
  input wire   we_d,
  input wire framing_sel,
  output logic [63:0] framing_rdata,

  //! Ethernet MAC PHY interface signals
output wire   o_erefclk     , // MII clock out
input wire [3:0] i_erxd    ,
input wire  i_erx_dv       ,
input wire  i_erx_er       ,
output wire [3:0] o_etxd   ,
output wire o_etx_en      ,
output wire o_etx_er      ,
output wire   o_emdc        ,
input wire i_emdio ,
output reg  o_emdio   ,
output reg  oe_emdio   ,
output wire   o_erstn    ,   

output reg eth_irq
   );

logic [3:0] etxd;
logic etx_en, etx_wren, erx_wren;
logic etx_er;
logic [14:0] core_lsu_addr_dly;   
logic [25:0] rdummy26, tdummy26;
   
logic tx_enable_i;
logic [47:0] mac_address, rx_dest_mac;
logic  [7:0] mii_rx_data_i;
logic [10:0] tx_frame_addr, rx_length_axis[0:7], tx_packet_length;
logic        ce_d_dly, avail;
logic [63:0] framing_rdata_pkt, framing_wdata_pkt;
logic [3:0] tx_enable_dly, firstbuf, nextbuf, oldbuf, newbuf;   

reg [12:0] nxt_addr;
reg        sync, irq_en, tx_busy, oldsync;

   wire [7:0] m_enb = (we_d ? core_lsu_be : 8'hFF);
   logic emdio, o_emdclk, o_erst, cooked, loopback, promiscuous;
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
        reg [3:0]   gmii_rxd;
        reg         gmii_rx_er;
        reg         gmii_rx_dv;
      /*
        * AXIS Status
        */
         wire        axis_error_bad_frame;
         wire        axis_error_bad_fcs;
         wire [31:0] tx_fcs_reg_rev, rx_fcs_reg_rev;

   logic  [15:0] douta;
   wire [3:0]   tx_padding;   
   
   logic  [15:0] dina;
   logic  [12:0] addra;
   logic   [1:0] wea;
   logic         ena;
   logic         full;
   logic         rx_empty, rx_almost_empty, rx_rd_en;
   
     FIFO18E1 #(
                .ALMOST_EMPTY_OFFSET(13'h5),       // Sets the almost empty threshold
                .ALMOST_FULL_OFFSET(13'h0080),     // Sets almost full threshold
                .DATA_WIDTH(9),                    // Sets data width to 4-36
                .DO_REG(1),                        // Enable output register (1-0) Must be 1 if EN_SYN = FALSE
                .EN_SYN("FALSE"),                  // Specifies FIFO as dual-clock (FALSE) or Synchronous (TRUE)
                .FIFO_MODE("FIFO18"),              // Sets mode to FIFO18 or FIFO18_36
                .FIRST_WORD_FALL_THROUGH("FALSE"), // Sets the FIFO FWFT to FALSE, TRUE
                .INIT(36'h000000000),              // Initial values on output port
                .SIM_DEVICE("7SERIES"),            // Must be set to "7SERIES" for simulation behavior
                .SRVAL(36'h000000000)              // Set/Reset value for output port
                )
      rx_fifo (
                        // Read Data: 32-bit (each) output: Read output data
                        .DO({rdummy26,gmii_rx_er,gmii_rx_dv,gmii_rxd}), // 32-bit output: Data output
                        // Status: 1-bit (each) output: Flags and other FIFO status outputs
                        .ALMOSTEMPTY(rx_almost_empty),// 1-bit output: Almost empty flag
                        .EMPTY(rx_empty),          // 1-bit output: Empty flag
                        // Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
                        .RDCLK(clk_mii),           // 1-bit input: Read clock
                        .RDEN(rx_rd_en),           // 1-bit input: Read enable
                        .REGCE(1'b1),              // 1-bit input: Clock enable
                        .RST(!rstn),               // 1-bit input: Asynchronous Reset
                        .RSTREG(1'b0),             // 1-bit input: Output register set/reset
                        // Write Control Signals: 1-bit (each) input: Write clock and enable input signals
                        .WRCLK(i_erx_clk),         // 1-bit input: Write clock
                        .WREN(erx_wren),           // 1-bit input: Write enable
                        // Write Data: 32-bit (each) input: Write input data
                        .DI(loopback ? {26'b0,o_etx_er,o_etx_en,o_etxd} : {26'b0,i_erx_er,i_erx_dv,i_erxd}),                   // 32-bit input: Data input
                        .DIP(4'b0)                 // 4-bit input: Parity input
                        );

   always @(posedge clk_mii)
     if (rstn == 1'b0)
       begin
          ena <= 1'b0;
          wea <= 2'b00;
          dina <= 'b0;
          addra <= 'b0;
          rx_rd_en <= 1'b0;
       end
     else
       begin
          if (rx_empty)
              rx_rd_en <= 1'b0;
          else if (!rx_almost_empty)
              rx_rd_en <= 1'b1;
          if (rx_axis_tvalid)
            begin
               addra <= {nextbuf[2:0],rx_addr_axis[10:3],rx_addr_axis[1:0]};
               dina <= {rx_axis_tdata,rx_axis_tdata};
               wea <= 2'b01 << rx_addr_axis[2];
               ena <= ~full;
            end
          else
               ena <= 1'b0;
            
       end

   assign tx_axis_tdata = douta >> {tx_frame_addr[2],3'b000};

   dualmem_widen8 RAMB16_inst_rx (
                                    .clka(~msoc_clk),             // Port A Clock
                                    .clkb(msoc_clk),              // Port A Clock
                                    .douta(),                     // Port A 8-bit Data Output
                                    .addra(addra),    // Port A 11-bit Address Input
                                    .dina(dina), // Port A 8-bit Data Input
                                    .ena(ena),         // Port A RAM Enable Input
                                    .wea(wea),                  // Port A Write Enable Input
                                    .doutb(framing_rdata_pkt),    // Port B 32-bit Data Output
                                    .addrb(core_lsu_addr[13:3]),  // Port B 9-bit Address Input
                                    .dinb(core_lsu_wdata),        // Port B 32-bit Data Input
                                    .enb(ce_d & framing_sel & core_lsu_addr[14]),
                                                                  // Port B RAM Enable Input
                                    .web(we_d ? {(|core_lsu_be[7:4]),(|core_lsu_be[3:0])} : 2'b0) // Port B Write Enable Input
                                    );

    dualmem_widen RAMB16_inst_tx (
                                   .clka(~clk_mii),             // Port A Clock
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
assign o_erefclk = clk_mii;

logic [31:0] rx_clk_cnt, tx_clk_cnt,
             rx_clk_div, tx_clk_div,
             rx_clk_prev, tx_clk_prev,
             rx_clk_frq, tx_clk_frq;

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
    nextbuf <= 4'b0;
    oldbuf <= 4'b0;
    newbuf <= 4'b0;
    eth_irq <= 1'b0;
    irq_en <= 1'b0;
    ce_d_dly <= 1'b0;
    tx_busy <= 1'b0;
    avail = 1'b0;         
    full <= 1'b0;
    rx_clk_cnt <= 0;
    tx_clk_cnt <= 0;       
    rx_clk_frq <= 0;
    tx_clk_frq <= 0;       
    rx_clk_prev <= 0;
    tx_clk_prev <= 0;       
    end
  else
    begin
    rx_clk_cnt = rx_clk_cnt + 1;       
    tx_clk_cnt = tx_clk_cnt + 1;
    if (rx_clk_cnt == 5000000)
      begin
         rx_clk_cnt = 0;
         rx_clk_frq <= rx_clk_div - rx_clk_prev;
         rx_clk_prev <= rx_clk_div;
      end
    if (tx_clk_cnt == 5000000)
      begin
         tx_clk_cnt = 0;
         tx_clk_frq <= tx_clk_div - tx_clk_prev;
         tx_clk_prev <= tx_clk_div;
      end
    core_lsu_addr_dly <= core_lsu_addr;
    emdio <= i_emdio;
    ce_d_dly <= ce_d;
    newbuf = nextbuf+1;
    avail = nextbuf != firstbuf;
    eth_irq <= avail & irq_en; // make eth_irq go away immediately if irq_en is low
    if (framing_sel&we_d&(core_lsu_addr[14:11]==4'b0001))
      case(core_lsu_addr[6:3])
        0: mac_address[31:0] <= core_lsu_wdata;
        1: {irq_en,promiscuous,spare,loopback,cooked,mac_address[47:32]} <= core_lsu_wdata;
        2: begin tx_enable_dly <= 8; tx_packet_length <= core_lsu_wdata; end /* tx payload size */
        3: begin tx_enable_dly <= 0; tx_packet_length <= 0; end
        4: begin {o_erst,oe_emdio,o_emdio,o_emdclk} <= core_lsu_wdata; end
        6: begin firstbuf <= core_lsu_wdata[3:0]; end
      endcase
       if ((rx_addr_axis >= 60) & (~gmii_rx_dv) & ~(sync|oldsync)) // Minimum length reduced to 60 to allow for pipelining
         begin
         // check broadcast/multicast address
	     sync <= (rx_dest_mac[47:24]==24'h01005E) | (&rx_dest_mac) | (mac_address == rx_dest_mac) | promiscuous;
         end
       else if (sync & rx_axis_tlast & ~gmii_rx_dv)
         begin
            oldbuf <= nextbuf;
            if (newbuf != {~firstbuf[3], firstbuf[2:0]})
              begin
                 full <= 1'b0;
                 nextbuf <= nextbuf + 1;            
                 oldsync <= 1'b1;
              end
            else
              full <= 1'b1;
            sync <= 1'b0;
         end
       else if (!rx_addr_axis)
         begin
         oldsync <= 1'b0;
         end
       if (etx_en && tx_axis_tlast)
         begin
            tx_enable_dly <= 0;
         end
       else if (1'b1 == |tx_enable_dly)
         begin
            tx_busy <= 1'b1;
            if (1'b0 == &tx_enable_dly)
              tx_enable_dly <= tx_enable_dly + 1'b1;
         end
       else if (~etx_en)
         tx_busy <= tx_enable_i;         
    end

always @(posedge clk_mii)
  if (!rstn)
    begin
       etx_wren <= 1'b0;
       tx_enable_i <= 1'b0;
    end
  else
    begin
       etx_wren <= etx_en | tx_busy;
       if (etx_en && tx_axis_tlast)
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
    13'b10001????0110 : framing_rdata = {full, eth_irq, avail, ~firstbuf[3], firstbuf[2:0], nextbuf, firstbuf};
    13'b10001????0111 : framing_rdata = {tx_clk_frq,rx_clk_frq};
    13'b10001????1??? : framing_rdata = rx_length_axis[core_lsu_addr_dly[5:3]];
    13'b10010???????? : framing_rdata = framing_wdata_pkt;
    13'b11??????????? : framing_rdata = framing_rdata_pkt;
    default: framing_rdata = 'h0;
    endcase

   assign o_erstn = ~o_erst;
  
   parameter dly = 0;
   
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
   
   always @(posedge clk_mii)
     if (~rstn)
       begin
          rx_addr_axis <= 'b0;
          tx_axis_tvalid <= 'b0;
	  tx_axis_tvalid_dly <= 'b0;
	  tx_frame_addr <= 'b0;
	  tx_axis_tlast <= 'b0;
          rx_dest_mac <= 'b0;
       end
     else
       begin
	  tx_axis_tvalid_dly <= tx_axis_tvalid;
	  tx_axis_tvalid <= tx_enable_i;
	  if (tx_axis_tready)
	    begin
	       tx_frame_addr <= tx_frame_addr + 1;
	       tx_axis_tlast <= (tx_frame_addr == tx_packet_length-2) & tx_axis_tvalid_dly;
	    end
	  if (!tx_busy)
	    begin
	       tx_frame_addr <= 'b0;
	    end
	  if (rx_axis_tvalid)
            begin
            rx_addr_axis <= rx_addr_axis + 1;
            if (rx_addr_axis < 6)
              rx_dest_mac <= {rx_dest_mac[39:0],rx_axis_tdata};
            end
	  if (oldsync)
            begin
	       rx_length_axis[oldbuf[2:0]] <= rx_addr_axis + 1;
	       rx_addr_axis <= 'b0;
               rx_dest_mac <= 'b0;
            end
      end

   always @(posedge i_erx_clk)
     if (~rstn)
       begin
          rx_clk_div <= 0;
          erx_wren <= 1'b0;
       end
     else
       begin
          rx_clk_div <= rx_clk_div + 1;
          erx_wren <= loopback ? o_etx_en : i_erx_dv;
       end

   logic         tx_empty, tx_almost_empty, tx_rd_en;
   
     FIFO18E1 #(
                .ALMOST_EMPTY_OFFSET(13'h5),       // Sets the almost empty threshold
                .ALMOST_FULL_OFFSET(13'h0080),     // Sets almost full threshold
                .DATA_WIDTH(9),                    // Sets data width to 4-36
                .DO_REG(1),                        // Enable output register (1-0) Must be 1 if EN_SYN = FALSE
                .EN_SYN("FALSE"),                  // Specifies FIFO as dual-clock (FALSE) or Synchronous (TRUE)
                .FIFO_MODE("FIFO18"),              // Sets mode to FIFO18 or FIFO18_36
                .FIRST_WORD_FALL_THROUGH("FALSE"), // Sets the FIFO FWFT to FALSE, TRUE
                .INIT(36'h000000000),              // Initial values on output port
                .SIM_DEVICE("7SERIES"),            // Must be set to "7SERIES" for simulation behavior
                .SRVAL(36'h000000000)              // Set/Reset value for output port
                )
      tx_fifo (
                        // Read Data: 32-bit (each) output: Read output data
                        .DO({tdummy26,o_etx_er,o_etx_en,o_etxd}), // 32-bit output: Data output
                        // Status: 1-bit (each) output: Flags and other FIFO status outputs
                        .ALMOSTEMPTY(tx_almost_empty),// 1-bit output: Almost empty flag
                        .EMPTY(tx_empty),          // 1-bit output: Empty flag
                        // Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
                        .RDCLK(i_etx_clk),           // 1-bit input: Read clock
                        .RDEN(tx_rd_en),           // 1-bit input: Read enable
                        .REGCE(1'b1),              // 1-bit input: Clock enable
                        .RST(!rstn),               // 1-bit input: Asynchronous Reset
                        .RSTREG(1'b0),             // 1-bit input: Output register set/reset
                        // Write Control Signals: 1-bit (each) input: Write clock and enable input signals
                        .WRCLK(clk_mii),         // 1-bit input: Write clock
                        .WREN(etx_wren),           // 1-bit input: Write enable
                        // Write Data: 32-bit (each) input: Write input data
                        .DI({26'b0,etx_er,etx_en,etxd}),                   // 32-bit input: Data input
                        .DIP(4'b0)                 // 4-bit input: Parity input
                        );
   
   always @(posedge i_etx_clk)
     if (~rstn)
       begin
          tx_clk_div <= 'b0;
          tx_rd_en <= 1'b0;
       end
     else
       begin
          if (tx_empty)
            tx_rd_en <= 1'b0;
          else if (!tx_almost_empty)
            tx_rd_en <= 1'b1;            
          tx_clk_div <= tx_clk_div + 1;
       end

   axis_gmii_rx gmii_rx_inst (
       .clk(clk_mii),
       .rst(~rstn),
       .mii_select(1'b1),
       .clk_enable(1'b1),
       .gmii_rxd({4'b0,gmii_rxd}),
       .gmii_rx_dv(gmii_rx_dv),
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
       .clk(clk_mii),
       .rst(~rstn),
       .mii_select(1'b1),
       .clk_enable(1'b1),
       .input_axis_tdata(tx_axis_tdata),
       .input_axis_tvalid(tx_axis_tvalid),
       .input_axis_tready(tx_axis_tready),
       .input_axis_tlast(tx_axis_tlast),
       .input_axis_tuser(tx_axis_tuser),
       .gmii_txd({tx_padding,etxd}),
       .gmii_tx_en(etx_en),
       .gmii_tx_er(etx_er),
       .ifg_delay(8'd12),
       .fcs_reg(tx_fcs_reg)
   );

endmodule // framing_top
`default_nettype wire
