// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//

module uart_axi #(
    parameter int unsigned AXI_ID_WIDTH      = 10,
    parameter int unsigned AXI_ADDR_WIDTH    = 64,
    parameter int unsigned AXI_DATA_WIDTH    = 64,
    parameter int unsigned AXI_USER_WIDTH    = 10,
    parameter bit          InclUART          = 1
)(
    input logic                         clk_i,    // Clock
    input logic                         rst_ni,  // Asynchronous reset active low
    AXI_BUS.Slave                       slave,
    input  logic                        rx_i,
    output logic                        tx_o,
    input  logic                        cts_i,
    output logic                        rts_o,

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
        .ACLK      ( clk_i           ),
        .ARESETn   ( rst_ni          ),
        .test_en_i ( 1'b0            ),
        .AWID_i    ( slave.aw_id     ),
        .AWADDR_i  ( slave.aw_addr   ),
        .AWLEN_i   ( slave.aw_len    ),
        .AWSIZE_i  ( slave.aw_size   ),
        .AWBURST_i ( slave.aw_burst  ),
        .AWLOCK_i  ( slave.aw_lock   ),
        .AWCACHE_i ( slave.aw_cache  ),
        .AWPROT_i  ( slave.aw_prot   ),
        .AWREGION_i( slave.aw_region ),
        .AWUSER_i  ( slave.aw_user   ),
        .AWQOS_i   ( slave.aw_qos    ),
        .AWVALID_i ( slave.aw_valid  ),
        .AWREADY_o ( slave.aw_ready  ),
        .WDATA_i   ( slave.w_data    ),
        .WSTRB_i   ( slave.w_strb    ),
        .WLAST_i   ( slave.w_last    ),
        .WUSER_i   ( slave.w_user    ),
        .WVALID_i  ( slave.w_valid   ),
        .WREADY_o  ( slave.w_ready   ),
        .BID_o     ( slave.b_id      ),
        .BRESP_o   ( slave.b_resp    ),
        .BVALID_o  ( slave.b_valid   ),
        .BUSER_o   ( slave.b_user    ),
        .BREADY_i  ( slave.b_ready   ),
        .ARID_i    ( slave.ar_id     ),
        .ARADDR_i  ( slave.ar_addr   ),
        .ARLEN_i   ( slave.ar_len    ),
        .ARSIZE_i  ( slave.ar_size   ),
        .ARBURST_i ( slave.ar_burst  ),
        .ARLOCK_i  ( slave.ar_lock   ),
        .ARCACHE_i ( slave.ar_cache  ),
        .ARPROT_i  ( slave.ar_prot   ),
        .ARREGION_i( slave.ar_region ),
        .ARUSER_i  ( slave.ar_user   ),
        .ARQOS_i   ( slave.ar_qos    ),
        .ARVALID_i ( slave.ar_valid  ),
        .ARREADY_o ( slave.ar_ready  ),
        .RID_o     ( slave.r_id      ),
        .RDATA_o   ( slave.r_data    ),
        .RRESP_o   ( slave.r_resp    ),
        .RLAST_o   ( slave.r_last    ),
        .RUSER_o   ( slave.r_user    ),
        .RVALID_o  ( slave.r_valid   ),
        .RREADY_i  ( slave.r_ready   ),
        .PENABLE   ( uart_penable    ),
        .PWRITE    ( uart_pwrite     ),
        .PADDR     ( uart_paddr      ),
        .PSEL      ( uart_psel       ),
        .PWDATA    ( uart_pwdata     ),
        .PRDATA    ( uart_prdata     ),
        .PREADY    ( uart_pready     ),
        .PSLVERR   ( uart_pslverr    )
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
            .INT     ( irq_o           ),
            .OUT1N   (                 ), // keep open
            .OUT2N   (                 ), // keep open
            .RTSN    ( rts_o           ),
            .DTRN    (                 ),
            .CTSN    ( cts_i           ),
            .DSRN    ( 1'b0            ),
            .DCDN    ( 1'b0            ),
            .RIN     ( 1'b0            ),
            .SIN     ( rx_i            ),
            .SOUT    ( tx_o            )
        );
    end else begin
        assign irq_o = 1'b0;
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

endmodule
