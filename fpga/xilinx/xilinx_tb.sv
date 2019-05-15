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
// Author: Florian Zaruba, ETH Zurich
// Date: 15/04/2017
// Description: Top level testbench module. Instantiates the top level DUT, configures
//              the virtual interfaces and starts the test passed by +UVM_TEST+

import ariane_pkg::*;

module xilinx_tb;
    longint unsigned cycles;
    longint unsigned max_cycles;
    logic    clk;
    logic    cpu_resetn;   
`ifdef GENESYSII
    localparam int unsigned CLOCK_PERIOD = 5ns;
    logic         sys_clk_p   ;
    logic         sys_clk_n   ;
    wire  [31:0]  ddr3_dq     ;
    wire  [ 3:0]  ddr3_dqs_n  ;
    wire  [ 3:0]  ddr3_dqs_p  ;
    logic [14:0]  ddr3_addr   ;
    logic [ 2:0]  ddr3_ba     ;
    logic         ddr3_ras_n  ;
    logic         ddr3_cas_n  ;
    logic         ddr3_we_n   ;
    logic         ddr3_reset_n;
    logic [ 0:0]  ddr3_ck_p   ;
    logic [ 0:0]  ddr3_ck_n   ;
    logic [ 0:0]  ddr3_cke    ;
    logic [ 0:0]  ddr3_cs_n   ;
    logic [ 3:0]  ddr3_dm     ;
    logic [ 0:0]  ddr3_odt    ;
    assign sys_clk_p = clk;
    assign sys_clk_n = ~clk;   
`elsif NEXYS4DDR
    localparam int unsigned CLOCK_PERIOD = 10ns;
    logic        clk_p       ;
    wire  [15:0] ddr2_dq     ;
    wire  [ 1:0] ddr2_dqs_n  ;
    wire  [ 1:0] ddr2_dqs_p  ;
    logic [12:0] ddr2_addr   ;
    logic [ 2:0] ddr2_ba     ;
    logic        ddr2_ras_n  ;
    logic        ddr2_cas_n  ;
    logic        ddr2_we_n   ;
    logic [ 0:0] ddr2_ck_p   ;
    logic [ 0:0] ddr2_ck_n   ;
    logic [ 0:0] ddr2_cke    ;
    logic [ 1:0] ddr2_dm     ;
    logic [ 0:0] ddr2_odt    ;
    assign clk_p = clk;
