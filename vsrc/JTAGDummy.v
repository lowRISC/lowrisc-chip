// See LICENSE.SiFive for license details.

module JTAGDummy(
   // LED and DIP switch
  output [7:0]  o_led,
  input         clk_p,
  input         rst_top
  );
    
     wire          rxd;
     wire          txd;
     wire          rts;
     wire          cts;
     wire         flash_ss;
     wire [3:0]   flash_io;
     wire         spi_cs;
     wire         spi_sclk;
     wire         spi_mosi;
     wire         spi_miso;
     // 4-bit full SD interface
     wire         sd_sclk;
     wire         sd_detect;
     wire [3:0]   sd_dat;
     wire         sd_cmd;
     wire         sd_reset;
  
     // LED and DIP switch
     wire [7:0]  o_led;
     wire  [3:0]  i_dip;
  
     // push button array
     wire         GPIO_SW_C;
     wire         GPIO_SW_W;
     wire         GPIO_SW_E;
     wire         GPIO_SW_N;
     wire         GPIO_SW_S;
  
     //keyboard
     wire         PS2_CLK;
     wire         PS2_DATA;
  
    // display
     wire        VGA_HS_O;
     wire        VGA_VS_O;
     wire [3:0]  VGA_RED_O;
     wire [3:0]  VGA_BLUE_O;
     wire [3:0]  VGA_GREEN_O;
   //! Ethernet MAC PHY interface signals
   wire [1:0]   i_erxd; // RMII receive data
   wire         i_erx_dv; // PHY data valid
   wire         i_erx_er; // PHY coding error
   wire         i_emdint; // PHY interrupt in active low
   wire         o_erefclk; // RMII clock out
   wire  [1:0]  o_etxd; // RMII transmit data
   wire         o_etx_en; // RMII transmit enable
   wire         o_emdc; // MDIO clock
   wire         io_emdio; // MDIO wire
   wire         o_erstn; // PHY reset active low

`ifdef verilator
  wire         clk = clk_p;
  wire         rst = ~rst_top;
`else
  wire clk_locked;
  wire         clk;
  wire         rst = ~clk_locked;
  
   clk_wiz_2 clk_gen
     (
      .clk_in1       ( clk_p         ), // 100 MHz onboard
      .clk_out1      ( clk           ), // 25 MHz
      .resetn        ( rst_top       ),
      .locked        ( clk_locked    )
      );
`endif // !`ifdef verilator

   chip_top
   DUT
     (
      .*,
      .clk_p        ( clk       ),
      .clk_n        ( !clk      ),
      .rst_top      ( rst       )
      );
 
endmodule
