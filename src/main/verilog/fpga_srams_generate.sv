
module data_arrays_0_ext(
  input wire RW0_clk,
  input wire [8:0] RW0_addr,
  input wire RW0_en,
  input wire RW0_wmode,
  input wire [31:0] RW0_wmask,
  input wire [255:0] RW0_wdata,
  output [255:0] RW0_rdata
);

  `ifdef FPGA_FULL
  
/* name=data_arrays_0_ext, width=256, depth=512, mask_gran=8, mask_seg=32, ports=['mrw'] FPGA special case */

   genvar 	 r;

   generate for (r = 0; r < 16; r=r+1)
     RAMB16_S9_S9
     RAMB16_S9_S9_inst
       (
        .CLKA   ( RW0_clk                  ),     // Port A Clock
        .DOA    ( RW0_rdata[r*16 +: 8]     ),     // Port A 1-bit Data Output
        .DOPA   (                          ),
        .ADDRA  ( {2'b00,RW0_addr}          ),     // Port A 14-bit Address input wire
        .DIA    ( RW0_wdata[r*16 +: 8]     ),     // Port A 1-bit Data input wire
        .DIPA   ( 1'b0                     ),
        .ENA    ( RW0_en                   ),     // Port A RAM Enable input wire
        .SSRA   ( 1'b0                     ),     // Port A Synchronous Set/Reset input wire
        .WEA    ( RW0_wmask[r*2]           ),     // Port A Write Enable input wire
        .CLKB   ( RW0_clk                  ),     // Port B Clock
        .DOB    ( RW0_rdata[r*16+8 +: 8]   ),     // Port B 1-bit Data Output
        .DOPB   (                          ),
        .ADDRB  ( {2'b01,RW0_addr}          ),     // Port B 14-bit Address input wire
        .DIB    ( RW0_wdata[r*16+8 +: 8]   ),     // Port B 1-bit Data input wire
        .DIPB   ( 1'b0                     ),
        .ENB    ( RW0_en                   ),     // Port B RAM Enable input wire
        .SSRB   ( 1'b0                     ),     // Port B Synchronous Set/Reset input wire
        .WEB    ( RW0_wmask[r*2+1]         )      // Port B Write Enable input wire
        );
   endgenerate

  `else // not FPGA_FULL
  reg reg_RW0_ren;
  reg [8:0] reg_RW0_addr;
  reg [255:0] ram [511:0];
  `ifdef RANDOMIZE_MEM_INIT
    integer initvar;
    initial begin
      #0.002 begin end
      for (initvar = 0; initvar < 512; initvar = initvar+1)
        ram[initvar] = {8 {$random}};
      reg_RW0_addr = {1 {$random}};
    end
  `endif
  integer i;
  always @(posedge RW0_clk)
    reg_RW0_ren <= RW0_en && !RW0_wmode;
  always @(posedge RW0_clk)
    if (RW0_en && !RW0_wmode) reg_RW0_addr <= RW0_addr;
  always @(posedge RW0_clk)
    if (RW0_en && RW0_wmode) begin
      if (RW0_wmask[0]) ram[RW0_addr][7:0] <= RW0_wdata[7:0];
      if (RW0_wmask[1]) ram[RW0_addr][15:8] <= RW0_wdata[15:8];
      if (RW0_wmask[2]) ram[RW0_addr][23:16] <= RW0_wdata[23:16];
      if (RW0_wmask[3]) ram[RW0_addr][31:24] <= RW0_wdata[31:24];
      if (RW0_wmask[4]) ram[RW0_addr][39:32] <= RW0_wdata[39:32];
      if (RW0_wmask[5]) ram[RW0_addr][47:40] <= RW0_wdata[47:40];
      if (RW0_wmask[6]) ram[RW0_addr][55:48] <= RW0_wdata[55:48];
      if (RW0_wmask[7]) ram[RW0_addr][63:56] <= RW0_wdata[63:56];
      if (RW0_wmask[8]) ram[RW0_addr][71:64] <= RW0_wdata[71:64];
      if (RW0_wmask[9]) ram[RW0_addr][79:72] <= RW0_wdata[79:72];
      if (RW0_wmask[10]) ram[RW0_addr][87:80] <= RW0_wdata[87:80];
      if (RW0_wmask[11]) ram[RW0_addr][95:88] <= RW0_wdata[95:88];
      if (RW0_wmask[12]) ram[RW0_addr][103:96] <= RW0_wdata[103:96];
      if (RW0_wmask[13]) ram[RW0_addr][111:104] <= RW0_wdata[111:104];
      if (RW0_wmask[14]) ram[RW0_addr][119:112] <= RW0_wdata[119:112];
      if (RW0_wmask[15]) ram[RW0_addr][127:120] <= RW0_wdata[127:120];
      if (RW0_wmask[16]) ram[RW0_addr][135:128] <= RW0_wdata[135:128];
      if (RW0_wmask[17]) ram[RW0_addr][143:136] <= RW0_wdata[143:136];
      if (RW0_wmask[18]) ram[RW0_addr][151:144] <= RW0_wdata[151:144];
      if (RW0_wmask[19]) ram[RW0_addr][159:152] <= RW0_wdata[159:152];
      if (RW0_wmask[20]) ram[RW0_addr][167:160] <= RW0_wdata[167:160];
      if (RW0_wmask[21]) ram[RW0_addr][175:168] <= RW0_wdata[175:168];
      if (RW0_wmask[22]) ram[RW0_addr][183:176] <= RW0_wdata[183:176];
      if (RW0_wmask[23]) ram[RW0_addr][191:184] <= RW0_wdata[191:184];
      if (RW0_wmask[24]) ram[RW0_addr][199:192] <= RW0_wdata[199:192];
      if (RW0_wmask[25]) ram[RW0_addr][207:200] <= RW0_wdata[207:200];
      if (RW0_wmask[26]) ram[RW0_addr][215:208] <= RW0_wdata[215:208];
      if (RW0_wmask[27]) ram[RW0_addr][223:216] <= RW0_wdata[223:216];
      if (RW0_wmask[28]) ram[RW0_addr][231:224] <= RW0_wdata[231:224];
      if (RW0_wmask[29]) ram[RW0_addr][239:232] <= RW0_wdata[239:232];
      if (RW0_wmask[30]) ram[RW0_addr][247:240] <= RW0_wdata[247:240];
      if (RW0_wmask[31]) ram[RW0_addr][255:248] <= RW0_wdata[255:248];
    end
  `ifdef RANDOMIZE_GARBAGE_ASSIGN
  reg [255:0] RW0_random;
  `ifdef RANDOMIZE_MEM_INIT
    initial begin
      #0.002 begin end
      RW0_random = {$random, $random, $random, $random, $random, $random, $random, $random};
      reg_RW0_ren = RW0_random[0];
    end
  `endif
  always @(posedge RW0_clk) RW0_random <= {$random, $random, $random, $random, $random, $random, $random, $random};
  assign RW0_rdata = reg_RW0_ren ? ram[reg_RW0_addr] : RW0_random[255:0];
  `else
  assign RW0_rdata = ram[reg_RW0_addr];
  `endif
  `endif // FPGA_FULL

