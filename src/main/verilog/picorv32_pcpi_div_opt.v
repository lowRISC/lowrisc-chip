
module picorv32_pcpi_div_opt(
    input logic clk,
    input logic resetn,
    input logic pcpi_valid,
    input logic[31:0] pcpi_insn,
    input logic[31:0] pcpi_rs1,
    input logic[31:0] pcpi_rs2,
    output logic pcpi_wr,
    output logic[31:0] pcpi_rd,
    output logic pcpi_wait,
    output logic pcpi_ready);
    logic instr_div;
    logic instr_divu;
    logic instr_rem;
    logic instr_remu;
    logic instr_any_div_rem;
    logic pcpi_wait_q;
    logic start;
    logic [31:0] dividend;
    logic [62:0] divisor;
    logic [31:0] quotient;
    logic [31:0] quotient_msk;
    logic running;
    logic outsign;
    assign instr_any_div_rem = (instr_div | (instr_divu | (instr_rem | instr_remu)));
    assign start = (pcpi_wait & ( ~ pcpi_wait_q));
    
/* example/picorv32_pcpi_div.v:24 */
always@(posedge clk) 
        begin
        instr_div <= 1'h0;
        instr_divu <= 1'h0;
        instr_rem <= 1'h0;
        instr_remu <= 1'h0;
        if ((((resetn & pcpi_valid) & ( ~ pcpi_ready)) & (7'h33 == pcpi_insn[6:0])) & (7'h1 == pcpi_insn[31:25])) 
            begin
            case(pcpi_insn[14:12])
                3'h4:
                    begin
                    instr_div <= 1'h1;
                    end
                3'h5:
                    begin
                    instr_divu <= 1'h1;
                    end
                3'h6:
                    begin
                    instr_rem <= 1'h1;
                    end
                3'h7:
                    begin
                    instr_remu <= 1'h1;
                    end
                endcase
            end;
        pcpi_wait <= (instr_any_div_rem & resetn);
        pcpi_wait_q <= (pcpi_wait & resetn);
        end
    
/* example/picorv32_pcpi_div.v:50 */
always@(posedge clk) 
        begin
        pcpi_ready <= 1'h0;
        pcpi_wr <= 1'h0;
        pcpi_rd <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        if (resetn) 
            begin
            if (start) 
                begin
                running <= 1'h1;
                if ((instr_div | instr_rem) & pcpi_rs1[31]) 
                    begin
                    dividend <= ( - pcpi_rs1);
                    end
                else
                    begin
                    dividend <= pcpi_rs1;
                    end;
                divisor <= ((((instr_div | instr_rem) & pcpi_rs2[31])?( - {1'b0,pcpi_rs2}):{1'b0,pcpi_rs2}) << 32'sh1f);
                outsign <= (((instr_div & (pcpi_rs1[31] != pcpi_rs2[31])) & ( | pcpi_rs2)) | (instr_rem & pcpi_rs1[31]));
                quotient <= 32'sh0;
                quotient_msk <= 32'h80000000;
                end
            else
                begin
                if (( ~ ( | quotient_msk)) & running) 
                    begin
                    running <= 1'h0;
                    pcpi_ready <= 1'h1;
                    pcpi_wr <= 1'h1;
                    if (instr_div | instr_divu) 
                        begin
                        pcpi_rd <= (outsign?( - quotient):quotient);
                        end
                    else
                        begin
                        pcpi_rd <= (outsign?( - dividend):dividend);
                        end
                    end
                else
                    begin
                    if (divisor <= {1'b0,dividend}) 
                        begin
                        dividend <= (dividend-divisor[31:0]);
                        quotient <= (quotient | quotient_msk);
                        end;
                    divisor <= (divisor >> 32'sh1);
                    quotient_msk <= (quotient_msk >> 32'sh1);
                    end
                end
            end
        else
            begin
            running <= 1'h0;
            end
        end
    endmodule
