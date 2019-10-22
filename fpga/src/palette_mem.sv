
module palette_mem(clka, clkb, dina, dinb, addra, addrb, wea, web, douta, doutb, ena, enb);

   input wire clka, clkb;
   input [31:0] dina;
   input [31:0] dinb;
   input [8:0] addra;
   input [8:0] addrb;
   input        wea;
   input        web;
   input        ena, enb;
   output [31:0]      douta;
   output [31:0]      doutb;

`ifdef FPGA_TARGET_XILINX
   
RAMB16_S36_S36
     RAMB16_S36_S36_inst
       (
        .CLKA   ( clka                     ),     // Port A Clock
        .DOA    ( douta                    ),     // Port A 1-bit Data Output
        .DOPA   (                          ),
        .ADDRA  ( addra                    ),     // Port A 14-bit Address Input
        .DIA    ( dina                     ),     // Port A 1-bit Data Input
        .DIPA   ( 4'b0                     ),
        .ENA    ( ena                      ),     // Port A RAM Enable Input
        .SSRA   ( 1'b0                     ),     // Port A Synchronous Set/Reset Input
        .WEA    ( wea                      ),     // Port A Write Enable Input
        .CLKB   ( clkb                     ),     // Port B Clock
        .DOB    ( doutb                    ),     // Port B 1-bit Data Output
        .DOPB   (                          ),
        .ADDRB  ( addrb                    ),     // Port B 14-bit Address Input
        .DIB    ( dinb                     ),     // Port B 1-bit Data Input
        .DIPB   ( 4'b0                     ),
        .ENB    ( enb                      ),     // Port B RAM Enable Input
        .SSRB   ( 1'b0                     ),     // Port B Synchronous Set/Reset Input
        .WEB    ( web                      )      // Port B Write Enable Input
        );

`else // !`ifdef FPGA

infer_dpram #(.RAM_SIZE(9), .BYTE_WIDTH(8)) ram1 // RAM_SIZE is in words
(
.ram_clk_a(clka),
.ram_en_a(ena),
.ram_we_a(wea),
.ram_addr_a(addra),
.ram_wrdata_a(dina),
.ram_rddata_a(douta),
.ram_clk_b(clkb),
.ram_en_b(enb),
.ram_we_b(web),
.ram_addr_b(addrb),
.ram_wrdata_b(dinb),
.ram_rddata_b(doutb)
 );
   
`endif
   
endmodule // dualmem