endmodule

module tag_array_ext(
  input wire RW0_clk,
  input wire [5:0] RW0_addr,
  input wire RW0_en,
  input wire RW0_wmode,
  input wire [3:0] RW0_wmask,
  input wire [87:0] RW0_wdata,
  output [87:0] RW0_rdata
);

  
/* name=tag_array_ext, width=88, depth=64, mask_gran=22, mask_seg=4, ports=['mrw'] normal case */

  reg reg_RW0_ren;
  reg [5:0] reg_RW0_addr;
  reg [87:0] ram [63:0];
  `ifdef RANDOMIZE_MEM_INIT
    integer initvar;
    initial begin
      #0.002 begin end
      for (initvar = 0; initvar < 64; initvar = initvar+1)
        ram[initvar] = {3 {$random}};
      reg_RW0_addr = {1 {$random}};
    end
  `endif
  integer i;
  always @(posedge RW0_clk)
    reg_RW0_ren <= RW0_en && !RW0_wmode;
  always @(posedge RW0_clk)
    if (RW0_en && !RW0_wmode) reg_RW0_addr <= RW0_addr;
  always @(posedge RW0_clk)
    if (RW0_en && RW0_wmode) begin
      if (RW0_wmask[0]) ram[RW0_addr][21:0] <= RW0_wdata[21:0];
      if (RW0_wmask[1]) ram[RW0_addr][43:22] <= RW0_wdata[43:22];
      if (RW0_wmask[2]) ram[RW0_addr][65:44] <= RW0_wdata[65:44];
      if (RW0_wmask[3]) ram[RW0_addr][87:66] <= RW0_wdata[87:66];
    end
  `ifdef RANDOMIZE_GARBAGE_ASSIGN
  reg [95:0] RW0_random;
  `ifdef RANDOMIZE_MEM_INIT
    initial begin
      #0.002 begin end
      RW0_random = {$random, $random, $random};
      reg_RW0_ren = RW0_random[0];
    end
  `endif
  always @(posedge RW0_clk) RW0_random <= {$random, $random, $random};
  assign RW0_rdata = reg_RW0_ren ? ram[reg_RW0_addr] : RW0_random[87:0];
  `else
  assign RW0_rdata = ram[reg_RW0_addr];
  `endif

endmodule

module tag_array_0_ext(
  input wire RW0_clk,
  input wire [5:0] RW0_addr,
  input wire RW0_en,
  input wire RW0_wmode,
  input wire [3:0] RW0_wmask,
  input wire [83:0] RW0_wdata,
  output [83:0] RW0_rdata
);

  
/* name=tag_array_0_ext, width=84, depth=64, mask_gran=21, mask_seg=4, ports=['mrw'] normal case */

  reg reg_RW0_ren;
  reg [5:0] reg_RW0_addr;
  reg [83:0] ram [63:0];
  `ifdef RANDOMIZE_MEM_INIT
    integer initvar;
    initial begin
      #0.002 begin end
      for (initvar = 0; initvar < 64; initvar = initvar+1)
        ram[initvar] = {3 {$random}};
      reg_RW0_addr = {1 {$random}};
    end
  `endif
  integer i;
  always @(posedge RW0_clk)
    reg_RW0_ren <= RW0_en && !RW0_wmode;
  always @(posedge RW0_clk)
    if (RW0_en && !RW0_wmode) reg_RW0_addr <= RW0_addr;
  always @(posedge RW0_clk)
    if (RW0_en && RW0_wmode) begin
      if (RW0_wmask[0]) ram[RW0_addr][20:0] <= RW0_wdata[20:0];
      if (RW0_wmask[1]) ram[RW0_addr][41:21] <= RW0_wdata[41:21];
      if (RW0_wmask[2]) ram[RW0_addr][62:42] <= RW0_wdata[62:42];
      if (RW0_wmask[3]) ram[RW0_addr][83:63] <= RW0_wdata[83:63];
    end
  `ifdef RANDOMIZE_GARBAGE_ASSIGN
  reg [95:0] RW0_random;
  `ifdef RANDOMIZE_MEM_INIT
    initial begin
      #0.002 begin end
      RW0_random = {$random, $random, $random};
      reg_RW0_ren = RW0_random[0];
    end
  `endif
  always @(posedge RW0_clk) RW0_random <= {$random, $random, $random};
  assign RW0_rdata = reg_RW0_ren ? ram[reg_RW0_addr] : RW0_random[83:0];
  `else
  assign RW0_rdata = ram[reg_RW0_addr];
  `endif

