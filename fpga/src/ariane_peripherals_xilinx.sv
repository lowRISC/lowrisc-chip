// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Xilinx Peripehrals
`default_nettype none

module ariane_peripherals_xilinx #(
    parameter int AxiAddrWidth = -1,
    parameter int AxiDataWidth = -1,
    parameter int AxiIdWidth   = -1,
    parameter int AxiUserWidth = 1,
    parameter bit InclUART     = 1,
    parameter bit InclSPI      = 0,
    parameter bit InclEthernet = 0,
    parameter bit InclGPIO     = 0
) (
    input  logic       clk_i           , // Clock
    input  logic       clk_200MHz_i    ,
    input  logic       rst_ni          , // Asynchronous reset active low
    AXI_BUS.Slave      iobus           ,
    output logic [ariane_soc::NumSources-1:0] irq_sources,
    // UART
    input  logic       rx_i            ,
    output logic       tx_o            ,
    // Ethernet
`ifdef RMII
    input  logic       clk_rmii        ,
    input  logic       clk_rmii_quad   ,
    input wire [1:0]   i_erxd, // RMII receive data
    input wire         i_erx_dv, // PHY data valid
    input wire         i_erx_er, // PHY coding error
    input wire         i_emdint, // PHY interrupt in active low
    output reg         o_erefclk, // RMII clock out
    output reg [1:0]   o_etxd, // RMII transmit data
    output reg         o_etx_en, // RMII transmit enable
    output wire        o_erstn, // PHY reset active low 
`endif
    // Ethernet
`ifdef RGMII
    input  logic       eth_clk_i       ,
    input  wire        eth_rxck        ,
    input  wire        eth_rxctl       ,
    input  wire [3:0]  eth_rxd         ,
    output wire        eth_txck        ,
    output wire        eth_txctl       ,
    output wire [3:0]  eth_txd         ,
    output wire        eth_rst_n       ,
    input  logic       phy_tx_clk_i    , // 125 MHz Clock
`endif
    // MDIO Interface
    inout  wire        eth_mdio        ,
    output logic       eth_mdc         ,
    // SD (shared with SPI)
    output wire        sd_sclk,
    input wire         sd_detect,
    inout wire [3:0]   sd_dat,
    inout wire         sd_cmd,
    output reg         sd_reset,
    output logic [7:0] leds_o,
    input  logic [7:0] dip_switches_i,
    input wire         pxl_clk,
`ifdef GENESYSII
    // display
    output wire [4:0]  VGA_RED_O,
    output wire [4:0]  VGA_BLUE_O,
    output wire [5:0]  VGA_GREEN_O,
`elsif NEXYS4DDR
    output wire   [3:0] VGA_RED_O   ,
    output wire   [3:0] VGA_BLUE_O  ,
    output wire   [3:0] VGA_GREEN_O ,
`endif
`ifndef NEXYS_VIDEO
  //keyboard
    inout wire         PS2_CLK     ,
    inout wire         PS2_DATA    ,
  // display
    output wire        VGA_HS_O    ,
    output wire        VGA_VS_O    ,
`endif
  // Quad-SPI
    inout wire         QSPI_CSN,
    inout wire [3:0]   QSPI_D   
);

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_ID_WIDTH   ( AxiIdWidth       ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) master[ariane_soc::ExtLast-1:0]();

logic [ariane_soc::ExtLast-1:0][AxiAddrWidth-1:0] BASE;
logic [ariane_soc::ExtLast-1:0][AxiAddrWidth-1:0] MASK;

assign BASE = {
        ariane_soc::BOOTBase,
        ariane_soc::UARTBase,
        ariane_soc::SPIBase,
        ariane_soc::EthernetBase,
        ariane_soc::GPIOBase,
        ariane_soc::HIDBase
      };
      
assign MASK = {
              ariane_soc::BOOTLength - 1,
              ariane_soc::UARTLength - 1,
              ariane_soc::SPILength - 1,
              ariane_soc::EthernetLength -1,
              ariane_soc::GPIOLength - 1,
              ariane_soc::HIDLength - 1
            };

