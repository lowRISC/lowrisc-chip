`timescale 1ns / 1ps

`include "defs.vh"

`define STATE_IDLE   0
`define STATE_RDID   1
`define STATE_WAIT 2
`define STATE_WREN 3
`define STATE_BE 4
`define STATE_POLL_RFSR 5
`define STATE_PP 6
`define STATE_SE 7
`define STATE_WRVECR 8
`define STATE_RDVECR 9
`define STATE_RDSR 10
`define STATE_MIORDID 11


module qspi_mem_controller(
        input 		      clk,
        input 		      reset,
        input 		      trigger,
        input 		      quad,
        input [7:0] 	      cmd,
        input [(3+256)*8-1:0] data_send, //max: 256B page data + 3B address
        output reg [63:0]     readout,
        output reg 	      busy,
        output reg 	      error,

	output                clk_div,
        inout [3:0] 	      DQio,
        output 		      S
    );
    
    reg spi_trigger;
    wire spi_busy;
    
    reg [260*8-1:0] data_in;
    reg [8:0] data_in_count;
    wire [63:0] data_out;
    reg data_out_count;
    
    reg [35:0] delay_counter;
    
    spi_cmd sc(.clk(clk), .reset(reset), .trigger(spi_trigger), .busy(spi_busy), .quad(quad),
        .data_in_count(data_in_count), .data_out_count(data_out_count), .data_in(data_in), .data_out(data_out),
        .DQio(DQio[3:0]), .S(S), .clk_div(clk_div));
    
    
    reg [5:0] state;
    reg [5:0] nextstate;
    
    
    always @(posedge clk) begin
        if(reset) begin
            state <= `STATE_WAIT;
            nextstate <= `STATE_IDLE;
            spi_trigger <= 0;
            busy <= 1;
            error <= 0;
            readout <= 0;
        end
        
        else
            case(state)
                `STATE_IDLE: begin
                    if(trigger) begin
                        busy <= 1;
                        error <= 0;
                        case(cmd)
                            `CMD_RDID:
                                state <= `STATE_RDID;
                            `CMD_MIORDID:
                                state <= `STATE_MIORDID;
                            `CMD_WREN:
                                state <= `STATE_WREN;
                            `CMD_BE:
                                state <= `STATE_BE;
                            `CMD_SE:
                                state <= `STATE_SE;
                            `CMD_PP:
                                state <= `STATE_PP;
                            `CMD_WRVECR:
                                state <= `STATE_WRVECR;
                            `CMD_RDVECR:
                                state <= `STATE_RDVECR;
                            `CMD_RDSR:
                                state <= `STATE_RDSR;
                            default: begin
                                $display("ERROR: unknown command!");
                                $display(cmd);
                                $stop;
                            end
                        endcase
                    end else
                        busy <= 0;
                end
            
                `STATE_RDID: begin
                    data_in <= `CMD_RDID;
                    data_in_count <= 1;
                    data_out_count <= 1;
                    spi_trigger <= 1;
                    state <= `STATE_WAIT;
                    nextstate <= `STATE_IDLE;
                    if (quad == 1) begin
                        $display("ERROR: RDID is not available in quad mode!");
                        $stop;
                    end
                end                

                `STATE_MIORDID: begin
                    data_in <= `CMD_MIORDID;
                    data_in_count <= 1;
                    data_out_count <= 1;
                    spi_trigger <= 1;
                    state <= `STATE_WAIT;
                    nextstate <= `STATE_IDLE;
                    if (quad == 0) begin
                        $display("ERROR: MIORDID is only available in quad mode!");
                        $stop;
                    end
                end                

                `STATE_RDSR: begin
                    data_in <= `CMD_RDSR;
                    data_in_count <= 1;
                    data_out_count <= 1;
                    spi_trigger <= 1;
                    state <= `STATE_WAIT;
                    nextstate <= `STATE_IDLE;
                end                

                `STATE_WRVECR: begin
                    data_in <= {`CMD_WRVECR, data_send[7:0]};
                    data_in_count <= 2;
                    data_out_count <= 0;
                    spi_trigger <= 1;
                    state <= `STATE_WAIT;
                    nextstate <= `STATE_IDLE;
                end

                `STATE_RDVECR: begin
                    data_in <= `CMD_RDVECR;
                    data_in_count <= 1;
                    data_out_count <= 1;
                    spi_trigger <= 1;
                    state <= `STATE_WAIT;
                    nextstate <= `STATE_IDLE;
                end

                `STATE_WREN: begin
                    data_in <= `CMD_WREN;
                    data_in_count <= 1;
                    data_out_count <= 0;
                    spi_trigger <= 1;
                    state <= `STATE_WAIT;
                    nextstate <= `STATE_IDLE;
                end

                `STATE_BE: begin
                    data_in <= `CMD_BE;
                    data_in_count <= 1;
                    data_out_count <= 0;
                    spi_trigger <= 1;
                    state <= `STATE_WAIT;
                    nextstate <= `STATE_POLL_RFSR;
                    delay_counter <= `tBEmax*`input_freq;
                end

                `STATE_POLL_RFSR: begin
                    if (delay_counter == 0) begin // max delay timeout
                        state <= `STATE_IDLE;
                        error <= 1;
                    end else begin
                        if (readout[7] == 1) begin // operation finished successfully
                            state <= `STATE_IDLE;
                        end else begin // go on polling
                            data_in <= `CMD_RFSR;
                            data_in_count <= 1;
                            data_out_count <= 1;
                            spi_trigger <= 1;
                            delay_counter <= delay_counter - 1;
                            state <= `STATE_WAIT;
                            nextstate <= `STATE_POLL_RFSR;
                        end
                    end
                end                

                `STATE_WAIT: begin
                    spi_trigger <= 0;
                    if (!spi_trigger && !spi_busy) begin
                        state <= nextstate;
                        readout <= data_out;
                    end
                end
                
                `STATE_PP: begin
                    data_in <= {`CMD_PP, data_send};
                    data_in_count <= 260; // 256 bytes for data + 1 for command + 3 for address
                    data_out_count <= 0;
                    spi_trigger <= 1;
                    state <= `STATE_WAIT;
                    nextstate <= `STATE_POLL_RFSR;               
                    delay_counter <= `tPPmax*`input_freq;
               end

                `STATE_SE: begin
                    data_in <= {`CMD_SE, data_send[23:0]};
                    data_in_count <= 4; // 1 byte command + 3 bytes address
                    data_out_count <= 0;
                    spi_trigger <= 1;
                    state <= `STATE_WAIT;
                    nextstate <= `STATE_POLL_RFSR;               
                    delay_counter <= `tSEmax*`input_freq;
               end
                
            endcase
    end
    
    
endmodule
