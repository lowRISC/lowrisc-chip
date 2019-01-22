
module picorv32_axi_adapter_opt(
    input logic clk,
    input logic resetn,
    output logic mem_axi_awvalid,
    input logic mem_axi_awready,
    output logic[31:0] mem_axi_awaddr,
    output logic[2:0] mem_axi_awprot,
    output logic mem_axi_wvalid,
    input logic mem_axi_wready,
    output logic[31:0] mem_axi_wdata,
    output logic[3:0] mem_axi_wstrb,
    input logic mem_axi_bvalid,
    output logic mem_axi_bready,
    output logic mem_axi_arvalid,
    input logic mem_axi_arready,
    output logic[31:0] mem_axi_araddr,
    output logic[2:0] mem_axi_arprot,
    input logic mem_axi_rvalid,
    output logic mem_axi_rready,
    input logic[31:0] mem_axi_rdata,
    input logic mem_valid,
    input logic mem_instr,
    output logic mem_ready,
    input logic[31:0] mem_addr,
    input logic[31:0] mem_wdata,
    input logic[3:0] mem_wstrb,
    output logic[31:0] mem_rdata);
    logic ack_awvalid;
    logic ack_arvalid;
    logic ack_wvalid;
    logic xfer_done;
    assign mem_axi_awvalid = ((mem_valid & ( | mem_wstrb)) & ( ~ ack_awvalid));
    assign mem_axi_awaddr = mem_addr;
    assign mem_axi_arvalid = ((mem_valid & ( ~ ( | mem_wstrb))) & ( ~ ack_arvalid));
    assign mem_axi_araddr = mem_addr;
    assign mem_axi_arprot = (mem_instr?3'h4:3'h0);
    assign mem_axi_wvalid = ((mem_valid & ( | mem_wstrb)) & ( ~ ack_wvalid));
    assign mem_axi_wdata = mem_wdata;
    assign mem_axi_wstrb = mem_wstrb;
    assign mem_ready = (mem_axi_bvalid | mem_axi_rvalid);
    assign mem_axi_bready = (mem_valid & ( | mem_wstrb));
    assign mem_axi_rready = (mem_valid & ( ~ ( | mem_wstrb)));
    assign mem_rdata = mem_axi_rdata;
    
/* example/picorv32_axi_adapter.v:65 */
always@(posedge clk) 
        begin
        if (resetn) 
            begin
            xfer_done <= (mem_valid & mem_ready);
            if (mem_axi_awready & mem_axi_awvalid) 
                begin
                ack_awvalid <= 1'h1;
                end;
            if (mem_axi_arready & mem_axi_arvalid) 
                begin
                ack_arvalid <= 1'h1;
                end;
            if (mem_axi_wready & mem_axi_wvalid) 
                begin
                ack_wvalid <= 1'h1;
                end;
            if (xfer_done | ( ~ mem_valid)) 
                begin
                ack_awvalid <= 1'h0;
                ack_arvalid <= 1'h0;
                ack_wvalid <= 1'h0;
                end
            end
        else
            begin
            ack_awvalid <= 1'h0;
            end
        end
    initial
        begin
        mem_axi_awprot = 3'h0;
        end
    endmodule
