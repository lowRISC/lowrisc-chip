module jtag_rom(input wire INC, input wire [1:0] OPIN, input wire [31:0] ADDR0,
input wire CAPTURE, RESET, RUNTEST, SEL, SHIFT, TDI, TMS, UPDATE, TCK,
output wire TDO, output reg [1:0] OP, output reg VALID, output reg [31:0] TO_MEM, output reg [31:0] ADDR,
input wire [31:0] FROM_MEM );

parameter dataw = 32;

reg [dataw-1:0] SR;

reg  INCEN;
reg [7:0] CNT;

assign TDO = SR[0];
	     
always @(posedge TCK)
       begin
       if (RESET)
           begin
           CNT = 0;
           SR = 0;
           WREN = 0;
           TO_MEM = 0;
	       ADDR = 0;
	       INCEN = 1'b0;
           end
       else if (SEL)
           begin
           if (CAPTURE)
               begin
               CNT = 0;
               SR = ADDR0;
	           OP = OPIN;
	           INCEN = 1'b0;
	           ADDR = ADDR0;
               end
           if (UPDATE)
               begin
                  if (WR)
                      TO_MEM = SR;
                  WREN = WR;
        		  INCEN = 1'b0;
                  CNT = 0;
               end
           if (SHIFT)
             begin
		     ADDR = ADDR + {INCEN,2'b0};
		     INCEN = 1'b0;
             VALID = 1'b0;
             SR = {TDI,SR[dataw-1:1]};
             CNT = CNT + 1;
             if (CNT == dataw)
                  begin
                     if (WR)
                        TO_MEM = SR;
		             else
		                SR = FROM_MEM;
                     VALID = 1'b1;
                     INCEN = INC;
                     CNT = 0;
                  end
               end
           end
       end
      // End of BSCANE2_inst instantiation

endmodule // unmatched end(function|task|module|primitive|interface|package|class|clocking)