axi_demux_raw #(
    .SLAVE_NUM  ( ariane_soc::ExtLast ),
    .ADDR_WIDTH ( AxiAddrWidth        ),
    .ID_WIDTH   ( AxiIdWidth          )
) demux (.clk(clk_i), .rstn(rst_ni), .master(iobus), .slave(master), .BASE, .MASK);

// ---------------
// BOOTRAM
// ---------------

logic                    ram_req, ram_we;
logic [AxiAddrWidth-1:0] ram_addr;
logic [AxiDataWidth-1:0] ram_rdata, ram_wdata;
logic [AxiDataWidth/8-1:0] ram_be;

axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidth       ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) i_axi2rom (
    .clk_i  ( clk_i                    ),
    .rst_ni ( rst_ni                   ),
    .slave  ( master[ariane_soc::BOOT] ),
    .req_o  ( ram_req                  ),
    .we_o   ( ram_we                   ),
    .addr_o ( ram_addr                 ),
    .be_o   ( ram_be                   ),
    .data_o ( ram_wdata                ),
    .data_i ( ram_rdata                )
);

bootram i_bootram (
    .clk_i   ( clk_i     ),
    .req_i   ( ram_req   ),
    .we_i    ( ram_we    ),
    .addr_i  ( ram_addr  ),
    .be_i    ( ram_be    ),
    .wdata_i ( ram_wdata ),
    .rdata_o ( ram_rdata )
);
   
    // ---------------
    // 2. UART
    // ---------------
    logic         uart_penable;
    logic         uart_pwrite;
    logic [31:0]  uart_paddr;
    logic         uart_psel;
    logic [31:0]  uart_pwdata;
    logic [31:0]  uart_prdata;
    logic         uart_pready;
    logic         uart_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth ),
        .AXI4_ID_WIDTH      ( AxiIdWidth   ),
        .AXI4_USER_WIDTH    ( AxiUserWidth ),
        .BUFF_DEPTH_SLAVE   ( 2            ),
        .APB_ADDR_WIDTH     ( 32           )
    ) i_axi2apb_64_32_uart (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( master[ariane_soc::UART].aw_id     ),
        .AWADDR_i  ( master[ariane_soc::UART].aw_addr   ),
        .AWLEN_i   ( master[ariane_soc::UART].aw_len    ),
        .AWSIZE_i  ( master[ariane_soc::UART].aw_size   ),
        .AWBURST_i ( master[ariane_soc::UART].aw_burst  ),
        .AWLOCK_i  ( master[ariane_soc::UART].aw_lock   ),
        .AWCACHE_i ( master[ariane_soc::UART].aw_cache  ),
        .AWPROT_i  ( master[ariane_soc::UART].aw_prot   ),
        .AWREGION_i( master[ariane_soc::UART].aw_region ),
        .AWUSER_i  ( master[ariane_soc::UART].aw_user   ),
        .AWQOS_i   ( master[ariane_soc::UART].aw_qos    ),
        .AWVALID_i ( master[ariane_soc::UART].aw_valid  ),
        .AWREADY_o ( master[ariane_soc::UART].aw_ready  ),
        .WDATA_i   ( master[ariane_soc::UART].w_data    ),
        .WSTRB_i   ( master[ariane_soc::UART].w_strb    ),
        .WLAST_i   ( master[ariane_soc::UART].w_last    ),
        .WUSER_i   ( master[ariane_soc::UART].w_user    ),
        .WVALID_i  ( master[ariane_soc::UART].w_valid   ),
        .WREADY_o  ( master[ariane_soc::UART].w_ready   ),
        .BID_o     ( master[ariane_soc::UART].b_id      ),
        .BRESP_o   ( master[ariane_soc::UART].b_resp    ),
        .BVALID_o  ( master[ariane_soc::UART].b_valid   ),
        .BUSER_o   ( master[ariane_soc::UART].b_user    ),
        .BREADY_i  ( master[ariane_soc::UART].b_ready   ),
        .ARID_i    ( master[ariane_soc::UART].ar_id     ),
        .ARADDR_i  ( master[ariane_soc::UART].ar_addr   ),
        .ARLEN_i   ( master[ariane_soc::UART].ar_len    ),
        .ARSIZE_i  ( master[ariane_soc::UART].ar_size   ),
        .ARBURST_i ( master[ariane_soc::UART].ar_burst  ),
        .ARLOCK_i  ( master[ariane_soc::UART].ar_lock   ),
        .ARCACHE_i ( master[ariane_soc::UART].ar_cache  ),
        .ARPROT_i  ( master[ariane_soc::UART].ar_prot   ),
        .ARREGION_i( master[ariane_soc::UART].ar_region ),
        .ARUSER_i  ( master[ariane_soc::UART].ar_user   ),
        .ARQOS_i   ( master[ariane_soc::UART].ar_qos    ),
        .ARVALID_i ( master[ariane_soc::UART].ar_valid  ),
        .ARREADY_o ( master[ariane_soc::UART].ar_ready  ),
        .RID_o     ( master[ariane_soc::UART].r_id      ),
        .RDATA_o   ( master[ariane_soc::UART].r_data    ),
        .RRESP_o   ( master[ariane_soc::UART].r_resp    ),
        .RLAST_o   ( master[ariane_soc::UART].r_last    ),
        .RUSER_o   ( master[ariane_soc::UART].r_user    ),
        .RVALID_o  ( master[ariane_soc::UART].r_valid   ),
        .RREADY_i  ( master[ariane_soc::UART].r_ready   ),
        .PENABLE   ( uart_penable   ),
        .PWRITE    ( uart_pwrite    ),
        .PADDR     ( uart_paddr     ),
        .PSEL      ( uart_psel      ),
        .PWDATA    ( uart_pwdata    ),
        .PRDATA    ( uart_prdata    ),
        .PREADY    ( uart_pready    ),
        .PSLVERR   ( uart_pslverr   )
    );

    if (InclUART) begin : gen_uart
        apb_uart i_apb_uart (
            .CLK     ( clk_i           ),
            .RSTN    ( rst_ni          ),
            .PSEL    ( uart_psel       ),
            .PENABLE ( uart_penable    ),
            .PWRITE  ( uart_pwrite     ),
            .PADDR   ( uart_paddr[4:2] ),
            .PWDATA  ( uart_pwdata     ),
            .PRDATA  ( uart_prdata     ),
            .PREADY  ( uart_pready     ),
            .PSLVERR ( uart_pslverr    ),
            .INT     ( irq_sources[0]  ),
            .OUT1N   (                 ), // keep open
            .OUT2N   (                 ), // keep open
            .RTSN    (                 ), // no flow control
            .DTRN    (                 ), // no flow control
            .CTSN    ( 1'b0            ),
            .DSRN    ( 1'b0            ),
            .DCDN    ( 1'b0            ),
            .RIN     ( 1'b0            ),
            .SIN     ( rx_i            ),
            .SOUT    ( tx_o            )
        );
    end else begin
        assign irq_sources[0] = 1'b0;
        /* pragma translate_off */
        `ifndef VERILATOR
        mock_uart i_mock_uart (
            .clk_i     ( clk_i        ),
            .rst_ni    ( rst_ni       ),
            .penable_i ( uart_penable ),
            .pwrite_i  ( uart_pwrite  ),
            .paddr_i   ( uart_paddr   ),
            .psel_i    ( uart_psel    ),
            .pwdata_i  ( uart_pwdata  ),
            .prdata_o  ( uart_prdata  ),
            .pready_o  ( uart_pready  ),
            .pslverr_o ( uart_pslverr )
        );
        `endif
        /* pragma translate_on */
    end

    // ---------------
    // 3. SPI
    // ---------------
    if (InclSPI) begin : gen_spi

logic                    spi_en, spi_we, spi_int_n, spi_pme_n, spi_mdio_i, spi_mdio_o, spi_mdio_oe;
logic [AxiAddrWidth-1:0] spi_addr;
logic [AxiDataWidth-1:0] spi_wrdata, spi_rdata;
logic [AxiDataWidth/8-1:0] spi_be;

axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidth       ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) i_axi2spi (
    .clk_i  ( clk_i                   ),
    .rst_ni ( rst_ni                  ),
    .slave  ( master[ariane_soc::SPI] ),
    .req_o  ( spi_en                  ),
    .we_o   ( spi_we                  ),
    .addr_o ( spi_addr                ),
    .be_o   ( spi_be                  ),
    .data_o ( spi_wrdata              ),
    .data_i ( spi_rdata               )
);

sd_bus sd1
  (
   .spisd_en     ( spi_en                  ),
   .spisd_we     ( spi_we                  ),
   .spisd_addr   ( spi_addr                ),
   .spisd_be     ( spi_be                  ),
   .spisd_wrdata ( spi_wrdata              ),
   .spisd_rddata ( spi_rdata               ),
   .clk_200MHz   ( clk_200MHz_i            ),
   .msoc_clk     ( clk_i                   ),
   .rstn         ( rst_ni                  ),
   .sd_sclk,
   .sd_detect,
   .sd_dat,
   .sd_cmd,
   .sd_reset,
   .sd_irq       ( irq_sources[1]          )
   );
       
    end else begin
        assign sd_sclk = 1'b0;
        assign sd_dat = 4'bzzzz;
        assign sd_cmd = 1'bz;

        assign irq_sources [1] = 1'b0;
        assign spi.aw_ready = 1'b1;
        assign spi.ar_ready = 1'b1;
        assign spi.w_ready = 1'b1;

        assign spi.b_valid = spi.aw_valid;
        assign spi.b_id = spi.aw_id;
        assign spi.b_resp = axi_pkg::RESP_SLVERR;
        assign spi.b_user = '0;

        assign spi.r_valid = spi.ar_valid;
        assign spi.r_resp = axi_pkg::RESP_SLVERR;
        assign spi.r_data = 'hdeadbeef;
        assign spi.r_last = 1'b1;
    end


    // ---------------
    // 4. Ethernet
    // ---------------

    if (InclEthernet) begin : gen_ethernet

    logic                    eth_en, eth_we;
    logic [AxiAddrWidth-1:0] eth_addr;
    logic [AxiDataWidth-1:0] eth_wrdata, eth_rdata;
    logic [AxiDataWidth/8-1:0] eth_be;
    logic                    eth_int_n, eth_pme_n, eth_mdio_i, eth_mdio_o, eth_mdio_oe;

    IOBUF #(
          .DRIVE(12), // Specify the output drive strength
          .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
          .IOSTANDARD("DEFAULT"), // Specify the I/O standard
          .SLEW("SLOW") // Specify the output slew rate
       ) IOBUF_inst (
          .O(eth_mdio_i),     // Buffer output
          .IO(eth_mdio),      // Buffer inout port (connect directly to top-level port)
          .I(eth_mdio_o),     // Buffer input
          .T(~eth_mdio_oe)    // 3-state enable input, high=input, low=output
       );

    axi2mem #(
        .AXI_ID_WIDTH   ( AxiIdWidth       ),
        .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
        .AXI_DATA_WIDTH ( AxiDataWidth     ),
        .AXI_USER_WIDTH ( AxiUserWidth     )
    ) i_axi2rom (
        .clk_i  ( clk_i                        ),
        .rst_ni ( rst_ni                       ),
        .slave  ( master[ariane_soc::Ethernet] ),
        .req_o  ( eth_en                       ),
        .we_o   ( eth_we                       ),
        .addr_o ( eth_addr                     ),
        .be_o   ( eth_be                       ),
        .data_o ( eth_wrdata                   ),
        .data_i ( eth_rdata                    )
    );

`ifdef RMII

    framing_top_rmii eth_mii (
       .rstn(rst_ni),
       .msoc_clk(clk_i),
       .clk_rmii(clk_rmii),
       .clk_rmii_quad(clk_rmii_quad),

       .core_lsu_addr(eth_addr[14:0]),
       .core_lsu_wdata(eth_wrdata),
       .core_lsu_be(eth_be),
       .ce_d(eth_en),
       .we_d(eth_en & eth_we),
       .framing_sel(eth_en),
       .framing_rdata(eth_rdata),
       .o_edutrefclk(o_erefclk),
       .i_edutrxd(i_erxd),
       .i_edutrx_dv(i_erx_dv),
       .i_edutrx_er(i_erx_er),
       .o_eduttxd(o_etxd),
       .o_eduttx_en(o_etx_en),
       .o_edutmdc(eth_mdc),
       .i_edutmdio(eth_mdio_i),
       .o_edutmdio(eth_mdio_o),
       .oe_edutmdio(eth_mdio_oe),
       .o_edutrstn(o_erstn),
       .eth_irq(irq_sources[2])
    );

`endif

`ifdef RGMII

    framing_top eth_rgmii (
       .msoc_clk(clk_i),
       .core_lsu_addr(eth_addr[14:0]),
       .core_lsu_wdata(eth_wrdata),
       .core_lsu_be(eth_be),
       .ce_d(eth_en),
       .we_d(eth_en & eth_we),
       .framing_sel(eth_en),
       .framing_rdata(eth_rdata),
       .rst_int(!rst_ni),
       .clk_int(phy_tx_clk_i), // 125 MHz in-phase
       .clk90_int(eth_clk_i),    // 125 MHz quadrature
       .clk_200_int(clk_200MHz_i),
       /*
        * Ethernet: 1000BASE-T RGMII
        */
       .phy_rx_clk(eth_rxck),
       .phy_rxd(eth_rxd),
       .phy_rx_ctl(eth_rxctl),
       .phy_tx_clk(eth_txck),
       .phy_txd(eth_txd),
       .phy_tx_ctl(eth_txctl),
       .phy_reset_n(eth_rst_n),
       .phy_int_n(eth_int_n),
       .phy_pme_n(eth_pme_n),
       .phy_mdc(eth_mdc),
       .phy_mdio_i(eth_mdio_i),
       .phy_mdio_o(eth_mdio_o),
       .phy_mdio_oe(eth_mdio_oe),
       .eth_irq(irq_sources[2])
    );

`endif

    end else begin
        assign irq_sources [2] = 1'b0;
        assign ethernet.aw_ready = 1'b1;
        assign ethernet.ar_ready = 1'b1;
        assign ethernet.w_ready = 1'b1;

        assign ethernet.b_valid = ethernet.aw_valid;
        assign ethernet.b_id = ethernet.aw_id;
        assign ethernet.b_resp = axi_pkg::RESP_SLVERR;
        assign ethernet.b_user = '0;

        assign ethernet.r_valid = ethernet.ar_valid;
        assign ethernet.r_resp = axi_pkg::RESP_SLVERR;
        assign ethernet.r_data = 'hdeadbeef;
        assign ethernet.r_last = 1'b1;
    end

    // 5. GPIO

    if (InclGPIO) begin : gen_gpio

logic                    gpio_en, gpio_we, gpio_int_n, gpio_pme_n, gpio_mdio_i, gpio_mdio_o, gpio_mdio_oe;
logic [AxiAddrWidth-1:0] gpio_addr, gpio_addr_prev;
logic [AxiDataWidth-1:0] gpio_wrdata, gpio_rdata;
logic [AxiDataWidth/8-1:0] gpio_be;

axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidth       ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) i_axi2gpio (
    .clk_i  ( clk_i                    ),
    .rst_ni ( rst_ni                   ),
    .slave  ( master[ariane_soc::GPIO] ),
    .req_o  ( gpio_en                  ),
    .we_o   ( gpio_we                  ),
    .addr_o ( gpio_addr                ),
    .be_o   ( gpio_be                  ),
    .data_o ( gpio_wrdata              ),
    .data_i ( gpio_rdata               )
);

       logic               rdfifo;       
       wire [31:0]         fifo_out;
       wire [11:0]         rdcount, wrcount;       
       wire                full, empty, rderr, wrerr;
       logic               spi_wr;
       logic [31:0]        data_from_host;
       wire                spi_busy, spi_error;
       wire [63:0]         spi_readout;