endmodule

module data_arrays_0_0_ext(
  input wire RW0_clk,
  input wire [8:0] RW0_addr,
  input wire RW0_en,
  input wire RW0_wmode,
  input wire [3:0] RW0_wmask,
  input wire [127:0] RW0_wdata,
  output [127:0] RW0_rdata
);

  `ifdef FPGA_FULL
  
/* name=data_arrays_0_0_ext, width=128, depth=512, mask_gran=32, mask_seg=4, ports=['mrw'] FPGA special case */

   genvar 	 r;
   
   generate for (r = 0; r < 4; r=r+1)
     RAMB16_S36
     RAMB16_S36_inst
       (
        .CLK   ( RW0_clk                  ),     // Port A Clock
        .DO    ( RW0_rdata[r*32 +: 32]    ),     // Port A 1-bit Data Output
        .DOP   (                          ),
        .ADDR  ( RW0_addr                 ),     // Port A 14-bit Address input wire
        .DI    ( RW0_wdata[r*32 +: 32]    ),     // Port A 1-bit Data input wire
        .DIP   ( 1'b0                     ),
        .EN    ( RW0_en                   ),     // Port A RAM Enable input wire
        .SSR   ( 1'b0                     ),     // Port A Synchronous Set/Reset input wire
        .WE    ( RW0_wmask[r]             )      // Port A Write Enable input wire
        );
   endgenerate

  `else // not FPGA_FULL
  reg reg_RW0_ren;
  reg [8:0] reg_RW0_addr;
  reg [127:0] ram [511:0];
  `ifdef RANDOMIZE_MEM_INIT
    integer initvar;
    initial begin
      #0.002 begin end
      for (initvar = 0; initvar < 512; initvar = initvar+1)
        ram[initvar] = {4 {$random}};
      reg_RW0_addr = {1 {$random}};
    end
  `endif
  integer i;
  always @(posedge RW0_clk)
    reg_RW0_ren <= RW0_en && !RW0_wmode;
  always @(posedge RW0_clk)
    if (RW0_en && !RW0_wmode) reg_RW0_addr <= RW0_addr;
  always @(posedge RW0_clk)
    if (RW0_en && RW0_wmode) begin
      if (RW0_wmask[0]) ram[RW0_addr][31:0] <= RW0_wdata[31:0];
      if (RW0_wmask[1]) ram[RW0_addr][63:32] <= RW0_wdata[63:32];
      if (RW0_wmask[2]) ram[RW0_addr][95:64] <= RW0_wdata[95:64];
      if (RW0_wmask[3]) ram[RW0_addr][127:96] <= RW0_wdata[127:96];
    end
  `ifdef RANDOMIZE_GARBAGE_ASSIGN
  reg [127:0] RW0_random;
  `ifdef RANDOMIZE_MEM_INIT
    initial begin
      #0.002 begin end
      RW0_random = {$random, $random, $random, $random};
      reg_RW0_ren = RW0_random[0];
    end
  `endif
  always @(posedge RW0_clk) RW0_random <= {$random, $random, $random, $random};
  assign RW0_rdata = reg_RW0_ren ? ram[reg_RW0_addr] : RW0_random[127:0];
  `else
  assign RW0_rdata = ram[reg_RW0_addr];
  `endif
  `endif // FPGA_FULL