`elsif NEXYS_VIDEO
    localparam int unsigned CLOCK_PERIOD = 10ns;
    logic        clk_p       ;
    logic        cpu_resetn  ;
    wire  [15:0] ddr3_dq     ;
    wire   [1:0] ddr3_dqs_n  ;
    wire   [1:0] ddr3_dqs_p  ;
    logic [14:0] ddr3_addr   ;
    logic  [2:0] ddr3_ba     ;
    logic        ddr3_ras_n  ;
    logic        ddr3_cas_n  ;
    logic        ddr3_we_n   ;
    logic        ddr3_reset_n;
    logic        ddr3_ck_n   ;
    logic        ddr3_ck_p   ;
    logic        ddr3_cke    ;
    logic  [1:0] ddr3_dm     ;
    logic        ddr3_odt    ;
    assign clk_p = clk;
`endif
`ifdef RGMII
    wire          eth_rst_n   ;
    reg           eth_rxck    ;
    reg           eth_rxctl   ;
    reg  [3:0]    eth_rxd     ;
    wire          eth_txck    ;
    wire          eth_txctl   ;
    wire [3:0]    eth_txd     ;
    initial
      begin
         eth_rxck = 0;
         eth_rxctl = 0;
         eth_rxd = 0;
      end
`endif
`ifdef RMII
  //! Ethernet MAC PHY interface signals
    wire [1:0]    i_erxd; // RMII receive data
    wire          i_erx_dv; // PHY data valid
    wire          i_erx_er; // PHY coding error
    wire          i_emdint; // PHY interrupt in active low
    reg           o_erefclk; // RMII clock out
    reg [1:0]     o_etxd; // RMII transmit data
    reg           o_etx_en; // RMII transmit enable
    wire          o_erstn;  // PHY reset active low 
    initial
      begin
         i_erxd = 0;
         i_erx_dv = 0;
         i_erx_er = 0;
         i_emdint = 0;
      end
`endif
    wire          eth_mdc;  // MDIO clock
    tri1          eth_mdio; // MDIO inout

    logic [ 7:0]  led         ;
    logic [ 7:0]  sw          ;
    logic         fan_pwm     ;
    // SD (shared with SPI)
    wire          sd_sclk;
    logic         sd_detect;
    tri1 [3:0]    sd_dat;
    tri1          sd_cmd;
    wire          sd_reset;
    // common part
    logic         tck         ;
    logic         tms         ;
    logic         trst_n      ;
    logic         tdi         ;
    wire          tdo         ;
    logic         rx          ;
    logic         tx          ;
    // Quad-SPI
    tri1          QSPI_CSN   ;
    tri1 [3:0]    QSPI_D    ;

    ariane_xilinx dut (.*);

    // Clock process
    initial begin
       sw = 0;
       sd_detect = 0;
       tck = 0;
       tms = 0;
       trst_n = 0;
       tdi = 0;
       rx = 1'b1;
       
        clk = 1'b0;
        cpu_resetn = 1'b0;
        repeat(8)
            #(CLOCK_PERIOD/2)
                 begin
                    clk = ~clk;
                    tck = ~tck;
                 end
        cpu_resetn = 1'b1;
        trst_n = 1'b1;
       
        forever begin
            #(CLOCK_PERIOD/2) clk = 1'b1;
            #(CLOCK_PERIOD/2) clk = 1'b0;

            //if (cycles > max_cycles)
            //    $fatal(1, "Simulation reached maximum cycle count of %d", max_cycles);

            cycles++;
        end
    end

    initial begin
        automatic logic [7:0][7:0] mem_row;
        longint address, len;
        byte buffer[];
        int unsigned rand_value;
        rand_value = $urandom;
        rand_value = $random(rand_value);
        $display("testing $random %0x seed %d", rand_value, unsigned'($get_initial_random_seed));
        $vcdpluson();
     end

`ifdef VCS
endmodule // xilinx_tb

module dummy;
   
// tediously connect unused module interfaces at the top level
// and unused modules to avoid cluttering the GUI display with loads of toplevels
   
   AXI_BUS  #(
    .AXI_ADDR_WIDTH ( 64     ),
    .AXI_DATA_WIDTH ( 64     ),
    .AXI_ID_WIDTH   ( 5      ),
    .AXI_USER_WIDTH ( 1      )
) axi_dummy[18:0] (), axi_master[3:0] (), axi_slave[3:0] (), axi_master4[3:0] ();
   AXI_LITE #(
    .AXI_ADDR_WIDTH ( 64     ),
    .AXI_DATA_WIDTH ( 64     ),
    .AXI_ID_WIDTH   ( 5      ),
    .AXI_USER_WIDTH ( 1      )
) axi_dummy_lite[1:0] ();
   REG_BUS reg_dummy[1:0] ();
   
   axi_riscv_lrsc_wrap #(.ADDR_BEGIN(0),
                         .ADDR_END(1),
                         .AXI_ADDR_WIDTH(64),
                         .AXI_DATA_WIDTH(64),
                         .AXI_ID_WIDTH(5)) dummy1 (.mst(axi_dummy[0]), .slv(axi_dummy[8]));
   axi_riscv_atomics_wrap dummy2 (.mst(axi_dummy[1]), .slv(axi_dummy[2]));
   axi_master_connect_rev dummy3 (.master(axi_dummy[3]));
   axi_slave_connect_rev dummy4 (.slave(axi_dummy[4]));
   axi_node_wrap_with_slices dummy5 (.master(axi_master), .slave(axi_slave));
   axi_to_axi_lite dummy6 (.in(axi_dummy[6]), .out(axi_dummy_lite[0]));
   axi_slave_connect dummy7 (.slave(axi_dummy[10]));
   axi_slice_wrap dummy8 (.axi_master(axi_dummy[11]), .axi_slave(axi_dummy[12]));
   apb_to_reg dummy9 (.reg_o(reg_dummy[0]));
   axi_master_connect dummy10 (.master(axi_dummy[13]));
   axi_demux #(
    .SLAVE_NUM  ( 4      ),
    .ADDR_WIDTH ( 64     ),
    .DATA_WIDTH ( 64     ),
    .USER_WIDTH ( 1      ),
    .ID_WIDTH   ( 5      )
   ) dummy11 (.clk(1'b0),
              .rstn(1'b0),
              .master(axi_dummy[14]),
              .slave(axi_master4),
              .BASE(0),
              .MASK(0));
   stream_mux #(.N_INP(2)) dummy12 ();
   ariane_shell dummy13(.dram(axi_dummy[15]), .iobus(axi_dummy[16]));
   rocket_shell dummy14(.dram(axi_dummy[17]), .iobus(axi_dummy[18]));

ClockDivider2 ();

ClockDivider3 ();

TestHarness ();

amo_alu ();

apb_regs_top ();

axi2apb ();

axi_delayer ();

axi_regs_top ();

axififo ();

binary_to_gray ();

bscan_generic ();

cache_ctrl ();

clock_buffer_generic ();

div_sqrt_mvp_wrapper ();

dword_interface ();

edge_detect ();

edge_detector ();

fpnew_f2fcast ();

fpnew_f2icast ();

fpnew_i2fcast ();

fpnew_top_dummy ();

framing_top_rmii ();

generic_fifo ();

gray_to_binary ();

io_buffer_generic ();

oddr_buffer_generic ();

pulp_sync ();

sd_clock_divider ();

slave_adapter ();

std_icache ();

stream_demux ();

synchronizer ();

tag_cmp ();

wt_l15_adapter ();

xlnx_axi_dwidth_converter ();

xlnx_axi_gpio ();

xlnx_axi_quad_spi ();

`endif   
   
endmodule
