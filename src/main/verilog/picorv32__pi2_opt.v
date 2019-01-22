
module picorv32__pi2_opt(
    input logic clk,
    input logic resetn,
    input wire [31:0] io_reset_vector,
    output logic trap,
    output logic mem_valid,
    output logic mem_instr,
    input logic mem_ready,
    output logic[31:0] mem_addr,
    output logic[31:0] mem_wdata,
    output logic[3:0] mem_wstrb,
    input logic[31:0] mem_rdata,
    output logic mem_la_read,
    output logic mem_la_write,
    output logic[31:0] mem_la_addr,
    output logic[31:0] mem_la_wdata,
    output logic[3:0] mem_la_wstrb,
    output logic pcpi_valid,
    output logic[31:0] pcpi_insn,
    output logic[31:0] pcpi_rs1,
    output logic[31:0] pcpi_rs2,
    input logic pcpi_wr,
    input logic[31:0] pcpi_rd,
    input logic pcpi_wait,
    input logic pcpi_ready,
    input logic[31:0] irq,
    output logic[31:0] eoi,
    output logic[31:0] dbg_reg_x0,
    output logic[31:0] dbg_reg_x1,
    output logic[31:0] dbg_reg_x2,
    output logic[31:0] dbg_reg_x3,
    output logic[31:0] dbg_reg_x4,
    output logic[31:0] dbg_reg_x5,
    output logic[31:0] dbg_reg_x6,
    output logic[31:0] dbg_reg_x7,
    output logic[31:0] dbg_reg_x8,
    output logic[31:0] dbg_reg_x9,
    output logic[31:0] dbg_reg_x10,
    output logic[31:0] dbg_reg_x11,
    output logic[31:0] dbg_reg_x12,
    output logic[31:0] dbg_reg_x13,
    output logic[31:0] dbg_reg_x14,
    output logic[31:0] dbg_reg_x15,
    output logic[31:0] dbg_reg_x16,
    output logic[31:0] dbg_reg_x17,
    output logic[31:0] dbg_reg_x18,
    output logic[31:0] dbg_reg_x19,
    output logic[31:0] dbg_reg_x20,
    output logic[31:0] dbg_reg_x21,
    output logic[31:0] dbg_reg_x22,
    output logic[31:0] dbg_reg_x23,
    output logic[31:0] dbg_reg_x24,
    output logic[31:0] dbg_reg_x25,
    output logic[31:0] dbg_reg_x26,
    output logic[31:0] dbg_reg_x27,
    output logic[31:0] dbg_reg_x28,
    output logic[31:0] dbg_reg_x29,
    output logic[31:0] dbg_reg_x30,
    output logic[31:0] dbg_reg_x31,
    output logic [31:0] dbg_insn_opcode,
    output logic [31:0] dbg_insn_addr,
    output logic dbg_mem_valid,
    output logic dbg_mem_instr,
    output logic dbg_mem_ready,
    output logic [31:0] dbg_mem_addr,
    output logic [31:0] dbg_mem_wdata,
    output logic [3:0] dbg_mem_wstrb,
    output logic [31:0] dbg_mem_rdata,
    output logic [63:0] dbg_ascii_instr,
    output logic [31:0] dbg_insn_imm,
    output logic [4:0] dbg_insn_rs1,
    output logic [4:0] dbg_insn_rs2,
    output logic [4:0] dbg_insn_rd,
    output logic [31:0] dbg_rs1val,
    output logic [31:0] dbg_rs2val,
    output logic dbg_rs1val_valid,
    output logic dbg_rs2val_valid,
    output logic dbg_next,
    output logic dbg_valid_insn,
    output logic [127:0] dbg_ascii_state,
    output logic trace_valid,
    output logic[35:0] trace_data);
    logic [63:0] count_cycle;
    logic [63:0] count_instr;
    logic [31:0] reg_pc;
    logic [31:0] reg_next_pc;
    logic [31:0] reg_op1;
    logic [31:0] reg_op2;
    logic [31:0] reg_out;
    logic [4:0] reg_sh;
    logic [31:0] next_insn_opcode;
    logic [31:0] next_pc;
    logic irq_delay;
    logic irq_active;
    logic [31:0] irq_mask;
    logic [31:0] irq_pending;
    logic [31:0] timer;
    logic [31:0] cpuregs [35:0];
    logic [31:0] i;
    logic pcpi_mul_wr;
    logic [31:0] pcpi_mul_rd;
    logic pcpi_mul_wait;
    logic pcpi_mul_ready;
    logic pcpi_div_wr;
    logic [31:0] pcpi_div_rd;
    logic pcpi_div_wait;
    logic pcpi_div_ready;
    logic pcpi_int_wr;
    logic [31:0] pcpi_int_rd;
    logic pcpi_int_wait;
    logic pcpi_int_ready;
    logic [1:0] mem_state;
    logic [1:0] mem_wordsize;
    logic [31:0] mem_rdata_word;
    logic [31:0] mem_rdata_q;
    logic mem_do_prefetch;
    logic mem_do_rinst;
    logic mem_do_rdata;
    logic mem_do_wdata;
    logic mem_xfer;
    logic mem_la_secondword;
    logic mem_la_firstword_reg;
    logic last_mem_valid;
    logic mem_la_firstword;
    logic mem_la_firstword_xfer;
    logic prefetched_high_word;
    logic clear_prefetched_high_word;
    logic [15:0] mem_16bit_buffer;
    logic [31:0] mem_rdata_latched_noshuffle;
    logic [31:0] mem_rdata_latched;
    logic mem_la_use_prefetched_high_word;
    logic mem_busy;
    logic mem_done;
    logic [11:0] __tmp12;
    logic [10:0] __tmp11;
    logic [9:0] __tmp10;
    logic [3:0] __tmp4;
    logic instr_lui;
    logic instr_auipc;
    logic instr_jal;
    logic instr_jalr;
    logic instr_beq;
    logic instr_bne;
    logic instr_blt;
    logic instr_bge;
    logic instr_bltu;
    logic instr_bgeu;
    logic instr_lb;
    logic instr_lh;
    logic instr_lw;
    logic instr_lbu;
    logic instr_lhu;
    logic instr_sb;
    logic instr_sh;
    logic instr_sw;
    logic instr_addi;
    logic instr_slti;
    logic instr_sltiu;
    logic instr_xori;
    logic instr_ori;
    logic instr_andi;
    logic instr_slli;
    logic instr_srli;
    logic instr_srai;
    logic instr_add;
    logic instr_sub;
    logic instr_sll;
    logic instr_slt;
    logic instr_sltu;
    logic instr_xor;
    logic instr_srl;
    logic instr_sra;
    logic instr_or;
    logic instr_and;
    logic instr_rdcycle;
    logic instr_rdcycleh;
    logic instr_rdinstr;
    logic instr_rdinstrh;
    logic instr_ecall_ebreak;
    logic instr_getq;
    logic instr_setq;
    logic instr_retirq;
    logic instr_maskirq;
    logic instr_waitirq;
    logic instr_timer;
    logic instr_trap;
    logic [5:0] decoded_rd;
    logic [5:0] decoded_rs1;
    logic [5:0] decoded_rs2;
    logic [31:0] decoded_imm;
    logic [31:0] decoded_imm_uj;
    logic decoder_trigger;
    logic decoder_trigger_q;
    logic decoder_pseudo_trigger;
    logic decoder_pseudo_trigger_q;
    logic compressed_instr;
    logic is_lui_auipc_jal;
    logic is_lb_lh_lw_lbu_lhu;
    logic is_slli_srli_srai;
    logic is_jalr_addi_slti_sltiu_xori_ori_andi;
    logic is_sb_sh_sw;
    logic is_sll_srl_sra;
    logic is_lui_auipc_jal_jalr_addi_add_sub;
    logic is_slti_blt_slt;
    logic is_sltiu_bltu_sltu;
    logic is_beq_bne_blt_bge_bltu_bgeu;
    logic is_lbu_lhu_lw;
    logic is_alu_reg_imm;
    logic is_alu_reg_reg;
    logic is_compare;
    logic is_rdcycle_rdcycleh_rdinstr_rdinstrh;
    logic [63:0] new_ascii_instr;
    logic [63:0] q_ascii_instr;
    logic [31:0] q_insn_imm;
    logic [31:0] q_insn_opcode;
    logic [4:0] q_insn_rs1;
    logic [4:0] q_insn_rs2;
    logic [4:0] q_insn_rd;
    logic launch_next_insn;
    logic [63:0] cached_ascii_instr;
    logic [31:0] cached_insn_imm;
    logic [31:0] cached_insn_opcode;
    logic [4:0] cached_insn_rs1;
    logic [4:0] cached_insn_rs2;
    logic [4:0] cached_insn_rd;
    logic [31:0] __tmp32;
    logic [19:0] __tmp20;
    logic [8:0] __tmp9;
    logic [0:0] __tmp1;
    logic [7:0] __tmp8;
    logic [6:0] __tmp7;
    logic [5:0] __tmp6;
    logic [4:0] __tmp5;
    logic [1:0] __tmp2;
    logic [7:0] cpu_state;
    logic [1:0] irq_state;
    logic set_mem_do_rinst;
    logic set_mem_do_rdata;
    logic set_mem_do_wdata;
    logic latched_store;
    logic latched_stalu;
    logic latched_branch;
    logic latched_compr;
    logic latched_trace;
    logic latched_is_lu;
    logic latched_is_lh;
    logic latched_is_lb;
    logic [5:0] latched_rd;
    logic [31:0] current_pc;
    logic [3:0] pcpi_timeout_counter;
    logic pcpi_timeout;
    logic [31:0] next_irq_pending;
    logic do_waitirq;
    logic [31:0] alu_out;
    logic [31:0] alu_out_q;
    logic alu_out_0;
    logic alu_out_0_q;
    logic alu_wait;
    logic alu_wait_2;
    logic [31:0] alu_add_sub;
    logic [31:0] alu_shl;
    logic [31:0] alu_shr;
    logic alu_eq;
    logic alu_ltu;
    logic alu_lts;
    logic clear_prefetched_high_word_q;
    logic cpuregs_write;
    logic [31:0] cpuregs_wrdata;
    logic [31:0] cpuregs_rs1;
    logic [31:0] cpuregs_rs2;
    logic [5:0] decoded_rs;
    task empty_statement;
            begin
            end
        endtask
    assign dbg_mem_valid = mem_valid;
    assign dbg_mem_instr = mem_instr;
    assign dbg_mem_ready = mem_ready;
    assign dbg_mem_addr = mem_addr;
    assign dbg_mem_wdata = mem_wdata;
    assign dbg_mem_wstrb = mem_wstrb;
    assign dbg_mem_rdata = mem_rdata;
    assign pcpi_rs1 = reg_op1;
    assign pcpi_rs2 = reg_op2;
    assign dbg_reg_x1 = cpuregs[6'h1];
    assign dbg_reg_x2 = cpuregs[6'h2];
    assign dbg_reg_x3 = cpuregs[6'h3];
    assign dbg_reg_x4 = cpuregs[6'h4];
    assign dbg_reg_x5 = cpuregs[6'h5];
    assign dbg_reg_x6 = cpuregs[6'h6];
    assign dbg_reg_x7 = cpuregs[6'h7];
    assign dbg_reg_x8 = cpuregs[6'h8];
    assign dbg_reg_x9 = cpuregs[6'h9];
    assign dbg_reg_x10 = cpuregs[6'ha];
    assign dbg_reg_x11 = cpuregs[6'hb];
    assign dbg_reg_x12 = cpuregs[6'hc];
    assign dbg_reg_x13 = cpuregs[6'hd];
    assign dbg_reg_x14 = cpuregs[6'he];
    assign dbg_reg_x15 = cpuregs[6'hf];
    assign dbg_reg_x16 = cpuregs[6'h10];
    assign dbg_reg_x17 = cpuregs[6'h11];
    assign dbg_reg_x18 = cpuregs[6'h12];
    assign dbg_reg_x19 = cpuregs[6'h13];
    assign dbg_reg_x20 = cpuregs[6'h14];
    assign dbg_reg_x21 = cpuregs[6'h15];
    assign dbg_reg_x22 = cpuregs[6'h16];
    assign dbg_reg_x23 = cpuregs[6'h17];
    assign dbg_reg_x24 = cpuregs[6'h18];
    assign dbg_reg_x25 = cpuregs[6'h19];
    assign dbg_reg_x26 = cpuregs[6'h1a];
    assign dbg_reg_x27 = cpuregs[6'h1b];
    assign dbg_reg_x28 = cpuregs[6'h1c];
    assign dbg_reg_x29 = cpuregs[6'h1d];
    assign dbg_reg_x30 = cpuregs[6'h1e];
    assign dbg_reg_x31 = cpuregs[6'h1f];
    assign mem_la_firstword = (((mem_do_prefetch | mem_do_rinst) & next_pc[1]) & ( ~ mem_la_secondword));
    assign mem_la_firstword_xfer = (mem_xfer & (last_mem_valid?mem_la_firstword_reg:mem_la_firstword));
    assign mem_la_use_prefetched_high_word = ((mem_la_firstword & prefetched_high_word) & ( ~ clear_prefetched_high_word));
    assign mem_xfer = ((mem_valid & mem_ready) | (mem_la_use_prefetched_high_word & mem_do_rinst));
    assign mem_busy = (mem_do_prefetch | (mem_do_rinst | (mem_do_rdata | mem_do_wdata)));
    assign mem_done = ((resetn & (((mem_xfer & ( | mem_state)) & ((mem_do_rinst | mem_do_rdata) | mem_do_wdata)) | (( & mem_state) & mem_do_rinst))) & (( ~ mem_la_firstword) | (( ~ ( & mem_rdata_latched[1:0])) & mem_xfer)));
    assign mem_la_write = ((resetn & ( ~ ( | mem_state))) & mem_do_wdata);
    assign mem_la_read = (resetn & (((( ~ mem_la_use_prefetched_high_word) & ( ~ ( | mem_state))) & ((mem_do_rinst | mem_do_prefetch) | mem_do_rdata)) | (((mem_xfer & (last_mem_valid?mem_la_firstword_reg:mem_la_firstword)) & ( ~ mem_la_secondword)) & ( & mem_rdata_latched[1:0]))));
    assign mem_la_addr = ((mem_do_prefetch | mem_do_rinst)?{(next_pc[31:2]+{1'b0,mem_la_firstword_xfer}),2'h0}:{reg_op1[31:2],2'h0});
    assign mem_rdata_latched_noshuffle = (mem_xfer?mem_rdata:mem_rdata_q);
    assign mem_rdata_latched = (mem_la_use_prefetched_high_word?{1'b0,mem_16bit_buffer}:(mem_la_secondword?{mem_rdata_latched_noshuffle[15:0],mem_16bit_buffer}:(mem_la_firstword?{1'b0,mem_rdata_latched_noshuffle[31:16]}:mem_rdata_latched_noshuffle)));
    assign instr_trap = ( ~ ((instr_lui | (instr_auipc | (instr_jal | (instr_jalr | (instr_beq | (instr_bne | (instr_blt | (instr_bge | (instr_bltu | (instr_bgeu | (instr_lb | (instr_lh | (instr_lw | (instr_lbu | (instr_lhu | (instr_sb | (instr_sh | (instr_sw | (instr_addi | (instr_slti | (instr_sltiu | (instr_xori | (instr_ori | (instr_andi | (instr_slli | (instr_srli | (instr_srai | (instr_add | (instr_sub | (instr_sll | (instr_slt | instr_sltu))))))))))))))))))))))))))))))) | (instr_xor | (instr_srl | (instr_sra | (instr_or | (instr_and | (instr_rdcycle | (instr_rdcycleh | (instr_rdinstr | (instr_rdinstrh | (instr_getq | (instr_setq | (instr_retirq | (instr_maskirq | (instr_waitirq | instr_timer))))))))))))))));
    assign is_rdcycle_rdcycleh_rdinstr_rdinstrh = (instr_rdcycle | (instr_rdcycleh | (instr_rdinstr | instr_rdinstrh)));
    assign next_pc = ((latched_store & latched_branch)?(32'hfffffffe & reg_out):reg_next_pc);
    assign launch_next_insn = (((8'h40 == cpu_state) & decoder_trigger) & ((irq_delay | irq_active) | ( ~ ( | (irq_pending & ( ~ irq_mask))))));
    
/* example/picorv32.v:319 */
always@* 
        begin
        pcpi_int_wr = 1'h0;
        pcpi_int_rd = 32'h0;
        pcpi_int_wait = (pcpi_mul_wait | pcpi_div_wait);
        pcpi_int_ready = (pcpi_mul_ready | pcpi_div_ready);
        case(1'h1)
            1'h0:
                begin
                pcpi_int_wr = 1'h0;
                pcpi_int_rd = 32'sh0;
                end
            pcpi_mul_ready:
                begin
                pcpi_int_wr = pcpi_mul_wr;
                pcpi_int_rd = pcpi_mul_rd;
                end
            pcpi_div_ready:
                begin
                pcpi_int_wr = pcpi_div_wr;
                pcpi_int_rd = pcpi_div_rd;
                end
            endcase
        end
    
/* example/picorv32.v:384 */
always@(posedge clk) 
        begin
        if (resetn) 
            begin
            if ( ~ last_mem_valid) 
                begin
                mem_la_firstword_reg <= mem_la_firstword;
                end;
            last_mem_valid <= (mem_valid & ( ~ mem_ready));
            end
        else
            begin
            mem_la_firstword_reg <= 1'h0;
            last_mem_valid <= 1'h0;
            end
        end
    
/* example/picorv32.v:395 */
always@* 
        begin
        case({1'b0,mem_wordsize})
            32'sh0:
                begin
                mem_la_wdata = reg_op2;
                mem_la_wstrb = 4'hf;
                mem_rdata_word = mem_rdata;
                end
            32'sh1:
                begin
                mem_la_wdata = {2{reg_op2[15:0]}};
                mem_la_wstrb = (reg_op1[1]?4'hc:4'h3);
                case(reg_op1[1])
                    1'h0:
                        begin
                        mem_rdata_word = {1'b0,mem_rdata[15:0]};
                        end
                    1'h1:
                        begin
                        mem_rdata_word = {1'b0,mem_rdata[31:16]};
                        end
                    endcase
                end
            32'sh2:
                begin
                mem_la_wdata = {4{reg_op2[7:0]}};
                mem_la_wstrb = (4'h1 << reg_op1[1:0]);
                case(reg_op1[1:0])
                    2'h0:
                        begin
                        mem_rdata_word = {1'b0,mem_rdata[7:0]};
                        end
                    2'h1:
                        begin
                        mem_rdata_word = {1'b0,mem_rdata[15:8]};
                        end
                    2'h2:
                        begin
                        mem_rdata_word = {1'b0,mem_rdata[23:16]};
                        end
                    2'h3:
                        begin
                        mem_rdata_word = {1'b0,mem_rdata[31:24]};
                        end
                    endcase
                end
            endcase
        end
    
/* example/picorv32.v:424 */
always@(posedge clk) 
        begin
        if (mem_xfer) 
            begin
            mem_rdata_q <= mem_rdata_latched;
            next_insn_opcode <= mem_rdata_latched;
            end;
        if (mem_done & (mem_do_prefetch | mem_do_rinst)) 
            begin
            case(mem_rdata_latched[1:0])
                2'h0:
                    begin
                    case(mem_rdata_latched[15:13])
                        3'h0:
                            begin
                            mem_rdata_q[14:12] <= 3'h0;
                            mem_rdata_q[31:20] <= {{1'b0,mem_rdata_latched[10:7]},{mem_rdata_latched[12:11],{mem_rdata_latched[5],{mem_rdata_latched[6],2'h0}}}};
                            end
                        3'h2:
                            begin
                            mem_rdata_q[31:20] <= {{1'b0,mem_rdata_latched[5]},{mem_rdata_latched[12:10],{mem_rdata_latched[6],2'h0}}};
                            mem_rdata_q[14:12] <= 3'h2;
                            end
                        3'h6:
                            begin
                            mem_rdata_q[31:25] <= {{1'b0,mem_rdata_latched[5]},mem_rdata_latched[12]};
                            mem_rdata_q[11:7] <= {mem_rdata_latched[11:10],{mem_rdata_latched[6],2'h0}};
                            mem_rdata_q[14:12] <= 3'h2;
                            end
                        endcase
                    end
                2'h1:
                    begin
                    case(mem_rdata_latched[15:13])
                        3'h0:
                            begin
                            mem_rdata_q[14:12] <= 3'h0;
                            mem_rdata_q[31:20] <= $signed({mem_rdata_latched[12],mem_rdata_latched[6:2]});
                            end
                        3'h2:
                            begin
                            mem_rdata_q[14:12] <= 3'h0;
                            mem_rdata_q[31:20] <= $signed({mem_rdata_latched[12],mem_rdata_latched[6:2]});
                            end
                        3'h3:
                            begin
                            if (5'h2 == mem_rdata_latched[11:7]) 
                                begin
                                mem_rdata_q[14:12] <= 3'h0;
                                mem_rdata_q[31:20] <= $signed({mem_rdata_latched[12],{mem_rdata_latched[4:3],{mem_rdata_latched[5],{mem_rdata_latched[2],{mem_rdata_latched[6],4'h0}}}}});
                                end
                            else
                                begin
                                mem_rdata_q[31:12] <= $signed({mem_rdata_latched[12],mem_rdata_latched[6:2]});
                                end
                            end
                        3'h4:
                            begin
                            if (2'h0 == mem_rdata_latched[11:10]) 
                                begin
                                mem_rdata_q[31:25] <= 7'h0;
                                mem_rdata_q[14:12] <= 3'h5;
                                end;
                            if (2'h1 == mem_rdata_latched[11:10]) 
                                begin
                                mem_rdata_q[31:25] <= 7'h20;
                                mem_rdata_q[14:12] <= 3'h5;
                                end;
                            if (2'h2 == mem_rdata_latched[11:10]) 
                                begin
                                mem_rdata_q[14:12] <= 3'h7;
                                mem_rdata_q[31:20] <= $signed({mem_rdata_latched[12],mem_rdata_latched[6:2]});
                                end;
                            if (3'h3 == mem_rdata_latched[12:10]) 
                                begin
                                if (2'h0 == mem_rdata_latched[6:5]) 
                                    begin
                                    mem_rdata_q[14:12] <= 3'h0;
                                    end;
                                if (2'h1 == mem_rdata_latched[6:5]) 
                                    begin
                                    mem_rdata_q[14:12] <= 3'h4;
                                    end;
                                if (2'h2 == mem_rdata_latched[6:5]) 
                                    begin
                                    mem_rdata_q[14:12] <= 3'h6;
                                    end;
                                if (2'h3 == mem_rdata_latched[6:5]) 
                                    begin
                                    mem_rdata_q[14:12] <= 3'h7;
                                    end;
                                if (2'h0 == mem_rdata_latched[6:5]) 
                                    begin
                                    mem_rdata_q[31:25] <= 7'h20;
                                    end
                                else
                                    begin
                                    mem_rdata_q[31:25] <= 7'h0;
                                    end
                                end
                            end
                        3'h6:
                            begin
                            mem_rdata_q[14:12] <= 3'h0;
                            __tmp12 = $signed({mem_rdata_latched[12],{mem_rdata_latched[6:5],{mem_rdata_latched[2],{mem_rdata_latched[11:10],mem_rdata_latched[4:3]}}}});
                            mem_rdata_q[31] <= __tmp12[11];
                            mem_rdata_q[7] <= __tmp12[10];
                            mem_rdata_q[30:25] <= __tmp12[9:4];
                            mem_rdata_q[11:8] <= __tmp12[3:0];
                            end
                        3'h7:
                            begin
                            mem_rdata_q[14:12] <= 3'h1;
                            __tmp12 = $signed({mem_rdata_latched[12],{mem_rdata_latched[6:5],{mem_rdata_latched[2],{mem_rdata_latched[11:10],mem_rdata_latched[4:3]}}}});
                            mem_rdata_q[31] <= __tmp12[11];
                            mem_rdata_q[7] <= __tmp12[10];
                            mem_rdata_q[30:25] <= __tmp12[9:4];
                            mem_rdata_q[11:8] <= __tmp12[3:0];
                            end
                        endcase
                    end
                2'h2:
                    begin
                    case(mem_rdata_latched[15:13])
                        3'h0:
                            begin
                            mem_rdata_q[31:25] <= 7'h0;
                            mem_rdata_q[14:12] <= 3'h1;
                            end
                        3'h2:
                            begin
                            mem_rdata_q[31:20] <= {{1'b0,mem_rdata_latched[3:2]},{mem_rdata_latched[12],{mem_rdata_latched[6:4],2'h0}}};
                            mem_rdata_q[14:12] <= 3'h2;
                            end
                        3'h4:
                            begin
                            if (( ~ mem_rdata_latched[12]) & (5'h0 == mem_rdata_latched[6:2])) 
                                begin
                                mem_rdata_q[14:12] <= 3'h0;
                                mem_rdata_q[31:20] <= 12'h0;
                                end;
                            if (( ~ mem_rdata_latched[12]) & (5'h0 != mem_rdata_latched[6:2])) 
                                begin
                                mem_rdata_q[14:12] <= 3'h0;
                                mem_rdata_q[31:25] <= 7'h0;
                                end;
                            if ((mem_rdata_latched[12] & (5'h0 != mem_rdata_latched[11:7])) & (5'h0 == mem_rdata_latched[6:2])) 
                                begin
                                mem_rdata_q[14:12] <= 3'h0;
                                mem_rdata_q[31:20] <= 12'h0;
                                end;
                            if (mem_rdata_latched[12] & (5'h0 != mem_rdata_latched[6:2])) 
                                begin
                                mem_rdata_q[14:12] <= 3'h0;
                                mem_rdata_q[31:25] <= 7'h0;
                                end
                            end
                        3'h6:
                            begin
                            mem_rdata_q[31:25] <= {{1'b0,mem_rdata_latched[8:7]},mem_rdata_latched[12]};
                            mem_rdata_q[11:7] <= {mem_rdata_latched[11:9],2'h0};
                            mem_rdata_q[14:12] <= 3'h2;
                            end
                        endcase
                    end
                endcase
            end
        end
    
/* example/picorv32.v:540 */
always@(posedge clk) 
        begin
        if (resetn & ( ~ trap)) 
            begin
            if ((mem_do_prefetch | mem_do_rinst) | mem_do_rdata) 
                begin
                empty_statement;
                end;
            if (mem_do_prefetch | mem_do_rinst) 
                begin
                empty_statement;
                end;
            if (mem_do_rdata) 
                begin
                empty_statement;
                end;
            if (mem_do_wdata) 
                begin
                empty_statement;
                end;
            if ((2'h2 == mem_state) | (2'h3 == mem_state)) 
                begin
                empty_statement;
                end
            end
        end
    
/* example/picorv32.v:559 */
always@(posedge clk) 
        begin
        if (( ~ resetn) | trap) 
            begin
            if ( ~ resetn) 
                begin
                mem_state <= 2'h0;
                end;
            if (( ~ resetn) | mem_ready) 
                begin
                mem_valid <= 1'h0;
                end;
            mem_la_secondword <= 1'h0;
            prefetched_high_word <= 1'h0;
            end
        else
            begin
            if (mem_la_read | mem_la_write) 
                begin
                mem_addr <= mem_la_addr;
                mem_wstrb <= (mem_la_wstrb & {4{mem_la_write}});
                end;
            if (mem_la_write) 
                begin
                mem_wdata <= mem_la_wdata;
                end;
            case({1'b0,mem_state})
                32'sh0:
                    begin
                    if ((mem_do_prefetch | mem_do_rinst) | mem_do_rdata) 
                        begin
                        mem_valid <= ( ~ mem_la_use_prefetched_high_word);
                        mem_instr <= (mem_do_prefetch | mem_do_rinst);
                        mem_wstrb <= 4'h0;
                        mem_state <= 2'h1;
                        end;
                    if (mem_do_wdata) 
                        begin
                        mem_valid <= 1'h1;
                        mem_instr <= 1'h0;
                        mem_state <= 2'h2;
                        end
                    end
                32'sh1:
                    begin
                    empty_statement;
                    empty_statement;
                    empty_statement;
                    empty_statement;
                    if (mem_xfer) 
                        begin
                        if (mem_la_read) 
                            begin
                            mem_valid <= 1'h1;
                            mem_la_secondword <= 1'h1;
                            if ( ~ mem_la_use_prefetched_high_word) 
                                begin
                                mem_16bit_buffer <= mem_rdata[31:16];
                                end
                            end
                        else
                            begin
                            mem_valid <= 1'h0;
                            mem_la_secondword <= 1'h0;
                            if ( ~ mem_do_rdata) 
                                begin
                                if (( ~ ( & mem_rdata[1:0])) | mem_la_secondword) 
                                    begin
                                    mem_16bit_buffer <= mem_rdata[31:16];
                                    prefetched_high_word <= 1'h1;
                                    end
                                else
                                    begin
                                    prefetched_high_word <= 1'h0;
                                    end
                                end;
                            mem_state <= (((mem_do_rinst | mem_do_rdata)?32'sh0:32'sh3)>>0);
                            end
                        end
                    end
                32'sh2:
                    begin
                    empty_statement;
                    empty_statement;
                    if (mem_xfer) 
                        begin
                        mem_valid <= 1'h0;
                        mem_state <= 2'h0;
                        end
                    end
                32'sh3:
                    begin
                    empty_statement;
                    empty_statement;
                    if (mem_do_rinst) 
                        begin
                        mem_state <= 2'h0;
                        end
                    end
                endcase
            end;
        if (clear_prefetched_high_word) 
            begin
            prefetched_high_word <= 1'h0;
            end
        end
    
/* example/picorv32.v:694 */
always@* 
        begin
        new_ascii_instr = 64'h0;
        if (instr_lui) new_ascii_instr = 64'h6c7569;
        if (instr_auipc) new_ascii_instr = 64'h6175697063;
        if (instr_jal) new_ascii_instr = 64'h6a616c;
        if (instr_jalr) new_ascii_instr = 64'h6a616c72;
        if (instr_beq) new_ascii_instr = 64'h626571;
        if (instr_bne) new_ascii_instr = 64'h626e65;
        if (instr_blt) new_ascii_instr = 64'h626c74;
        if (instr_bge) new_ascii_instr = 64'h626765;
        if (instr_bltu) new_ascii_instr = 64'h626c7475;
        if (instr_bgeu) new_ascii_instr = 64'h62676575;
        if (instr_lb) new_ascii_instr = 64'h6c62;
        if (instr_lh) new_ascii_instr = 64'h6c68;
        if (instr_lw) new_ascii_instr = 64'h6c77;
        if (instr_lbu) new_ascii_instr = 64'h6c6275;
        if (instr_lhu) new_ascii_instr = 64'h6c6875;
        if (instr_sb) new_ascii_instr = 64'h7362;
        if (instr_sh) new_ascii_instr = 64'h7368;
        if (instr_sw) new_ascii_instr = 64'h7377;
        if (instr_addi) new_ascii_instr = 64'h61646469;
        if (instr_slti) new_ascii_instr = 64'h736c7469;
        if (instr_sltiu) new_ascii_instr = 64'h736c746975;
        if (instr_xori) new_ascii_instr = 64'h786f7269;
        if (instr_ori) new_ascii_instr = 64'h6f7269;
        if (instr_andi) new_ascii_instr = 64'h616e6469;
        if (instr_slli) new_ascii_instr = 64'h736c6c69;
        if (instr_srli) new_ascii_instr = 64'h73726c69;
        if (instr_srai) new_ascii_instr = 64'h73726169;
        if (instr_add) new_ascii_instr = 64'h616464;
        if (instr_sub) new_ascii_instr = 64'h737562;
        if (instr_sll) new_ascii_instr = 64'h736c6c;
        if (instr_slt) new_ascii_instr = 64'h736c74;
        if (instr_sltu) new_ascii_instr = 64'h736c7475;
        if (instr_xor) new_ascii_instr = 64'h786f72;
        if (instr_srl) new_ascii_instr = 64'h73726c;
        if (instr_sra) new_ascii_instr = 64'h737261;
        if (instr_or) new_ascii_instr = 64'h6f72;
        if (instr_and) new_ascii_instr = 64'h616e64;
        if (instr_rdcycle) new_ascii_instr = 64'h72646379636c65;
        if (instr_rdcycleh) new_ascii_instr = 64'h72646379636c6568;
        if (instr_rdinstr) new_ascii_instr = 64'h7264696e737472;
        if (instr_rdinstrh) new_ascii_instr = 64'h7264696e73747268;
        if (instr_getq) new_ascii_instr = 64'h67657471;
        if (instr_setq) new_ascii_instr = 64'h73657471;
        if (instr_retirq) new_ascii_instr = 64'h726574697271;
        if (instr_maskirq) new_ascii_instr = 64'h6d61736b697271;
        if (instr_waitirq) new_ascii_instr = 64'h77616974697271;
        if (instr_timer) new_ascii_instr = 64'h74696d6572;
        end
    
/* example/picorv32.v:770 */
always@(posedge clk) 
        begin
        q_ascii_instr <= dbg_ascii_instr;
        q_insn_imm <= dbg_insn_imm;
        q_insn_opcode <= dbg_insn_opcode;
        q_insn_rs1 <= dbg_insn_rs1;
        q_insn_rs2 <= dbg_insn_rs2;
        q_insn_rd <= dbg_insn_rd;
        dbg_next <= launch_next_insn;
        if (( ~ resetn) | trap) 
            begin
            dbg_valid_insn <= 1'h0;
            end
        else
            begin
            if (launch_next_insn) 
                begin
                dbg_valid_insn <= 1'h1;
                end
            end;
        if (decoder_trigger_q) 
            begin
            cached_ascii_instr <= new_ascii_instr;
            cached_insn_imm <= decoded_imm;
            if ( & next_insn_opcode[1:0]) 
                begin
                cached_insn_opcode <= next_insn_opcode;
                end
            else
                begin
                cached_insn_opcode <= {1'b0,next_insn_opcode[15:0]};
                end;
            cached_insn_rs1 <= decoded_rs1[4:0];
            cached_insn_rs2 <= decoded_rs2[4:0];
            cached_insn_rd <= decoded_rd[4:0];
            end;
        if (launch_next_insn) 
            begin
            dbg_insn_addr <= next_pc;
            end
        end
    
/* example/picorv32.v:801 */
always@* 
        begin
        dbg_ascii_instr = q_ascii_instr;
        dbg_insn_imm = q_insn_imm;
        dbg_insn_opcode = q_insn_opcode;
        dbg_insn_rs1 = q_insn_rs1;
        dbg_insn_rs2 = q_insn_rs2;
        dbg_insn_rd = q_insn_rd;
        if (dbg_next) 
            begin
            if (decoder_pseudo_trigger_q) 
                begin
                dbg_ascii_instr = cached_ascii_instr;
                dbg_insn_imm = cached_insn_imm;
                dbg_insn_opcode = cached_insn_opcode;
                dbg_insn_rs1 = cached_insn_rs1;
                dbg_insn_rs2 = cached_insn_rs2;
                dbg_insn_rd = cached_insn_rd;
                end
            else
                begin
                dbg_ascii_instr = new_ascii_instr;
                dbg_insn_opcode = (( & next_insn_opcode[1:0])?next_insn_opcode:{1'b0,next_insn_opcode[15:0]});
                dbg_insn_imm = decoded_imm;
                dbg_insn_rs1 = decoded_rs1[4:0];
                dbg_insn_rs2 = decoded_rs2[4:0];
                dbg_insn_rd = decoded_rd[4:0];
                end
            end
        end
    
/* example/picorv32.v:850 */
always@(posedge clk) 
        begin
        is_lui_auipc_jal <= (instr_lui | (instr_auipc | instr_jal));
        is_lui_auipc_jal_jalr_addi_add_sub <= (instr_lui | (instr_auipc | (instr_jal | (instr_jalr | (instr_addi | (instr_add | instr_sub))))));
        is_slti_blt_slt <= (instr_slti | (instr_blt | instr_slt));
        is_sltiu_bltu_sltu <= (instr_sltiu | (instr_bltu | instr_sltu));
        is_lbu_lhu_lw <= (instr_lbu | (instr_lhu | instr_lw));
        is_compare <= (is_beq_bne_blt_bge_bltu_bgeu | (instr_slti | (instr_slt | (instr_sltiu | instr_sltu))));
        if (mem_do_rinst & mem_done) 
            begin
            instr_lui <= (7'h37 == mem_rdata_latched[6:0]);
            instr_auipc <= (7'h17 == mem_rdata_latched[6:0]);
            instr_jal <= (7'h6f == mem_rdata_latched[6:0]);
            instr_jalr <= ((7'h67 == mem_rdata_latched[6:0]) & (3'h0 == mem_rdata_latched[14:12]));
            instr_retirq <= ((7'hb == mem_rdata_latched[6:0]) & (7'h2 == mem_rdata_latched[31:25]));
            instr_waitirq <= ((7'hb == mem_rdata_latched[6:0]) & (7'h4 == mem_rdata_latched[31:25]));
            is_beq_bne_blt_bge_bltu_bgeu <= (7'h63 == mem_rdata_latched[6:0]);
            is_lb_lh_lw_lbu_lhu <= (7'h3 == mem_rdata_latched[6:0]);
            is_sb_sh_sw <= (7'h23 == mem_rdata_latched[6:0]);
            is_alu_reg_imm <= (7'h13 == mem_rdata_latched[6:0]);
            is_alu_reg_reg <= (7'h33 == mem_rdata_latched[6:0]);
            __tmp32 = $signed({mem_rdata_latched[31:12],1'h0});
            decoded_imm_uj[31:20] <= __tmp32[31:20];
            decoded_imm_uj[10:1] <= __tmp32[19:10];
            decoded_imm_uj[11] <= __tmp32[9];
            decoded_imm_uj[19:12] <= __tmp32[8:1];
            decoded_imm_uj[0] <= __tmp32[0];
            decoded_rd <= {1'b0,mem_rdata_latched[11:7]};
            decoded_rs1 <= {1'b0,mem_rdata_latched[19:15]};
            decoded_rs2 <= {1'b0,mem_rdata_latched[24:20]};
            if ((7'hb == mem_rdata_latched[6:0]) & (7'h0 == mem_rdata_latched[31:25])) 
                begin
                decoded_rs1[5] <= 1'h1;
                end;
            if ((7'hb == mem_rdata_latched[6:0]) & (7'h2 == mem_rdata_latched[31:25])) 
                begin
                decoded_rs1 <= 6'h20;
                end;
            compressed_instr <= 1'h0;
            if (2'h3 != mem_rdata_latched[1:0]) 
                begin
                compressed_instr <= 1'h1;
                decoded_rd <= 6'h0;
                decoded_rs1 <= 6'h0;
                decoded_rs2 <= 6'h0;
                __tmp32 = $signed({mem_rdata_latched[12:2],1'h0});
                decoded_imm_uj[31:11] <= __tmp32[31:11];
                decoded_imm_uj[4] <= __tmp32[10];
                decoded_imm_uj[9:8] <= __tmp32[9:8];
                decoded_imm_uj[10] <= __tmp32[7];
                decoded_imm_uj[6] <= __tmp32[6];
                decoded_imm_uj[7] <= __tmp32[5];
                decoded_imm_uj[3:1] <= __tmp32[4:2];
                decoded_imm_uj[5] <= __tmp32[1];
                decoded_imm_uj[0] <= __tmp32[0];
                case(mem_rdata_latched[1:0])
                    2'h0:
                        begin
                        case(mem_rdata_latched[15:13])
                            3'h0:
                                begin
                                is_alu_reg_imm <= ( | mem_rdata_latched[12:5]);
                                decoded_rs1 <= 6'h2;
                                decoded_rd <= (6'h8+({1'b0,mem_rdata_latched[4:2]}>>0));
                                end
                            3'h2:
                                begin
                                is_lb_lh_lw_lbu_lhu <= 1'h1;
                                decoded_rs1 <= (6'h8+({1'b0,mem_rdata_latched[9:7]}>>0));
                                decoded_rd <= (6'h8+({1'b0,mem_rdata_latched[4:2]}>>0));
                                end
                            3'h6:
                                begin
                                is_sb_sh_sw <= 1'h1;
                                decoded_rs1 <= (6'h8+({1'b0,mem_rdata_latched[9:7]}>>0));
                                decoded_rs2 <= (6'h8+({1'b0,mem_rdata_latched[4:2]}>>0));
                                end
                            endcase
                        end
                    2'h1:
                        begin
                        case(mem_rdata_latched[15:13])
                            3'h0:
                                begin
                                is_alu_reg_imm <= 1'h1;
                                decoded_rd <= {1'b0,mem_rdata_latched[11:7]};
                                decoded_rs1 <= {1'b0,mem_rdata_latched[11:7]};
                                end
                            3'h1:
                                begin
                                instr_jal <= 1'h1;
                                decoded_rd <= 6'h1;
                                end
                            3'h2:
                                begin
                                is_alu_reg_imm <= 1'h1;
                                decoded_rd <= {1'b0,mem_rdata_latched[11:7]};
                                decoded_rs1 <= 6'h0;
                                end
                            3'h3:
                                begin
                                if (mem_rdata_latched[12] | ( | mem_rdata_latched[6:2])) 
                                    begin
                                    if (5'h2 == mem_rdata_latched[11:7]) 
                                        begin
                                        is_alu_reg_imm <= 1'h1;
                                        decoded_rd <= {1'b0,mem_rdata_latched[11:7]};
                                        decoded_rs1 <= {1'b0,mem_rdata_latched[11:7]};
                                        end
                                    else
                                        begin
                                        instr_lui <= 1'h1;
                                        decoded_rd <= {1'b0,mem_rdata_latched[11:7]};
                                        decoded_rs1 <= 6'h0;
                                        end
                                    end
                                end
                            3'h4:
                                begin
                                if (( ~ mem_rdata_latched[11]) & ( ~ mem_rdata_latched[12])) 
                                    begin
                                    is_alu_reg_imm <= 1'h1;
                                    decoded_rd <= (6'h8+({1'b0,mem_rdata_latched[9:7]}>>0));
                                    decoded_rs1 <= (6'h8+({1'b0,mem_rdata_latched[9:7]}>>0));
                                    decoded_rs2 <= {mem_rdata_latched[12],mem_rdata_latched[6:2]};
                                    end;
                                if (2'h2 == mem_rdata_latched[11:10]) 
                                    begin
                                    is_alu_reg_imm <= 1'h1;
                                    decoded_rd <= (6'h8+({1'b0,mem_rdata_latched[9:7]}>>0));
                                    decoded_rs1 <= (6'h8+({1'b0,mem_rdata_latched[9:7]}>>0));
                                    end;
                                if (3'h3 == mem_rdata_latched[12:10]) 
                                    begin
                                    is_alu_reg_reg <= 1'h1;
                                    decoded_rd <= (6'h8+({1'b0,mem_rdata_latched[9:7]}>>0));
                                    decoded_rs1 <= (6'h8+({1'b0,mem_rdata_latched[9:7]}>>0));
                                    decoded_rs2 <= (6'h8+({1'b0,mem_rdata_latched[4:2]}>>0));
                                    end
                                end
                            3'h5:
                                begin
                                instr_jal <= 1'h1;
                                end
                            3'h6:
                                begin
                                is_beq_bne_blt_bge_bltu_bgeu <= 1'h1;
                                decoded_rs1 <= (6'h8+({1'b0,mem_rdata_latched[9:7]}>>0));
                                decoded_rs2 <= 6'h0;
                                end
                            3'h7:
                                begin
                                is_beq_bne_blt_bge_bltu_bgeu <= 1'h1;
                                decoded_rs1 <= (6'h8+({1'b0,mem_rdata_latched[9:7]}>>0));
                                decoded_rs2 <= 6'h0;
                                end
                            endcase
                        end
                    2'h2:
                        begin
                        case(mem_rdata_latched[15:13])
                            3'h0:
                                begin
                                if ( ~ mem_rdata_latched[12]) 
                                    begin
                                    is_alu_reg_imm <= 1'h1;
                                    decoded_rd <= {1'b0,mem_rdata_latched[11:7]};
                                    decoded_rs1 <= {1'b0,mem_rdata_latched[11:7]};
                                    decoded_rs2 <= {mem_rdata_latched[12],mem_rdata_latched[6:2]};
                                    end
                                end
                            3'h2:
                                begin
                                if ( | mem_rdata_latched[11:7]) 
                                    begin
                                    is_lb_lh_lw_lbu_lhu <= 1'h1;
                                    decoded_rd <= {1'b0,mem_rdata_latched[11:7]};
                                    decoded_rs1 <= 6'h2;
                                    end
                                end
                            3'h4:
                                begin
                                if ((( ~ mem_rdata_latched[12]) & (5'h0 != mem_rdata_latched[11:7])) & (5'h0 == mem_rdata_latched[6:2])) 
                                    begin
                                    instr_jalr <= 1'h1;
                                    decoded_rd <= 6'h0;
                                    decoded_rs1 <= {1'b0,mem_rdata_latched[11:7]};
                                    end;
                                if (( ~ mem_rdata_latched[12]) & (5'h0 != mem_rdata_latched[6:2])) 
                                    begin
                                    is_alu_reg_reg <= 1'h1;
                                    decoded_rd <= {1'b0,mem_rdata_latched[11:7]};
                                    decoded_rs1 <= 6'h0;
                                    decoded_rs2 <= {1'b0,mem_rdata_latched[6:2]};
                                    end;
                                if ((mem_rdata_latched[12] & (5'h0 != mem_rdata_latched[11:7])) & (5'h0 == mem_rdata_latched[6:2])) 
                                    begin
                                    instr_jalr <= 1'h1;
                                    decoded_rd <= 6'h1;
                                    decoded_rs1 <= {1'b0,mem_rdata_latched[11:7]};
                                    end;
                                if (mem_rdata_latched[12] & (5'h0 != mem_rdata_latched[6:2])) 
                                    begin
                                    is_alu_reg_reg <= 1'h1;
                                    decoded_rd <= {1'b0,mem_rdata_latched[11:7]};
                                    decoded_rs1 <= {1'b0,mem_rdata_latched[11:7]};
                                    decoded_rs2 <= {1'b0,mem_rdata_latched[6:2]};
                                    end
                                end
                            3'h6:
                                begin
                                is_sb_sh_sw <= 1'h1;
                                decoded_rs1 <= 6'h2;
                                decoded_rs2 <= {1'b0,mem_rdata_latched[6:2]};
                                end
                            endcase
                        end
                    endcase
                end
            end;
        if (decoder_trigger & ( ~ decoder_pseudo_trigger)) 
            begin
            pcpi_insn <= mem_rdata_q;
            instr_beq <= (is_beq_bne_blt_bge_bltu_bgeu & (3'h0 == mem_rdata_q[14:12]));
            instr_bne <= (is_beq_bne_blt_bge_bltu_bgeu & (3'h1 == mem_rdata_q[14:12]));
            instr_blt <= (is_beq_bne_blt_bge_bltu_bgeu & (3'h4 == mem_rdata_q[14:12]));
            instr_bge <= (is_beq_bne_blt_bge_bltu_bgeu & (3'h5 == mem_rdata_q[14:12]));
            instr_bltu <= (is_beq_bne_blt_bge_bltu_bgeu & (3'h6 == mem_rdata_q[14:12]));
            instr_bgeu <= (is_beq_bne_blt_bge_bltu_bgeu & (3'h7 == mem_rdata_q[14:12]));
            instr_lb <= (is_lb_lh_lw_lbu_lhu & (3'h0 == mem_rdata_q[14:12]));
            instr_lh <= (is_lb_lh_lw_lbu_lhu & (3'h1 == mem_rdata_q[14:12]));
            instr_lw <= (is_lb_lh_lw_lbu_lhu & (3'h2 == mem_rdata_q[14:12]));
            instr_lbu <= (is_lb_lh_lw_lbu_lhu & (3'h4 == mem_rdata_q[14:12]));
            instr_lhu <= (is_lb_lh_lw_lbu_lhu & (3'h5 == mem_rdata_q[14:12]));
            instr_sb <= (is_sb_sh_sw & (3'h0 == mem_rdata_q[14:12]));
            instr_sh <= (is_sb_sh_sw & (3'h1 == mem_rdata_q[14:12]));
            instr_sw <= (is_sb_sh_sw & (3'h2 == mem_rdata_q[14:12]));
            instr_addi <= (is_alu_reg_imm & (3'h0 == mem_rdata_q[14:12]));
            instr_slti <= (is_alu_reg_imm & (3'h2 == mem_rdata_q[14:12]));
            instr_sltiu <= (is_alu_reg_imm & (3'h3 == mem_rdata_q[14:12]));
            instr_xori <= (is_alu_reg_imm & (3'h4 == mem_rdata_q[14:12]));
            instr_ori <= (is_alu_reg_imm & (3'h6 == mem_rdata_q[14:12]));
            instr_andi <= (is_alu_reg_imm & (3'h7 == mem_rdata_q[14:12]));
            instr_slli <= ((is_alu_reg_imm & (3'h1 == mem_rdata_q[14:12])) & (7'h0 == mem_rdata_q[31:25]));
            instr_srli <= ((is_alu_reg_imm & (3'h5 == mem_rdata_q[14:12])) & (7'h0 == mem_rdata_q[31:25]));
            instr_srai <= ((is_alu_reg_imm & (3'h5 == mem_rdata_q[14:12])) & (7'h20 == mem_rdata_q[31:25]));
            instr_add <= ((is_alu_reg_reg & (3'h0 == mem_rdata_q[14:12])) & (7'h0 == mem_rdata_q[31:25]));
            instr_sub <= ((is_alu_reg_reg & (3'h0 == mem_rdata_q[14:12])) & (7'h20 == mem_rdata_q[31:25]));
            instr_sll <= ((is_alu_reg_reg & (3'h1 == mem_rdata_q[14:12])) & (7'h0 == mem_rdata_q[31:25]));
            instr_slt <= ((is_alu_reg_reg & (3'h2 == mem_rdata_q[14:12])) & (7'h0 == mem_rdata_q[31:25]));
            instr_sltu <= ((is_alu_reg_reg & (3'h3 == mem_rdata_q[14:12])) & (7'h0 == mem_rdata_q[31:25]));
            instr_xor <= ((is_alu_reg_reg & (3'h4 == mem_rdata_q[14:12])) & (7'h0 == mem_rdata_q[31:25]));
            instr_srl <= ((is_alu_reg_reg & (3'h5 == mem_rdata_q[14:12])) & (7'h0 == mem_rdata_q[31:25]));
            instr_sra <= ((is_alu_reg_reg & (3'h5 == mem_rdata_q[14:12])) & (7'h20 == mem_rdata_q[31:25]));
            instr_or <= ((is_alu_reg_reg & (3'h6 == mem_rdata_q[14:12])) & (7'h0 == mem_rdata_q[31:25]));
            instr_and <= ((is_alu_reg_reg & (3'h7 == mem_rdata_q[14:12])) & (7'h0 == mem_rdata_q[31:25]));
            instr_rdcycle <= (((7'h73 == mem_rdata_q[6:0]) & (20'hc0002 == mem_rdata_q[31:12])) | ((7'h73 == mem_rdata_q[6:0]) & (20'hc0102 == mem_rdata_q[31:12])));
            instr_rdcycleh <= (((7'h73 == mem_rdata_q[6:0]) & (20'hc8002 == mem_rdata_q[31:12])) | ((7'h73 == mem_rdata_q[6:0]) & (20'hc8102 == mem_rdata_q[31:12])));
            instr_rdinstr <= ((7'h73 == mem_rdata_q[6:0]) & (20'hc0202 == mem_rdata_q[31:12]));
            instr_rdinstrh <= ((7'h73 == mem_rdata_q[6:0]) & (20'hc8202 == mem_rdata_q[31:12]));
            instr_ecall_ebreak <= ((((7'h73 == mem_rdata_q[6:0]) & ( ~ ( | mem_rdata_q[31:21]))) & ( ~ ( | mem_rdata_q[19:7]))) | (16'h9002 == mem_rdata_q[15:0]));
            instr_getq <= ((7'hb == mem_rdata_q[6:0]) & (7'h0 == mem_rdata_q[31:25]));
            instr_setq <= ((7'hb == mem_rdata_q[6:0]) & (7'h1 == mem_rdata_q[31:25]));
            instr_maskirq <= ((7'hb == mem_rdata_q[6:0]) & (7'h3 == mem_rdata_q[31:25]));
            instr_timer <= ((7'hb == mem_rdata_q[6:0]) & (7'h5 == mem_rdata_q[31:25]));
            is_slli_srli_srai <= (is_alu_reg_imm & (((3'h1 == mem_rdata_q[14:12]) & (7'h0 == mem_rdata_q[31:25])) | (((3'h5 == mem_rdata_q[14:12]) & (7'h0 == mem_rdata_q[31:25])) | ((3'h5 == mem_rdata_q[14:12]) & (7'h20 == mem_rdata_q[31:25])))));
            is_jalr_addi_slti_sltiu_xori_ori_andi <= (instr_jalr | (is_alu_reg_imm & ((3'h0 == mem_rdata_q[14:12]) | ((3'h2 == mem_rdata_q[14:12]) | ((3'h3 == mem_rdata_q[14:12]) | ((3'h4 == mem_rdata_q[14:12]) | ((3'h6 == mem_rdata_q[14:12]) | (3'h7 == mem_rdata_q[14:12]))))))));
            is_sll_srl_sra <= (is_alu_reg_reg & (((3'h1 == mem_rdata_q[14:12]) & (7'h0 == mem_rdata_q[31:25])) | (((3'h5 == mem_rdata_q[14:12]) & (7'h0 == mem_rdata_q[31:25])) | ((3'h5 == mem_rdata_q[14:12]) & (7'h20 == mem_rdata_q[31:25])))));
            is_lui_auipc_jal_jalr_addi_add_sub <= 1'h0;
            is_compare <= 1'h0;
            case(1'h1)
                instr_jal:
                    begin
                    decoded_imm <= decoded_imm_uj;
                    end
                (instr_lui | instr_auipc):
                    begin
                    decoded_imm <= ({1'b0,mem_rdata_q[31:12]} << 32'shc);
                    end
                (instr_jalr | (is_lb_lh_lw_lbu_lhu | is_alu_reg_imm)):
                    begin
                    decoded_imm <= $signed(mem_rdata_q[31:20]);
                    end
                is_beq_bne_blt_bge_bltu_bgeu:
                    begin
                    decoded_imm <= $signed({mem_rdata_q[31],{mem_rdata_q[7],{mem_rdata_q[30:25],{mem_rdata_q[11:8],1'h0}}}});
                    end
                is_sb_sh_sw:
                    begin
                    decoded_imm <= $signed({mem_rdata_q[31:25],mem_rdata_q[11:7]});
                    end
                default:decoded_imm <= 32'h0;
                endcase
            end;
        if ( ~ resetn) 
            begin
            is_beq_bne_blt_bge_bltu_bgeu <= 1'h0;
            is_compare <= 1'h0;
            instr_beq <= 1'h0;
            instr_bne <= 1'h0;
            instr_blt <= 1'h0;
            instr_bge <= 1'h0;
            instr_bltu <= 1'h0;
            instr_bgeu <= 1'h0;
            instr_addi <= 1'h0;
            instr_slti <= 1'h0;
            instr_sltiu <= 1'h0;
            instr_xori <= 1'h0;
            instr_ori <= 1'h0;
            instr_andi <= 1'h0;
            instr_add <= 1'h0;
            instr_sub <= 1'h0;
            instr_sll <= 1'h0;
            instr_slt <= 1'h0;
            instr_sltu <= 1'h0;
            instr_xor <= 1'h0;
            instr_srl <= 1'h0;
            instr_sra <= 1'h0;
            instr_or <= 1'h0;
            instr_and <= 1'h0;
            end
        end
    
/* example/picorv32.v:1175 */
always@* 
        begin
        dbg_ascii_state = 128'h0;
        if (8'h80 == cpu_state) dbg_ascii_state = 128'h74726170;
        if (8'h40 == cpu_state) dbg_ascii_state = 128'h6665746368;
        if (8'h20 == cpu_state) dbg_ascii_state = 128'h6c645f727331;
        if (8'h10 == cpu_state) dbg_ascii_state = 128'h6c645f727332;
        if (8'h8 == cpu_state) dbg_ascii_state = 128'h65786563;
        if (8'h4 == cpu_state) dbg_ascii_state = 128'h7368696674;
        if (8'h2 == cpu_state) dbg_ascii_state = 128'h73746d656d;
        if (8'h1 == cpu_state) dbg_ascii_state = 128'h6c646d656d;
        end
    
/* example/picorv32.v:1228 */
always@* 
        begin
        alu_add_sub = (instr_sub?(reg_op1-reg_op2):(reg_op1+reg_op2));
        alu_eq = (reg_op1 == reg_op2);
        alu_lts = ($signed(reg_op1) < $signed(reg_op2));
        alu_ltu = (reg_op1 < reg_op2);
        alu_shl = (reg_op1 << reg_op2[4:0]);
        alu_shr = (($signed({((instr_sra | instr_srai) & reg_op1[31]),reg_op1}) >>> reg_op2[4:0])>>0);
        end
    
/* example/picorv32.v:1238 */
always@* 
        begin
        case(1'h1)
            instr_beq:
                begin
                alu_out_0 = alu_eq;
                end
            instr_bne:
                begin
                alu_out_0 = ( ~ alu_eq);
                end
            instr_bge:
                begin
                alu_out_0 = ( ~ alu_lts);
                end
            instr_bgeu:
                begin
                alu_out_0 = ( ~ alu_ltu);
                end
            is_slti_blt_slt:
                begin
                alu_out_0 = alu_lts;
                end
            is_sltiu_bltu_sltu:
                begin
                alu_out_0 = alu_ltu;
                end
            default:alu_out_0 = 1'h0;
            endcase;
        case(1'h1)
            is_lui_auipc_jal_jalr_addi_add_sub:
                begin
                alu_out = alu_add_sub;
                end
            is_compare:
                begin
                alu_out = {1'b0,alu_out_0};
                end
            (instr_xori | instr_xor):
                begin
                alu_out = (reg_op1 ^ reg_op2);
                end
            (instr_ori | instr_or):
                begin
                alu_out = (reg_op1 | reg_op2);
                end
            (instr_andi | instr_and):
                begin
                alu_out = (reg_op1 & reg_op2);
                end
            1'h0:
                begin
                alu_out = alu_shl;
                end
            1'h0:
                begin
                alu_out = alu_shr;
                end
            default:alu_out = 32'h0;
            endcase
        end
    
/* example/picorv32.v:1280 */
always@(posedge clk)
        begin
        clear_prefetched_high_word_q <= clear_prefetched_high_word;
        end
    
/* example/picorv32.v:1282 */
always@* 
        begin
        clear_prefetched_high_word = clear_prefetched_high_word_q;
        if ( ~ prefetched_high_word) clear_prefetched_high_word = 1'h0;
        if ((latched_branch | ( | irq_state)) | ( ~ resetn)) clear_prefetched_high_word = 1'h1;
        end
    
/* example/picorv32.v:1296 */
always@* 
        begin
        cpuregs_write = 1'h0;
        cpuregs_wrdata = 32'h0;
        if (8'h40 == cpu_state) 
            begin
            case(1'h1)
                latched_branch:
                    begin
                    cpuregs_wrdata = (reg_pc+(latched_compr?32'sh2:32'sh4));
                    cpuregs_write = 1'h1;
                    end
                (latched_store & ( ~ latched_branch)):
                    begin
                    cpuregs_wrdata = (latched_stalu?alu_out_q:reg_out);
                    cpuregs_write = 1'h1;
                    end
                irq_state[0]:
                    begin
                    cpuregs_wrdata = (reg_next_pc | {1'b0,latched_compr});
                    cpuregs_write = 1'h1;
                    end
                irq_state[1]:
                    begin
                    cpuregs_wrdata = (irq_pending & ( ~ irq_mask));
                    cpuregs_write = 1'h1;
                    end
                endcase
            end
        end
    
/* example/picorv32.v:1324 */
always@(posedge clk) 
        begin
        if ((resetn & cpuregs_write) & ( | latched_rd)) 
            begin
            cpuregs[latched_rd] <= cpuregs_wrdata;
            end
        end
    
/* example/picorv32.v:1329 */
always@* 
        begin
        decoded_rs = 6'h0;
        
            begin
            cpuregs_rs1 = (( | decoded_rs1)?cpuregs[decoded_rs1]:32'sh0);
            cpuregs_rs2 = (( | decoded_rs2)?cpuregs[decoded_rs2]:32'sh0);
            end
        end
    
/* example/picorv32.v:1383 */
always@(posedge clk) 
        begin
        trap <= 1'h0;
        reg_sh <= 5'h0;
        reg_out <= 32'h0;
        set_mem_do_rinst = 1'h0;
        set_mem_do_rdata = 1'h0;
        set_mem_do_wdata = 1'h0;
        alu_out_0_q <= alu_out_0;
        alu_out_q <= alu_out;
        alu_wait <= 1'h0;
        alu_wait_2 <= 1'h0;
        if (launch_next_insn) 
            begin
            dbg_rs1val <= 32'h0;
            dbg_rs2val <= 32'h0;
            dbg_rs1val_valid <= 1'h0;
            dbg_rs2val_valid <= 1'h0;
            end;
        
            begin
            if ((resetn & pcpi_valid) & ( ~ pcpi_int_wait)) 
                begin
                if ( | pcpi_timeout_counter) 
                    begin
                    pcpi_timeout_counter <= (pcpi_timeout_counter-4'h1);
                    end
                end
            else
                begin
                pcpi_timeout_counter <= 4'hf;
                end;
            pcpi_timeout <= ( ~ ( | pcpi_timeout_counter));
            if (resetn) 
                begin
                count_cycle <= (64'h1+count_cycle);
                end
            else
                begin
                count_cycle <= 64'h0;
                end
            end;
        next_irq_pending = irq_pending;
        if ( | timer) 
            begin
            if (32'sh0 == (timer-32'sh1)) 
                begin
                next_irq_pending[0] = 1'h1;
                end;
            timer <= (timer-32'sh1);
            end;
        
            begin
            next_irq_pending = (next_irq_pending | irq);
            end;
        decoder_trigger <= (mem_do_rinst & mem_done);
        decoder_trigger_q <= decoder_trigger;
        decoder_pseudo_trigger <= 1'h0;
        decoder_pseudo_trigger_q <= decoder_pseudo_trigger;
        do_waitirq <= 1'h0;
        trace_valid <= 1'h0;
        if (resetn) 
            begin
            case(cpu_state)
                8'h80:
                    begin
                    trap <= 1'h1;
                    end
                8'h40:
                    begin
                    mem_do_rinst <= (( ~ decoder_trigger) & ( ~ do_waitirq));
                    mem_wordsize <= 2'h0;
                    current_pc = reg_next_pc;
                    case(1'h1)
                        latched_branch:
                            begin
                            current_pc = (latched_store?(32'hfffffffe & (latched_stalu?alu_out_q:reg_out)):reg_next_pc);
                            end
                        (latched_store & ( ~ latched_branch)):
                            begin
                            end
                        irq_state[0]:
                            begin
                            current_pc = 32'h10;
                            irq_active <= 1'h1;
                            mem_do_rinst <= 1'h1;
                            end
                        irq_state[1]:
                            begin
                            eoi <= (irq_pending & ( ~ irq_mask));
                            next_irq_pending = (next_irq_pending & irq_mask);
                            end
                        endcase;
                    if (latched_trace) 
                        begin
                        latched_trace <= 1'h0;
                        trace_valid <= 1'h1;
                        if (latched_branch) 
                            begin
                            trace_data <= (36'h100000000 | ((irq_active?36'h800000000:36'h0) | (36'hfffffffe & {1'b0,current_pc})));
                            end
                        else
                            begin
                            trace_data <= ((irq_active?36'h800000000:36'h0) | (latched_stalu?{1'b0,alu_out_q}:{1'b0,reg_out}));
                            end
                        end;
                    reg_pc <= current_pc;
                    reg_next_pc <= current_pc;
                    latched_store <= 1'h0;
                    latched_stalu <= 1'h0;
                    latched_branch <= 1'h0;
                    latched_is_lu <= 1'h0;
                    latched_is_lh <= 1'h0;
                    latched_is_lb <= 1'h0;
                    latched_rd <= decoded_rd;
                    latched_compr <= compressed_instr;
                    if ((((decoder_trigger & ( ~ irq_active)) & ( ~ irq_delay)) & ( | (irq_pending & ( ~ irq_mask)))) | ( | irq_state)) 
                        begin
                        if (2'h0 == irq_state) 
                            begin
                            irq_state <= 2'h1;
                            end
                        else
                            begin
                            irq_state <= ((2'h1 == irq_state)?2'h2:2'h0);
                            end;
                        latched_compr <= latched_compr;
                        latched_rd <= (6'h20 | ({1'b0,irq_state[0]}>>0));
                        end
                    else
                        begin
                        if ((decoder_trigger | do_waitirq) & instr_waitirq) 
                            begin
                            if ( | irq_pending) 
                                begin
                                latched_store <= 1'h1;
                                reg_out <= irq_pending;
                                reg_next_pc <= (current_pc+(compressed_instr?32'sh2:32'sh4));
                                mem_do_rinst <= 1'h1;
                                end
                            else
                                begin
                                do_waitirq <= 1'h1;
                                end
                            end
                        else
                            begin
                            if (decoder_trigger) 
                                begin
                                irq_delay <= irq_active;
                                reg_next_pc <= (current_pc+(compressed_instr?32'sh2:32'sh4));
                                latched_trace <= 1'h1;
                                
                                    begin
                                    count_instr <= (64'h1+count_instr);
                                    end;
                                if (instr_jal) 
                                    begin
                                    mem_do_rinst <= 1'h1;
                                    reg_next_pc <= (current_pc+decoded_imm_uj);
                                    latched_branch <= 1'h1;
                                    end
                                else
                                    begin
                                    mem_do_rinst <= 1'h0;
                                    mem_do_prefetch <= (( ~ instr_jalr) & ( ~ instr_retirq));
                                    cpu_state <= 8'h20;
                                    end
                                end
                            end
                        end
                    end
                8'h20:
                    begin
                    reg_op1 <= 32'h0;
                    reg_op2 <= 32'h0;
                    case(1'h1)
                        instr_trap:
                            begin
                            reg_op1 <= cpuregs_rs1;
                            dbg_rs1val <= cpuregs_rs1;
                            dbg_rs1val_valid <= 1'h1;
                            
                                begin
                                pcpi_valid <= 1'h1;
                                reg_sh <= cpuregs_rs2[4:0];
                                reg_op2 <= cpuregs_rs2;
                                dbg_rs2val <= cpuregs_rs2;
                                dbg_rs2val_valid <= 1'h1;
                                if (pcpi_int_ready) 
                                    begin
                                    mem_do_rinst <= 1'h1;
                                    pcpi_valid <= 1'h0;
                                    reg_out <= pcpi_int_rd;
                                    latched_store <= pcpi_int_wr;
                                    cpu_state <= 8'h40;
                                    end
                                else
                                    begin
                                    if (pcpi_timeout | instr_ecall_ebreak) 
                                        begin
                                        pcpi_valid <= 1'h0;
                                        if (( ~ irq_mask[1]) & ( ~ irq_active)) 
                                            begin
                                            next_irq_pending[1] = 1'h1;
                                            cpu_state <= 8'h40;
                                            end
                                        else
                                            begin
                                            cpu_state <= 8'h80;
                                            end
                                        end
                                    end
                                end
                            end
                        is_rdcycle_rdcycleh_rdinstr_rdinstrh:
                            begin
                            case(1'h1)
                                instr_rdcycle:
                                    begin
                                    reg_out <= count_cycle[31:0];
                                    end
                                instr_rdcycleh:
                                    begin
                                    reg_out <= count_cycle[63:32];
                                    end
                                instr_rdinstr:
                                    begin
                                    reg_out <= count_instr[31:0];
                                    end
                                instr_rdinstrh:
                                    begin
                                    reg_out <= count_instr[63:32];
                                    end
                                endcase;
                            latched_store <= 1'h1;
                            cpu_state <= 8'h40;
                            end
                        is_lui_auipc_jal:
                            begin
                            if (instr_lui) 
                                begin
                                reg_op1 <= 32'sh0;
                                end
                            else
                                begin
                                reg_op1 <= reg_pc;
                                end;
                            reg_op2 <= decoded_imm;
                            mem_do_rinst <= mem_do_prefetch;
                            cpu_state <= 8'h8;
                            end
                        instr_getq:
                            begin
                            reg_out <= cpuregs_rs1;
                            dbg_rs1val <= cpuregs_rs1;
                            dbg_rs1val_valid <= 1'h1;
                            latched_store <= 1'h1;
                            cpu_state <= 8'h40;
                            end
                        instr_setq:
                            begin
                            reg_out <= cpuregs_rs1;
                            dbg_rs1val <= cpuregs_rs1;
                            dbg_rs1val_valid <= 1'h1;
                            latched_rd <= (6'h20 | latched_rd);
                            latched_store <= 1'h1;
                            cpu_state <= 8'h40;
                            end
                        instr_retirq:
                            begin
                            eoi <= 32'sh0;
                            irq_active <= 1'h0;
                            latched_branch <= 1'h1;
                            latched_store <= 1'h1;
                            reg_out <= (32'hfffffffe & cpuregs_rs1);
                            dbg_rs1val <= cpuregs_rs1;
                            dbg_rs1val_valid <= 1'h1;
                            cpu_state <= 8'h40;
                            end
                        instr_maskirq:
                            begin
                            latched_store <= 1'h1;
                            reg_out <= irq_mask;
                            irq_mask <= cpuregs_rs1;
                            dbg_rs1val <= cpuregs_rs1;
                            dbg_rs1val_valid <= 1'h1;
                            cpu_state <= 8'h40;
                            end
                        instr_timer:
                            begin
                            latched_store <= 1'h1;
                            reg_out <= timer;
                            timer <= cpuregs_rs1;
                            dbg_rs1val <= cpuregs_rs1;
                            dbg_rs1val_valid <= 1'h1;
                            cpu_state <= 8'h40;
                            end
                        (is_lb_lh_lw_lbu_lhu & ( ~ instr_trap)):
                            begin
                            reg_op1 <= cpuregs_rs1;
                            dbg_rs1val <= cpuregs_rs1;
                            dbg_rs1val_valid <= 1'h1;
                            cpu_state <= 8'h1;
                            mem_do_rinst <= 1'h1;
                            end
                        is_slli_srli_srai:
                            begin
                            reg_op1 <= cpuregs_rs1;
                            dbg_rs1val <= cpuregs_rs1;
                            dbg_rs1val_valid <= 1'h1;
                            reg_sh <= decoded_rs2[4:0];
                            cpu_state <= 8'h4;
                            end
                        is_jalr_addi_slti_sltiu_xori_ori_andi,1'h0:
                            begin
                                begin
                                reg_op1 <= cpuregs_rs1;
                                dbg_rs1val <= cpuregs_rs1;
                                dbg_rs1val_valid <= 1'h1;
                                reg_op2 <= decoded_imm;
                                mem_do_rinst <= mem_do_prefetch;
                                cpu_state <= 8'h8;
                                end
                            end
                        default:
                            begin
                            reg_op1 <= cpuregs_rs1;
                            dbg_rs1val <= cpuregs_rs1;
                            dbg_rs1val_valid <= 1'h1;
                            
                                begin
                                reg_sh <= cpuregs_rs2[4:0];
                                reg_op2 <= cpuregs_rs2;
                                dbg_rs2val <= cpuregs_rs2;
                                dbg_rs2val_valid <= 1'h1;
                                case(1'h1)
                                    is_sb_sh_sw:
                                        begin
                                        cpu_state <= 8'h2;
                                        mem_do_rinst <= 1'h1;
                                        end
                                    is_sll_srl_sra:
                                        begin
                                        cpu_state <= 8'h4;
                                        end
                                    default:
                                        begin
                                        mem_do_rinst <= mem_do_prefetch;
                                        cpu_state <= 8'h8;
                                        end
                                    endcase
                                end
                            end
                        endcase
                    end
                8'h10:
                    begin
                    reg_sh <= cpuregs_rs2[4:0];
                    reg_op2 <= cpuregs_rs2;
                    dbg_rs2val <= cpuregs_rs2;
                    dbg_rs2val_valid <= 1'h1;
                    case(1'h1)
                        instr_trap:
                            begin
                            pcpi_valid <= 1'h1;
                            if (pcpi_int_ready) 
                                begin
                                mem_do_rinst <= 1'h1;
                                pcpi_valid <= 1'h0;
                                reg_out <= pcpi_int_rd;
                                latched_store <= pcpi_int_wr;
                                cpu_state <= 8'h40;
                                end
                            else
                                begin
                                if (pcpi_timeout | instr_ecall_ebreak) 
                                    begin
                                    pcpi_valid <= 1'h0;
                                    if (( ~ irq_mask[1]) & ( ~ irq_active)) 
                                        begin
                                        next_irq_pending[1] = 1'h1;
                                        cpu_state <= 8'h40;
                                        end
                                    else
                                        begin
                                        cpu_state <= 8'h80;
                                        end
                                    end
                                end
                            end
                        is_sb_sh_sw:
                            begin
                            cpu_state <= 8'h2;
                            mem_do_rinst <= 1'h1;
                            end
                        is_sll_srl_sra:
                            begin
                            cpu_state <= 8'h4;
                            end
                        default:
                            begin
                            mem_do_rinst <= mem_do_prefetch;
                            cpu_state <= 8'h8;
                            end
                        endcase
                    end
                8'h8:
                    begin
                    reg_out <= (reg_pc+decoded_imm);
                    if (is_beq_bne_blt_bge_bltu_bgeu) 
                        begin
                        latched_rd <= 6'h0;
                        latched_store <= alu_out_0;
                        latched_branch <= alu_out_0;
                        if (mem_done) 
                            begin
                            cpu_state <= 8'h40;
                            end;
                        if (alu_out_0) 
                            begin
                            decoder_trigger <= 1'h0;
                            set_mem_do_rinst = 1'h1;
                            end
                        end
                    else
                        begin
                        latched_branch <= instr_jalr;
                        latched_store <= 1'h1;
                        latched_stalu <= 1'h1;
                        cpu_state <= 8'h40;
                        end
                    end
                8'h4:
                    begin
                    latched_store <= 1'h1;
                    if (5'h0 == reg_sh) 
                        begin
                        reg_out <= reg_op1;
                        mem_do_rinst <= mem_do_prefetch;
                        cpu_state <= 8'h40;
                        end
                    else
                        begin
                        if (5'h4 <= reg_sh) 
                            begin
                            case(1'h1)
                                (instr_slli | instr_sll):
                                    begin
                                    reg_op1 <= (reg_op1 << 32'sh4);
                                    end
                                (instr_srli | instr_srl):
                                    begin
                                    reg_op1 <= (reg_op1 >> 32'sh4);
                                    end
                                (instr_srai | instr_sra):
                                    begin
                                    reg_op1 <= ($signed(reg_op1) >>> 32'sh4);
                                    end
                                endcase;
                            reg_sh <= (reg_sh-5'h4);
                            end
                        else
                            begin
                            case(1'h1)
                                (instr_slli | instr_sll):
                                    begin
                                    reg_op1 <= (reg_op1 << 32'sh1);
                                    end
                                (instr_srli | instr_srl):
                                    begin
                                    reg_op1 <= (reg_op1 >> 32'sh1);
                                    end
                                (instr_srai | instr_sra):
                                    begin
                                    reg_op1 <= ($signed(reg_op1) >>> 32'sh1);
                                    end
                                endcase;
                            reg_sh <= (reg_sh-5'h1);
                            end
                        end
                    end
                8'h2:
                    begin
                    reg_out <= reg_op2;
                    if (( ~ mem_do_prefetch) | mem_done) 
                        begin
                        if ( ~ mem_do_wdata) 
                            begin
                            case(1'h1)
                                instr_sb:
                                    begin
                                    mem_wordsize <= 2'h2;
                                    end
                                instr_sh:
                                    begin
                                    mem_wordsize <= 2'h1;
                                    end
                                instr_sw:
                                    begin
                                    mem_wordsize <= 2'h0;
                                    end
                                endcase;
                            
                                begin
                                trace_valid <= 1'h1;
                                trace_data <= (36'h200000000 | ((irq_active?36'h800000000:36'h0) | (36'hffffffff & ({1'b0,reg_op1}+{1'b0,decoded_imm}))));
                                end;
                            reg_op1 <= (reg_op1+decoded_imm);
                            set_mem_do_wdata = 1'h1;
                            end;
                        if (( ~ mem_do_prefetch) & mem_done) 
                            begin
                            cpu_state <= 8'h40;
                            decoder_trigger <= 1'h1;
                            decoder_pseudo_trigger <= 1'h1;
                            end
                        end
                    end
                8'h1:
                    begin
                    latched_store <= 1'h1;
                    if (( ~ mem_do_prefetch) | mem_done) 
                        begin
                        if ( ~ mem_do_rdata) 
                            begin
                            case(1'h1)
                                (instr_lb | instr_lbu):
                                    begin
                                    mem_wordsize <= 2'h2;
                                    end
                                (instr_lh | instr_lhu):
                                    begin
                                    mem_wordsize <= 2'h1;
                                    end
                                instr_lw:
                                    begin
                                    mem_wordsize <= 2'h0;
                                    end
                                endcase;
                            latched_is_lu <= is_lbu_lhu_lw;
                            latched_is_lh <= instr_lh;
                            latched_is_lb <= instr_lb;
                            
                                begin
                                trace_valid <= 1'h1;
                                trace_data <= (36'h200000000 | ((irq_active?36'h800000000:36'h0) | (36'hffffffff & ({1'b0,reg_op1}+{1'b0,decoded_imm}))));
                                end;
                            reg_op1 <= (reg_op1+decoded_imm);
                            set_mem_do_rdata = 1'h1;
                            end;
                        if (( ~ mem_do_prefetch) & mem_done) 
                            begin
                            case(1'h1)
                                latched_is_lu:
                                    begin
                                    reg_out <= mem_rdata_word;
                                    end
                                latched_is_lh:
                                    begin
                                    reg_out <= $signed(mem_rdata_word[15:0]);
                                    end
                                latched_is_lb:
                                    begin
                                    reg_out <= $signed(mem_rdata_word[7:0]);
                                    end
                                endcase;
                            decoder_trigger <= 1'h1;
                            decoder_pseudo_trigger <= 1'h1;
                            cpu_state <= 8'h40;
                            end
                        end
                    end
                endcase
            end
        else
            begin
            reg_pc <= io_reset_vector;
            reg_next_pc <= io_reset_vector;
            count_instr <= 64'h0;
            latched_store <= 1'h0;
            latched_stalu <= 1'h0;
            latched_branch <= 1'h0;
            latched_trace <= 1'h0;
            latched_is_lu <= 1'h0;
            latched_is_lh <= 1'h0;
            latched_is_lb <= 1'h0;
            pcpi_valid <= 1'h0;
            pcpi_timeout <= 1'h0;
            irq_active <= 1'h0;
            irq_delay <= 1'h0;
            irq_mask <= 32'hffffffff;
            next_irq_pending = 32'sh0;
            irq_state <= 2'h0;
            eoi <= 32'sh0;
            timer <= 32'sh0;
            cpu_state <= 8'h40;
            end;
        if (resetn & (mem_do_rdata | mem_do_wdata)) 
            begin
            if ((2'h0 == mem_wordsize) & (2'h0 != reg_op1[1:0])) 
                begin
                if (( ~ irq_mask[2]) & ( ~ irq_active)) 
                    begin
                    next_irq_pending[2] = 1'h1;
                    end
                else
                    begin
                    cpu_state <= 8'h80;
                    end
                end;
            if ((2'h1 == mem_wordsize) & reg_op1[0]) 
                begin
                if (( ~ irq_mask[2]) & ( ~ irq_active)) 
                    begin
                    next_irq_pending[2] = 1'h1;
                    end
                else
                    begin
                    cpu_state <= 8'h80;
                    end
                end
            end;
        if ((resetn & mem_do_rinst) & reg_pc[0]) 
            begin
            if (( ~ irq_mask[2]) & ( ~ irq_active)) 
                begin
                next_irq_pending[2] = 1'h1;
                end
            else
                begin
                cpu_state <= 8'h80;
                end
            end;
        if (( ~ resetn) | mem_done) 
            begin
            mem_do_prefetch <= 1'h0;
            mem_do_rinst <= 1'h0;
            mem_do_rdata <= 1'h0;
            mem_do_wdata <= 1'h0;
            end;
        if (set_mem_do_rinst) 
            begin
            mem_do_rinst <= 1'h1;
            end;
        if (set_mem_do_rdata) 
            begin
            mem_do_rdata <= 1'h1;
            end;
        if (set_mem_do_wdata) 
            begin
            mem_do_wdata <= 1'h1;
            end;
        irq_pending <= next_irq_pending;
        current_pc = 32'h0;
        end
    picorv32_pcpi_mul_opt _genblk2_genblk1_pcpi_mul( 
    .clk(clk),
    .resetn(resetn),
    .pcpi_valid(pcpi_valid),
    .pcpi_insn(pcpi_insn),
    .pcpi_rs1(pcpi_rs1),
    .pcpi_rs2(pcpi_rs2),
    .pcpi_wr(pcpi_mul_wr),
    .pcpi_rd(pcpi_mul_rd),
    .pcpi_wait(pcpi_mul_wait),
    .pcpi_ready(pcpi_mul_ready)
    );
    picorv32_pcpi_div_opt _genblk3_pcpi_div( 
    .clk(clk),
    .resetn(resetn),
    .pcpi_valid(pcpi_valid),
    .pcpi_insn(pcpi_insn),
    .pcpi_rs1(pcpi_rs1),
    .pcpi_rs2(pcpi_rs2),
    .pcpi_wr(pcpi_div_wr),
    .pcpi_rd(pcpi_div_rd),
    .pcpi_wait(pcpi_div_wait),
    .pcpi_ready(pcpi_div_ready)
    );
    initial
        begin
        dbg_reg_x0 = 32'sh0;
        end
    endmodule