`ifdef HWRNG
       
 lowrisc_hwrng rng
  (
   .clk_i,
   .rst_ni,
   .rdfifo,
   .rdcount,
   .wrcount,
   .fifo_out,
   .full,
   .empty,
   .rderr,
   .wrerr
   );

`else
       assign rdcount = 12'b0;
       assign wrcount = 12'b0;
       assign full = 1'b0;
       assign empty = 1'b1;
       assign rderr = 1'b0;
       assign wrerr = 1'b0;
`endif
       
       always_comb
         begin
            case(gpio_addr_prev[5:3])
              3'b000:
                begin
                   gpio_rdata = dip_switches_i;
                end
              3'b010:
                begin
                   gpio_rdata = fifo_out;
                end
              3'b011:
                begin
                   gpio_rdata = {full, empty, rderr, wrerr, 7'b0, rdcount[8:0], 7'b0, wrcount[8:0]};
                end
              3'b100:
                begin
                   gpio_rdata = spi_readout;
                end
              3'b110:
                begin
                   gpio_rdata = {spi_busy, spi_error};
                end
              default:
                begin
                   gpio_rdata = 32'hDEADBEEF;
                end
            endcase // case (gpio_addr[5:3])
         end

       always @(posedge clk_i)
         begin
            spi_wr <= 0;
            rdfifo <= 0;
            gpio_addr_prev <= gpio_addr;
            if (gpio_en && gpio_we)
              case(gpio_addr[5:3])
                3'b000:
                  begin
                     leds_o <= gpio_wrdata;
                  end
                3'b010:
                  begin
                     rdfifo <= 1;
                  end
                3'b101:
                  begin
                     data_from_host <= gpio_wrdata;
                     spi_wr <= 1;
                  end
                default:;
              endcase // case (gpio_addr[5:3])
         end

`ifdef QSPI_CONFIG_MEM
// Bitbang SPI for retrieving MAC address

