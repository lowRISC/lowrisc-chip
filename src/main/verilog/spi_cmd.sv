`timescale 1ns / 1ps

`define STATE_IDLE 0
`define STATE_SEND 1
`define STATE_READ 2


module spi_cmd(
        //control interface
        input clk,
        input reset,
        input trigger,
        output reg busy,
        input [8:0] data_in_count,
        input data_out_count,
        input [260*8-1:0] data_in, //max len is: 256B data + 1B cmd + 3B addr
        output reg [63:0] data_out,
        input quad,
        
        //SPI interface
        output reg clk_div, 
        inout [3:0] DQio,
        output reg S 
    );
  
   wire [3:0] 	   DQi;
  
   wire [2:0] 	   width = quad?4:1;
    
   reg [11:0] 	   bit_cntr;

   reg [3:0] 	   DQ;
   reg 		   oe;
   reg [1:0] 	   state;        
    
    genvar n;
    generate for (n = 0; n < 4; n=n+1)
       IOBUF #(
        .DRIVE(12), // Specify the output drive strength
        .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
        .IOSTANDARD("DEFAULT"), // Specify the I/O standard
        .SLEW("SLOW") // Specify the output slew rate
     ) IOBUF_inst (
        .O(DQi[n]),     // Buffer output
        .IO(DQio[n]),   // Buffer inout port (connect directly to top-level port)
        .I(n==3 && !quad ? 1'b1 : DQ[n]),     // Buffer input
        .T(n==3 && !quad ? 1'b0 : !oe)      // 3-state enable input, high=input, low=output
     );
    endgenerate
    
    //during single IO operation, but in quad mode behaves as other IOs
    
     always @(posedge clk) begin
        if(reset) begin
            state <= `STATE_IDLE;
            oe <= 0;
            S <= 1;
            busy <= 1;
            clk_div <= 0;
            data_out <= 0;
	    DQ = 4'b1111;
        end else begin
            clk_div <= !clk_div;
	    if (clk_div)
	      begin
		 if(state==`STATE_READ) begin
                    if(quad)
                      data_out <= {data_out[3:0], DQi[3:0]};
                    else
                      data_out <= {data_out[6:0], DQi[1]};
		 end
	      end
	    else
              case(state)
                `STATE_IDLE: begin
                    if(trigger && !busy) begin
                        state<=`STATE_SEND;
                        busy <= 1;
                        bit_cntr <= data_in_count*8 - 1;   
                     end else begin
                        S <= 1;
                        busy <= 0;
                        clk_div <= 0;
                     end
                 end

                `STATE_SEND: begin
                    S <= 0;
                    oe <= 1;
                    if(quad) begin
                        DQ[0] <= data_in[bit_cntr-3];
                        DQ[1] <= data_in[bit_cntr-2];
                        DQ[2] <= data_in[bit_cntr-1];
                        DQ[3] <= data_in[bit_cntr];
                    end else
                         DQ[0] <= data_in[bit_cntr];
                    
                    if(bit_cntr>width-1) begin
                        bit_cntr <= bit_cntr - width;
                    end else begin
                        if(data_out_count>0) begin
                            state <= `STATE_READ;
                            bit_cntr <= 7+1; //7+1 because read happens on falling edge
                        end
                        else begin
                            state <= `STATE_IDLE;
                        end
                    end
                end

                `STATE_READ: begin
                    oe <= 0;
                    
                    if(bit_cntr>width-1) begin
                        bit_cntr <= bit_cntr - width;
                    end else begin
                        S <= 1;
                        state <= `STATE_IDLE;
                    end
                end
                
                
                default: begin
              
                end
              endcase
        end
    end 
       
endmodule
