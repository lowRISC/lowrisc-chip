module jtag_addr(output reg [1:0] OP, output reg INC, output reg [31:0] ADDR,
input wire CAPTURE, RESET, RUNTEST, SEL, SHIFT, TDI, TMS, UPDATE, TCK,
output wire TDO);

parameter wid = 35;

reg [wid-1:0] SR;

assign TDO = SR[0];
   
always @(posedge TCK)
       begin
       if (RESET)
           begin
           SR = 0;
           WR = 0;
	   INC = 0;
           ADDR = 0;
           end
       else if (SEL)
           begin
           if (CAPTURE)
               begin
               SR = {INC,OP,ADDR};
               end
           if (UPDATE)
               begin
                  {INC,OP,ADDR} = SR;
               end
           if (SHIFT)
             begin
                SR = {TDI,SR[wid-1:1]};
               end
           end
       end

endmodule