dword_interface dwi_inst(
                         .clk_in(clk_i),
                         .reset(~rst_ni), 
                         .data_from_PC(data_from_host),
                         .wr(spi_wr),
                         .busy(spi_busy),
                         .error(spi_error),
                         .readout(spi_readout),
                         .S(QSPI_CSN),
                         .DQio(QSPI_D)
    );

`endif
   
    end

    // HID

logic                    hid_en, hid_we, hid_int_n, hid_pme_n, hid_mdio_i, hid_mdio_o, hid_mdio_oe;
logic [AxiAddrWidth-1:0] hid_addr, hid_addr_prev;
logic [AxiDataWidth-1:0] hid_wrdata, hid_rddata;
logic [AxiDataWidth/8-1:0] hid_be;

axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidth       ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) i_axi2hid (
    .clk_i  ( clk_i                    ),
    .rst_ni ( rst_ni                   ),
    .slave  ( master[ariane_soc::HID] ),
    .req_o  ( hid_en                  ),
    .we_o   ( hid_we                  ),
    .addr_o ( hid_addr                ),
    .be_o   ( hid_be                  ),
    .data_o ( hid_wrdata              ),
    .data_i ( hid_rddata              )
);

`ifndef NEXYS_VIDEO

hid_soc hid1
  (
 // clock and reset
 .pxl_clk,
 .msoc_clk(clk_i),
 .rstn(rst_ni),
 .hid_en,
 .hid_be,
 .hid_addr(hid_addr[18:0]),
 .hid_wrdata,
 .hid_rddata,
 //keyboard
 .PS2_CLK,
 .PS2_DATA,
 // display
 .VGA_HS_O,
 .VGA_VS_O,
 .VGA_RED_O,
 .VGA_BLUE_O,
 .VGA_GREEN_O
   );

`endif
  
endmodule

`default_nettype wire
