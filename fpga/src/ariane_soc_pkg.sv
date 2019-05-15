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
// Description: Contains SoC information as constants
package ariane_soc;
  // M-Mode Hart, S-Mode Hart
  localparam int unsigned NumTargets = 2;
  // Uart, SPI, Ethernet, reserved
  localparam int unsigned NumSources = 30;
  localparam int unsigned MaxPriority = 7;

  localparam NrSlaves = 2; // actually masters, but slaves on the crossbar

  // 4 is recommended by AXI standard, so lets stick to it, do not change
  localparam IdWidth   = 4;
  localparam IdWidthSlave = IdWidth + $clog2(NrSlaves);

  typedef enum int unsigned {
    DRAM     = 0,
    ExtIO    = 1,
    PLIC     = 2,
    CLINT    = 3,
    Debug    = 4
  } axi_slaves_t;

  typedef enum int unsigned {
    GPIO     = 0,
    Ethernet = 1,
    SPI      = 2,
    UART     = 3,
    BOOT     = 4
  } axi_extio_t;

  localparam NB_PERIPHERALS = Debug + 1;

  localparam logic[63:0] DebugLength    = 64'h1000;
  localparam logic[63:0] CLINTLength    = 64'hC0000;
  localparam logic[63:0] PLICLength     = 64'h3FF_FFFF;
  localparam logic[63:0] ExtIOLength    = 64'h10000000;
  localparam logic[63:0] DRAMLength     = 64'h40000000; // 1GByte of DDR (split between two chips on Genesys2)
// These peripheral lengths must be powers of 2, because of the way the I/O demux works
  localparam logic[63:0] BOOTLength     = 64'h10000;
  localparam logic[63:0] UARTLength     = 64'h10000;
  localparam logic[63:0] SPILength      = 64'h10000;
  localparam logic[63:0] EthernetLength = 64'h10000;
  localparam logic[63:0] GPIOLength     = 64'h10000;
  // Instantiate AXI protocol checkers
  localparam bit GenProtocolChecker = 1'b0;

  typedef enum logic [63:0] {
    DebugBase    = 64'h0000_0000,
    CLINTBase    = 64'h0200_0000,
    PLICBase     = 64'h0C00_0000,
    ExtIOBase    = 64'h4000_0000,
    DRAMBase     = 64'h8000_0000
  } soc_bus_start_t;

  typedef enum logic [63:0] {
    BOOTBase     = 64'h4000_0000,
    UARTBase     = 64'h4100_0000,
    SPIBase      = 64'h4200_0000,
    EthernetBase = 64'h4300_0000,
    GPIOBase     = 64'h4400_0000
  } soc_iobus_start_t;

  localparam NrRegion = 1;
  localparam logic [NrRegion-1:0][NB_PERIPHERALS-1:0] ValidRule = {{NrRegion * NB_PERIPHERALS}{1'b1}};

  localparam ariane_pkg::ariane_cfg_t ArianeSocCfg = '{
    RASDepth: 2,
    BTBEntries: 32,
    BHTEntries: 128,
    // idempotent region
    NrNonIdempotentRules:  0,
    NonIdempotentAddrBase: {64'b0},
    NonIdempotentLength:   {64'b0},
    NrExecuteRegionRules:  3,
    ExecuteRegionAddrBase: {DRAMBase,   BOOTBase,   DebugBase},
    ExecuteRegionLength:   {DRAMLength, BOOTLength, DebugLength},
    // cached region
    NrCachedRegionRules:    1,
    CachedRegionAddrBase:  {DRAMBase},
    CachedRegionLength:    {DRAMLength},
    //  cache config
    Axi64BitCompliant:      1'b1,
    SwapEndianess:          1'b0,
    // debug
    DmBaseAddress:          DebugBase
  };

endpackage
