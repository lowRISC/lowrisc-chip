`define vstrt 32'h87FE0000
`define vsiz 32'h2000000
`define vstop (`vstrt+`vsiz)

module cnvmem;

   integer i, j, fd, first, last;
   
   reg [7:0] byt, mem[`vstrt:`vstop];
   reg [127:0] mem2[0:'hfff];

   initial
     begin
        $readmemh("cnvmem.mem", mem);
        i = `vstrt;
	while ((i < `vstop) && (1'bx === ^mem[i]))
	  i=i+16;
        first = i;
        i = `vstop;
	while ((i >= `vstrt) && (1'bx === ^mem[i]))
	  i=i-16;
        last = (i+16);
        if (last < first + 'H10000)
             last = first + 'H10000;
        for (i = i+1; i < last; i=i+1)
          mem[i] = 0;
        $display("First = %X, Last = %X", first, last-1);
        for (i = first; i < last; i=i+1)
          if (1'bx === ^mem[i]) mem[i] = 0;
        
        for (i = first; i < last; i=i+16)
          begin
             mem2[(i/16)&'hFFF] = {mem[i+15],mem[i+14],mem[i+13],mem[i+12],
                                   mem[i+11],mem[i+10],mem[i+9],mem[i+8],
                                   mem[i+7],mem[i+6],mem[i+5],mem[i+4],
                                   mem[i+3],mem[i+2],mem[i+1],mem[i+0]};
          end
        fd = $fopen("boot.mem", "w");
        for (i = 0; i <= 'hfff; i=i+1)
          $fdisplay(fd, "%32x", mem2[i]);
        $fclose(fd);
        fd = $fopen("bootram.sv", "w");
        $fdisplay(fd, "/* Copyright 2018 ETH Zurich and University of Bologna.");
        $fdisplay(fd, " * Copyright and related rights are licensed under the Solderpad Hardware");
        $fdisplay(fd, " * License, Version 0.51 (the %cLicense%c); you may not use this file except in", 34, 34);
        $fdisplay(fd, " * compliance with the License.  You may obtain a copy of the License at");
        $fdisplay(fd, " * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law");
        $fdisplay(fd, " * or agreed to in writing, software, hardware and materials distributed under");
        $fdisplay(fd, " * this License is distributed on an %cAS IS%c BASIS, WITHOUT WARRANTIES OR", 34, 34);
        $fdisplay(fd, " * CONDITIONS OF ANY KIND, either express or implied. See the License for the");
        $fdisplay(fd, " * specific language governing permissions and limitations under the License.");
        $fdisplay(fd, " *");
        $fdisplay(fd, " * File: $filename.v");
        $fdisplay(fd, " *");
        $fdisplay(fd, " * Description: Auto-generated bootrom");
        $fdisplay(fd, " */");
        $fdisplay(fd, "");
        $fdisplay(fd, "// Auto-generated code");
        $fdisplay(fd, "module bootram (");
        $fdisplay(fd, "   input  logic         clk_i,");
        $fdisplay(fd, "   input  logic         req_i,");
        $fdisplay(fd, "   input  logic         we_i,");
        $fdisplay(fd, "   input  logic [63:0]  addr_i,");
        $fdisplay(fd, "   input  logic [7:0]   be_i,");
        $fdisplay(fd, "   input  logic [63:0]  wdata_i,");
        $fdisplay(fd, "   output logic [63:0]  rdata_o");
        $fdisplay(fd, ");");
        $fdisplay(fd, "");
        $fdisplay(fd, "   localparam BRAM_SIZE          = 16;        // 2^16 -> 64 KB");
        $fdisplay(fd, "   localparam BRAM_WIDTH         = 128;       // always 128-bit wide");
        $fdisplay(fd, "   localparam BRAM_LINE          = 2 ** BRAM_SIZE / (BRAM_WIDTH/8);");
        $fdisplay(fd, "   localparam BRAM_OFFSET_BITS   = $clog2(64/8);");
        $fdisplay(fd, "   localparam BRAM_ADDR_LSB_BITS = $clog2(BRAM_WIDTH / 64);");
        $fdisplay(fd, "   localparam BRAM_ADDR_BLK_BITS = BRAM_SIZE - BRAM_ADDR_LSB_BITS - BRAM_OFFSET_BITS;");
        $fdisplay(fd, "");
        $fdisplay(fd, "   initial assert (BRAM_OFFSET_BITS < 7) else $fatal(1, %cDo not support BRAM AXI width > 64-bit!%c);", 34, 34);
        $fdisplay(fd, "");
        $fdisplay(fd, "   // BRAM controller");
        $fdisplay(fd, "   wire [7:0] ram_we = we_i ? be_i : 8'b0;");
        $fdisplay(fd, "");
        $fdisplay(fd, "   reg   [BRAM_WIDTH-1:0]         ram [0 : BRAM_LINE-1] = {");
        for (i = 0; i <= 'hfff; i=i+1)
        $fdisplay(fd, "128'h%32x%s /* %d */", mem2[i], i < 'hfff ? "," : "", i[11:0]);
        $fdisplay(fd, "    };");
        $fdisplay(fd, "");
        $fdisplay(fd, "   logic [BRAM_ADDR_BLK_BITS-1:0] ram_block_addr, ram_block_addr_delay;");
        $fdisplay(fd, "   logic [BRAM_ADDR_LSB_BITS-1:0] ram_lsb_addr, ram_lsb_addr_delay;");
        $fdisplay(fd, "   logic [BRAM_WIDTH/8-1:0]       ram_we_full;");
        $fdisplay(fd, "   logic [BRAM_WIDTH-1:0]         ram_wrdata_full, ram_rddata_full;");
        $fdisplay(fd, "   int                            ram_rddata_shift, ram_we_shift;");
        $fdisplay(fd, "");
        $fdisplay(fd, "   assign ram_block_addr = addr_i >> BRAM_ADDR_LSB_BITS + BRAM_OFFSET_BITS;");
        $fdisplay(fd, "   assign ram_lsb_addr = addr_i >> BRAM_OFFSET_BITS;");
        $fdisplay(fd, "   assign ram_we_shift = ram_lsb_addr << BRAM_OFFSET_BITS; // avoid ISim error");
        $fdisplay(fd, "   assign ram_we_full = ram_we << ram_we_shift;");
        $fdisplay(fd, "   assign ram_wrdata_full = {(BRAM_WIDTH / 64){wdata_i}};");
        $fdisplay(fd, "");
        $fdisplay(fd, "   always @(posedge clk_i)");
        $fdisplay(fd, "    begin");
        $fdisplay(fd, "     if (req_i) begin");
        $fdisplay(fd, "        ram_block_addr_delay <= ram_block_addr;");
        $fdisplay(fd, "        ram_lsb_addr_delay <= ram_lsb_addr;");
        $fdisplay(fd, "        foreach (ram_we_full[i])");
        $fdisplay(fd, "          if(ram_we_full[i]) ram[ram_block_addr][i*8 +:8] <= ram_wrdata_full[i*8 +: 8];");
        $fdisplay(fd, "     end");
        $fdisplay(fd, "    end");
        $fdisplay(fd, "");
        $fdisplay(fd, "   assign ram_rddata_full = ram[ram_block_addr_delay];");
        $fdisplay(fd, "   assign ram_rddata_shift = ram_lsb_addr_delay << (BRAM_OFFSET_BITS + 3); // avoid ISim error");
        $fdisplay(fd, "   assign rdata_o = ram_rddata_full >> ram_rddata_shift;");
        $fdisplay(fd, "");
        $fdisplay(fd, "endmodule");
        $fdisplay(fd, "");
        $fclose(fd);
        fd = $fopen("boot.bin", "w");
        for (i = 0; i <= 'hfff; i=i+1)
          begin
             for (j = 0; j < 128; j=j+8)
               begin
                  byt = mem2[i] >> j;
                  $fwrite(fd, "%c", byt);
               end
          end
        $fclose(fd);
     end
   
endmodule // cnvmem
