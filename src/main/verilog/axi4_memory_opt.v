
module axi4_memory_opt(
    input logic clk,
    input logic mem_axi_awvalid,
    output logic mem_axi_awready,
    input logic[31:0] mem_axi_awaddr,
    input logic[2:0] mem_axi_awprot,
    input logic mem_axi_wvalid,
    output logic mem_axi_wready,
    input logic[31:0] mem_axi_wdata,
    input logic[3:0] mem_axi_wstrb,
    output logic mem_axi_bvalid,
    input logic mem_axi_bready,
    input logic mem_axi_arvalid,
    output logic mem_axi_arready,
    input logic[31:0] mem_axi_araddr,
    input logic[2:0] mem_axi_arprot,
    output logic mem_axi_rvalid,
    input logic mem_axi_rready,
    output logic[31:0] mem_axi_rdata,
    output logic tests_passed);
    logic [31:0] memory [16383:0];
    logic verbose;
    logic axi_test;
    logic [63:0] xorshift64_state;
    logic [2:0] fast_axi_transaction;
    logic [4:0] async_axi_transaction;
    logic [4:0] delay_axi_transaction;
    logic latched_raddr_en;
    logic latched_waddr_en;
    logic latched_wdata_en;
    logic fast_raddr;
    logic fast_waddr;
    logic fast_wdata;
    logic [31:0] latched_raddr;
    logic [31:0] latched_waddr;
    logic [31:0] latched_wdata;
    logic [3:0] latched_wstrb;
    logic latched_rinsn;
    task xorshift64_next;
        
            begin
            xorshift64_state = (xorshift64_state ^ (xorshift64_state << 32'shd));
            xorshift64_state = (xorshift64_state ^ (xorshift64_state >> 32'sh7));
            xorshift64_state = (xorshift64_state ^ (xorshift64_state << 32'sh11));
            
            end
        endtask
    task handle_axi_arvalid;
        
            begin
            mem_axi_arready <= 1'h1;
            latched_raddr = mem_axi_araddr;
            latched_rinsn = mem_axi_arprot[2];
            latched_raddr_en = 1'h1;
            fast_raddr <= 1'h1;
            
            end
        endtask
    task handle_axi_awvalid;
        
            begin
            mem_axi_awready <= 1'h1;
            latched_waddr = mem_axi_awaddr;
            latched_waddr_en = 1'h1;
            fast_waddr <= 1'h1;
            
            end
        endtask
    task handle_axi_wvalid;
        
            begin
            mem_axi_wready <= 1'h1;
            latched_wdata = mem_axi_wdata;
            latched_wstrb = mem_axi_wstrb;
            latched_wdata_en = 1'h1;
            fast_wdata <= 1'h1;
            
            end
        endtask
    task handle_axi_rvalid;
        
            begin
            if (verbose) $display("RD: ADDR=%08x DATA=%08x%s",latched_raddr,memory[latched_raddr[15:2]],(latched_rinsn?40'h20494e534e:40'h0));
            if (32'h10000 > latched_raddr) 
                begin
                mem_axi_rdata <= memory[latched_raddr[15:2]];
                mem_axi_rvalid <= 1'h1;
                latched_raddr_en = 1'h0;
                end
            else
                begin
                $display("OUT-OF-BOUNDS MEMORY READ FROM %08x",latched_raddr);
                $finish();
                end;
            
            end
        endtask
    task handle_axi_bvalid;
        
            begin
            if (verbose) $display("WR: ADDR=%08x DATA=%08x STRB=%04b",latched_waddr,latched_wdata,latched_wstrb);
            if (32'h10000 > latched_waddr) 
                begin
                if (latched_wstrb[0]) memory[latched_waddr[15:2]][7:0] <= latched_wdata[7:0];
                if (latched_wstrb[1]) memory[latched_waddr[15:2]][15:8] <= latched_wdata[15:8];
                if (latched_wstrb[2]) memory[latched_waddr[15:2]][23:16] <= latched_wdata[23:16];
                if (latched_wstrb[3]) memory[latched_waddr[15:2]][31:24] <= latched_wdata[31:24];
                end
            else if (32'h10000000 == latched_waddr) 
                begin
                if (verbose) 
                    begin
                    if ((32'sh20 <= latched_wdata) & (32'sh80 > latched_wdata)) $display("OUT: '%c'",latched_wdata[7:0]);
                    else
                    $display("OUT: %3d",latched_wdata);
                    end
                else
                    begin
                    $write("%c",latched_wdata[7:0]);
                    end
                end
            else if (32'h20000000 == latched_waddr) 
                begin
                if (32'sh75bcd15 == latched_wdata) tests_passed = 1'h1;
                end
            else
                begin
                $display("OUT-OF-BOUNDS MEMORY WRITE TO %08x",latched_waddr);
                $finish();
                end;
            mem_axi_bvalid <= 1'h1;
            latched_waddr_en = 1'h0;
            latched_wdata_en = 1'h0;
            
            end
        endtask
    
/* example/axi4_memory.v:81 */
always@(posedge clk) 
        begin
        if (axi_test) 
            begin
            xorshift64_next;
            fast_axi_transaction <= xorshift64_state[12:10];
            async_axi_transaction <= xorshift64_state[9:5];
            delay_axi_transaction <= xorshift64_state[4:0];
            end
        end
    
/* example/axi4_memory.v:172 */
always@(negedge clk) 
        begin
        if ((mem_axi_arvalid & ( ~ (latched_raddr_en | fast_raddr))) & async_axi_transaction[0]) 
            begin
            handle_axi_arvalid;
            end;
        if ((mem_axi_awvalid & ( ~ (latched_waddr_en | fast_waddr))) & async_axi_transaction[1]) 
            begin
            handle_axi_awvalid;
            end;
        if ((mem_axi_wvalid & ( ~ (latched_wdata_en | fast_wdata))) & async_axi_transaction[2]) 
            begin
            handle_axi_wvalid;
            end;
        if ((( ~ mem_axi_rvalid) & latched_raddr_en) & async_axi_transaction[3]) 
            begin
            handle_axi_rvalid;
            end;
        if (((( ~ mem_axi_bvalid) & latched_waddr_en) & latched_wdata_en) & async_axi_transaction[4]) 
            begin
            handle_axi_bvalid;
            end
        end
    
/* example/axi4_memory.v:180 */
always@(posedge clk) 
        begin
        mem_axi_arready <= 1'h0;
        mem_axi_awready <= 1'h0;
        mem_axi_wready <= 1'h0;
        fast_raddr <= 1'h0;
        fast_waddr <= 1'h0;
        fast_wdata <= 1'h0;
        if (mem_axi_rvalid & mem_axi_rready) 
            begin
            mem_axi_rvalid <= 1'h0;
            end;
        if (mem_axi_bvalid & mem_axi_bready) 
            begin
            mem_axi_bvalid <= 1'h0;
            end;
        if ((mem_axi_arvalid & mem_axi_arready) & ( ~ fast_raddr)) 
            begin
            latched_raddr = mem_axi_araddr;
            latched_rinsn = mem_axi_arprot[2];
            latched_raddr_en = 1'h1;
            end;
        if ((mem_axi_awvalid & mem_axi_awready) & ( ~ fast_waddr)) 
            begin
            latched_waddr = mem_axi_awaddr;
            latched_waddr_en = 1'h1;
            end;
        if ((mem_axi_wvalid & mem_axi_wready) & ( ~ fast_wdata)) 
            begin
            latched_wdata = mem_axi_wdata;
            latched_wstrb = mem_axi_wstrb;
            latched_wdata_en = 1'h1;
            end;
        if ((mem_axi_arvalid & ( ~ (latched_raddr_en | fast_raddr))) & ( ~ delay_axi_transaction[0])) 
            begin
            handle_axi_arvalid;
            end;
        if ((mem_axi_awvalid & ( ~ (latched_waddr_en | fast_waddr))) & ( ~ delay_axi_transaction[1])) 
            begin
            handle_axi_awvalid;
            end;
        if ((mem_axi_wvalid & ( ~ (latched_wdata_en | fast_wdata))) & ( ~ delay_axi_transaction[2])) 
            begin
            handle_axi_wvalid;
            end;
        if ((( ~ mem_axi_rvalid) & latched_raddr_en) & ( ~ delay_axi_transaction[3])) 
            begin
            handle_axi_rvalid;
            end;
        if (((( ~ mem_axi_bvalid) & latched_waddr_en) & latched_wdata_en) & ( ~ delay_axi_transaction[4])) 
            begin
            handle_axi_bvalid;
            end
        end
    initial
        begin
        fast_wdata = 1'h0;
        end
    initial
        begin
        fast_waddr = 1'h0;
        end
    initial
        begin
        fast_raddr = 1'h0;
        end
    initial
        begin
        latched_wdata_en = 1'h0;
        end
    initial
        begin
        latched_waddr_en = 1'h0;
        end
    initial
        begin
        latched_raddr_en = 1'h0;
        end
    initial
        begin
        delay_axi_transaction = 5'h0;
        end
    initial
        begin
        async_axi_transaction = 5'h1f;
        end
    initial
        begin
        fast_axi_transaction = 3'h7;
        end
    initial
        begin
        xorshift64_state = 64'h139408dcbbf7a44;
        end
    initial 
        begin
        mem_axi_awready = 1'h0;
        mem_axi_wready = 1'h0;
        mem_axi_bvalid = 1'h0;
        mem_axi_arready = 1'h0;
        mem_axi_rvalid = 1'h0;
        tests_passed = 1'h0;
        end
    initial
        begin
        axi_test = ( | $test$plusargs("axi_test"));
        end
    initial
        begin
        verbose = ( | $test$plusargs("verbose"));
        end
    endmodule