endmodule

module mem_ext(
  input wire W0_clk,
  input wire [24:0] W0_addr,
  input wire W0_en,
  input wire [63:0] W0_data,
  input wire [7:0] W0_mask,
  input wire R0_clk,
  input wire [24:0] R0_addr,
  input wire R0_en,
  output [63:0] R0_data
);

  
/* name=mem_ext, width=64, depth=33554432, mask_gran=8, mask_seg=8, ports=['mwrite', 'read'] normal case */

  reg reg_R0_ren;
  reg [24:0] reg_R0_addr;
  reg [63:0] ram [33554431:0];
  `ifdef RANDOMIZE_MEM_INIT
    integer initvar;
    initial begin
      #0.002 begin end
      for (initvar = 0; initvar < 33554432; initvar = initvar+1)
        ram[initvar] = {2 {$random}};
      reg_R0_addr = {1 {$random}};
    end
  `endif
  integer i;
  always @(posedge R0_clk)
    reg_R0_ren <= R0_en;
  always @(posedge R0_clk)
    if (R0_en) reg_R0_addr <= R0_addr;
  always @(posedge W0_clk)
    if (W0_en) begin
      if (W0_mask[0]) ram[W0_addr][7:0] <= W0_data[7:0];
      if (W0_mask[1]) ram[W0_addr][15:8] <= W0_data[15:8];
      if (W0_mask[2]) ram[W0_addr][23:16] <= W0_data[23:16];
      if (W0_mask[3]) ram[W0_addr][31:24] <= W0_data[31:24];
      if (W0_mask[4]) ram[W0_addr][39:32] <= W0_data[39:32];
      if (W0_mask[5]) ram[W0_addr][47:40] <= W0_data[47:40];
      if (W0_mask[6]) ram[W0_addr][55:48] <= W0_data[55:48];
      if (W0_mask[7]) ram[W0_addr][63:56] <= W0_data[63:56];
    end
  `ifdef RANDOMIZE_GARBAGE_ASSIGN
  reg [63:0] R0_random;
  `ifdef RANDOMIZE_MEM_INIT
    initial begin
      #0.002 begin end
      R0_random = {$random, $random};
      reg_R0_ren = R0_random[0];
    end
  `endif
  always @(posedge R0_clk) R0_random <= {$random, $random};
  assign R0_data = reg_R0_ren ? ram[reg_R0_addr] : R0_random[63:0];
  `else
  assign R0_data = ram[reg_R0_addr];
  `endif

endmodule

module mem_0_ext(
  input wire W0_clk,
  input wire [8:0] W0_addr,
  input wire W0_en,
  input wire [63:0] W0_data,
  input wire [7:0] W0_mask,
  input wire R0_clk,
  input wire [8:0] R0_addr,
  input wire R0_en,
  output [63:0] R0_data
);

  
/* name=mem_0_ext, width=64, depth=512, mask_gran=8, mask_seg=8, ports=['mwrite', 'read'] normal case */

  reg reg_R0_ren;
  reg [8:0] reg_R0_addr;
  reg [63:0] ram [511:0];
  `ifdef RANDOMIZE_MEM_INIT
    integer initvar;
    initial begin
      #0.002 begin end
      for (initvar = 0; initvar < 512; initvar = initvar+1)
        ram[initvar] = {2 {$random}};
      reg_R0_addr = {1 {$random}};
    end
  `endif
  integer i;
  always @(posedge R0_clk)
    reg_R0_ren <= R0_en;
  always @(posedge R0_clk)
    if (R0_en) reg_R0_addr <= R0_addr;
  always @(posedge W0_clk)
    if (W0_en) begin
      if (W0_mask[0]) ram[W0_addr][7:0] <= W0_data[7:0];
      if (W0_mask[1]) ram[W0_addr][15:8] <= W0_data[15:8];
      if (W0_mask[2]) ram[W0_addr][23:16] <= W0_data[23:16];
      if (W0_mask[3]) ram[W0_addr][31:24] <= W0_data[31:24];
      if (W0_mask[4]) ram[W0_addr][39:32] <= W0_data[39:32];
      if (W0_mask[5]) ram[W0_addr][47:40] <= W0_data[47:40];
      if (W0_mask[6]) ram[W0_addr][55:48] <= W0_data[55:48];
      if (W0_mask[7]) ram[W0_addr][63:56] <= W0_data[63:56];
    end
  `ifdef RANDOMIZE_GARBAGE_ASSIGN
  reg [63:0] R0_random;
  `ifdef RANDOMIZE_MEM_INIT
    initial begin
      #0.002 begin end
      R0_random = {$random, $random};
      reg_R0_ren = R0_random[0];
    end
  `endif
  always @(posedge R0_clk) R0_random <= {$random, $random};
  assign R0_data = reg_R0_ren ? ram[reg_R0_addr] : R0_random[63:0];
  `else
  assign R0_data = ram[reg_R0_addr];
  `endif

endmodule
