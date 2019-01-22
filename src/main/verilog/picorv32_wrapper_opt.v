
module picorv32_wrapper_opt(
    input logic clk,
    input logic resetn,
    output logic trap,
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
    output logic trace_valid,
    output logic[35:0] trace_data);
    logic tests_passed;
    logic [31:0] irq;
    logic mem_axi_awvalid;
    logic mem_axi_awready;
    logic [31:0] mem_axi_awaddr;
    logic [2:0] mem_axi_awprot;
    logic mem_axi_wvalid;
    logic mem_axi_wready;
    logic [31:0] mem_axi_wdata;
    logic [3:0] mem_axi_wstrb;
    logic mem_axi_bvalid;
    logic mem_axi_bready;
    logic mem_axi_arvalid;
    logic mem_axi_arready;
    logic [31:0] mem_axi_araddr;
    logic [2:0] mem_axi_arprot;
    logic mem_axi_rvalid;
    logic mem_axi_rready;
    logic [31:0] mem_axi_rdata;
    logic [1023:0] firmware_file;
    logic [31:0] cycle_counter;
    
/* example/picorv32_wrapper.v:50 */
always@* 
        begin
        irq = 32'sh0;
        irq[4] = ( & uut.picorv32_core.count_cycle[12:0]);
        irq[5] = ( & uut.picorv32_core.count_cycle[15:0]);
        end
    
/* example/picorv32_wrapper.v:258 */
always@(posedge clk) 
        begin
        if (resetn) 
            begin
            cycle_counter <= (32'sh1+cycle_counter);
            end
        else
            begin
            cycle_counter <= 32'sh0;
            end;
        if (resetn & trap) 
            begin
            $display("TRAP after %1~ clock cycles",cycle_counter);
            if (tests_passed) 
                begin
                $display("ALL TESTS PASSED.");
                $finish();
                end
            else
                begin
                $display("ERROR!");
                if ( | $test$plusargs("noerror")) 
                    begin
                    $finish();
                    end;
                $stop();
                end
            end
        end
    axi4_memory_opt mem( 
    .clk(clk),
    .mem_axi_awvalid(mem_axi_awvalid),
    .mem_axi_awready(mem_axi_awready),
    .mem_axi_awaddr(mem_axi_awaddr),
    .mem_axi_awprot(mem_axi_awprot),
    .mem_axi_wvalid(mem_axi_wvalid),
    .mem_axi_wready(mem_axi_wready),
    .mem_axi_wdata(mem_axi_wdata),
    .mem_axi_wstrb(mem_axi_wstrb),
    .mem_axi_bvalid(mem_axi_bvalid),
    .mem_axi_bready(mem_axi_bready),
    .mem_axi_arvalid(mem_axi_arvalid),
    .mem_axi_arready(mem_axi_arready),
    .mem_axi_araddr(mem_axi_araddr),
    .mem_axi_arprot(mem_axi_arprot),
    .mem_axi_rvalid(mem_axi_rvalid),
    .mem_axi_rready(mem_axi_rready),
    .mem_axi_rdata(mem_axi_rdata),
    .tests_passed(tests_passed)
    );
    picorv32_axi__pi1_opt uut( 
    .clk(clk),
    .resetn(resetn),
    .trap(trap),
    .mem_axi_awvalid(mem_axi_awvalid),
    .mem_axi_awready(mem_axi_awready),
    .mem_axi_awaddr(mem_axi_awaddr),
    .mem_axi_awprot(mem_axi_awprot),
    .mem_axi_wvalid(mem_axi_wvalid),
    .mem_axi_wready(mem_axi_wready),
    .mem_axi_wdata(mem_axi_wdata),
    .mem_axi_wstrb(mem_axi_wstrb),
    .mem_axi_bvalid(mem_axi_bvalid),
    .mem_axi_bready(mem_axi_bready),
    .mem_axi_arvalid(mem_axi_arvalid),
    .mem_axi_arready(mem_axi_arready),
    .mem_axi_araddr(mem_axi_araddr),
    .mem_axi_arprot(mem_axi_arprot),
    .mem_axi_rvalid(mem_axi_rvalid),
    .mem_axi_rready(mem_axi_rready),
    .mem_axi_rdata(mem_axi_rdata),
    .irq(irq),
    .dbg_reg_x0(dbg_reg_x0),
    .dbg_reg_x1(dbg_reg_x1),
    .dbg_reg_x2(dbg_reg_x2),
    .dbg_reg_x3(dbg_reg_x3),
    .dbg_reg_x4(dbg_reg_x4),
    .dbg_reg_x5(dbg_reg_x5),
    .dbg_reg_x6(dbg_reg_x6),
    .dbg_reg_x7(dbg_reg_x7),
    .dbg_reg_x8(dbg_reg_x8),
    .dbg_reg_x9(dbg_reg_x9),
    .dbg_reg_x10(dbg_reg_x10),
    .dbg_reg_x11(dbg_reg_x11),
    .dbg_reg_x12(dbg_reg_x12),
    .dbg_reg_x13(dbg_reg_x13),
    .dbg_reg_x14(dbg_reg_x14),
    .dbg_reg_x15(dbg_reg_x15),
    .dbg_reg_x16(dbg_reg_x16),
    .dbg_reg_x17(dbg_reg_x17),
    .dbg_reg_x18(dbg_reg_x18),
    .dbg_reg_x19(dbg_reg_x19),
    .dbg_reg_x20(dbg_reg_x20),
    .dbg_reg_x21(dbg_reg_x21),
    .dbg_reg_x22(dbg_reg_x22),
    .dbg_reg_x23(dbg_reg_x23),
    .dbg_reg_x24(dbg_reg_x24),
    .dbg_reg_x25(dbg_reg_x25),
    .dbg_reg_x26(dbg_reg_x26),
    .dbg_reg_x27(dbg_reg_x27),
    .dbg_reg_x28(dbg_reg_x28),
    .dbg_reg_x29(dbg_reg_x29),
    .dbg_reg_x30(dbg_reg_x30),
    .dbg_reg_x31(dbg_reg_x31),
    .trace_valid(trace_valid),
    .trace_data(trace_data),
    .pcpi_valid(),
    .pcpi_insn(),
    .pcpi_rs1(),
    .pcpi_rs2(),
    .pcpi_wr(),
    .pcpi_rd(),
    .pcpi_wait(),
    .pcpi_ready(),
    .eoi()
    );
    initial 
        begin
        if ( ! $value$plusargs("firmware=%s",firmware_file)) firmware_file = "firmware/firmware.hex";
        $readmemh( firmware_file,mem.memory);
        end
    endmodule
