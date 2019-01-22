
module picorv32_pcpi_mul_opt(
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
    logic instr_mul;
    logic instr_mulh;
    logic instr_mulhsu;
    logic instr_mulhu;
    logic instr_any_mul;
    logic instr_any_mulh;
    logic instr_rs1_signed;
    logic instr_rs2_signed;
    logic pcpi_wait_q;
    logic mul_start;
    logic [63:0] rs1;
    logic [63:0] rs2;
    logic [63:0] rd;
    logic [63:0] rdx;
    logic [63:0] next_rs1;
    logic [63:0] next_rs2;
    logic [63:0] this_rs2;
    logic [63:0] next_rd;
    logic [63:0] next_rdx;
    logic [63:0] next_rdt;
    logic [6:0] mul_counter;
    logic mul_waiting;
    logic mul_finish;
    logic [31:0] i;
    logic [31:0] j;
    logic __Vconcswap1;
    logic [3:0] __Vconcswap2;
    assign instr_any_mul = (instr_mul | (instr_mulh | (instr_mulhsu | instr_mulhu)));
    assign instr_any_mulh = (instr_mulh | (instr_mulhsu | instr_mulhu));
    assign instr_rs1_signed = (instr_mulh | instr_mulhsu);
    assign instr_rs2_signed = instr_mulh;
    assign mul_start = (pcpi_wait & ( ~ pcpi_wait_q));
    
/* example/picorv32_pcpi_mul.v:31 */
always@(posedge clk) 
        begin
        instr_mul <= 1'h0;
        instr_mulh <= 1'h0;
        instr_mulhsu <= 1'h0;
        instr_mulhu <= 1'h0;
        if (((resetn & pcpi_valid) & (7'h33 == pcpi_insn[6:0])) & (7'h1 == pcpi_insn[31:25])) 
            begin
            case(pcpi_insn[14:12])
                3'h0:
                    begin
                    instr_mul <= 1'h1;
                    end
                3'h1:
                    begin
                    instr_mulh <= 1'h1;
                    end
                3'h2:
                    begin
                    instr_mulhsu <= 1'h1;
                    end
                3'h3:
                    begin
                    instr_mulhu <= 1'h1;
                    end
                endcase
            end;
        pcpi_wait <= instr_any_mul;
        pcpi_wait_q <= pcpi_wait;
        end
    
/* example/picorv32_pcpi_mul.v:59 */
always@* 
        begin
        next_rd = rd;
        next_rdx = rdx;
        next_rs1 = rs1;
        next_rs2 = rs2;
        for(i=32'sh0;32'sh1 > i;i=i+32'sh1)
            begin
                begin
                this_rs2 = (next_rs1[0]?next_rs2:64'h0);
                
                    begin
                    next_rdt = 64'h0;
                    for(j=32'sh0;32'sh40 > j;j=j+32'sh4)
                        begin
                        __Vconcswap1 = ((({1'b0,next_rd[j[5:0]+:4]}+{1'b0,next_rdx[j[5:0]+:4]})+{1'b0,this_rs2[j[5:0]+:4]})>>4);
                        __Vconcswap2 = ((next_rd[j[5:0]+:4]+next_rdx[j[5:0]+:4])+this_rs2[j[5:0]+:4]);
                        next_rdt[(6'h3+j[5:0])] = __Vconcswap1;
                        next_rd[j[5:0]+:4] = __Vconcswap2;
                        
                        end;
                    next_rdx = (next_rdt << 32'sh1);
                    end;
                next_rs1 = (next_rs1 >> 32'sh1);
                next_rs2 = (next_rs2 << 32'sh1);
                end;
            
            end
        end
    
/* example/picorv32_pcpi_mul.v:83 */
always@(posedge clk) 
        begin
        mul_finish <= 1'h0;
        if (resetn) 
            begin
            if (mul_waiting) 
                begin
                if (instr_rs1_signed) 
                    begin
                    rs1 <= $signed(pcpi_rs1);
                    end
                else
                    begin
                    rs1 <= {1'b0,pcpi_rs1};
                    end;
                if (instr_rs2_signed) 
                    begin
                    rs2 <= $signed(pcpi_rs2);
                    end
                else
                    begin
                    rs2 <= {1'b0,pcpi_rs2};
                    end;
                rd <= 64'h0;
                rdx <= 64'h0;
                mul_counter <= ((instr_any_mulh?32'h3e:32'h1e)>>0);
                mul_waiting <= ( ~ mul_start);
                end
            else
                begin
                rd <= next_rd;
                rdx <= next_rdx;
                rs1 <= next_rs1;
                rs2 <= next_rs2;
                mul_counter <= (mul_counter-7'h1);
                if (mul_counter[6]) 
                    begin
                    mul_finish <= 1'h1;
                    mul_waiting <= 1'h1;
                    end
                end
            end
        else
            begin
            mul_waiting <= 1'h1;
            end
        end
    
/* example/picorv32_pcpi_mul.v:117 */
always@(posedge clk) 
        begin
        pcpi_wr <= 1'h0;
        pcpi_ready <= 1'h0;
        if (mul_finish & resetn) 
            begin
            pcpi_wr <= 1'h1;
            pcpi_ready <= 1'h1;
            pcpi_rd <= ((instr_any_mulh?(rd >> 32'sh20):rd)>>0);
            end
        end
    endmodule
