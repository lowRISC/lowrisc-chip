// See LICENSE for license details.

`include "config.vh"
`include "consts.DefaultConfig.vh"

module chip_top
  (
   // clock
`ifdef SIMULATION
   input clk_top,
`elsif FPGA
   input clk_p, clk_n,
`else
   input clk_top,
`endif

   // reset
   input rst_top,

   // UART
   input rxd,
   output txd
   );

   // get the clock and reset signal
   logic  clk, rst, rstn;

`ifdef SIMULATION

   assign clk = clk_top;
   assign rst = rst_top;
   assign rstn = !rst;

`elsif FPGA
 `ifdef USE_PLL
   
   clk_wiz_0 mmcm
     (
      .clk_in1_p   ( clk_p   ),
      .clk_in1_n   ( clk_n   ),
      .clk_out1    ( clk     ),
      .reset       ( rst_top ),
      .locked      ( rstn    )
      );
   assign rst = !rstn;
 
 `else // !`ifdef USE_PLL

   IBUFGDS clk_buf (.O(clk), .I(clk_p), .IB(clk_n));
   assign rst = rst_top;
   assign rstn = !rst;
   
 `endif
`else

   assign clk = clk_top;
   assign rst = rst_top;
   assign rstn = !rst;

`endif

   // the NASTI bus for cached memory
   nasti_aw mem_nasti_aw();
   nasti_w  mem_nasti_w();
   nasti_b  mem_nasti_b();
   nasti_ar mem_nasti_ar();
   nasti_r  mem_nasti_r();

   defparam mem_nasti_aw.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam mem_nasti_b.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam mem_nasti_ar.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam mem_nasti_r.ID_WIDTH  = `MEM_TAG_WIDTH;
   defparam mem_nasti_aw.ADDR_WIDTH = `PADDR_WIDTH;
   defparam mem_nasti_ar.ADDR_WIDTH = `PADDR_WIDTH;
   defparam mem_nasti_w.DATA_WIDTH = `MEM_DAT_WIDTH;
   defparam mem_nasti_r.DATA_WIDTH = `MEM_DAT_WIDTH;
   
   // the NASTI-Lite bus for IO space
   nasti_aw io_nasti_aw();
   nasti_w  io_nasti_w();
   nasti_b  io_nasti_b();
   nasti_ar io_nasti_ar();
   nasti_r  io_nasti_r();

   defparam io_nasti_aw.ADDR_WIDTH = 16;
   defparam io_nasti_ar.ADDR_WIDTH = 16;
   defparam io_nasti_w.DATA_WIDTH = `IO_DAT_WIDTH;
   defparam io_nasti_r.DATA_WIDTH = `IO_DAT_WIDTH;
   
   // the Rocket chip
   Top Rocket
     (
      .clk                           ( clk                 ),
      .reset                         ( rst                 ),

      .io_nasti_aw_valid             ( mem_nasti_aw.valid  ),
      .io_nasti_aw_ready             ( mem_nasti_aw.ready  ),
      .io_nasti_aw_bits_id           ( mem_nasti_aw.id     ),
      .io_nasti_aw_bits_addr         ( mem_nasti_aw.addr   ),
      .io_nasti_aw_bits_len          ( mem_nasti_aw.len    ),
      .io_nasti_aw_bits_size         ( mem_nasti_aw.size   ),
      .io_nasti_aw_bits_burst        ( mem_nasti_aw.burst  ),
      .io_nasti_aw_bits_lock         ( mem_nasti_aw.lock   ),
      .io_nasti_aw_bits_cache        ( mem_nasti_aw.cache  ),
      .io_nasti_aw_bits_prot         ( mem_nasti_aw.prot   ),
      .io_nasti_aw_bits_qos          ( mem_nasti_aw.qos    ),
      .io_nasti_aw_bits_region       ( mem_nasti_aw.region ),
      .io_nasti_aw_bits_user         ( mem_nasti_aw.user   ),

      .io_nasti_w_valid              ( mem_nasti_w.valid   ),
      .io_nasti_w_ready              ( mem_nasti_w.ready   ),
      .io_nasti_w_bits_data          ( mem_nasti_w.data    ),
      .io_nasti_w_bits_strb          ( mem_nasti_w.strb    ),
      .io_nasti_w_bits_last          ( mem_nasti_w.last    ),
      .io_nasti_w_bits_user          ( mem_nasti_w.user    ),

      .io_nasti_b_valid              ( mem_nasti_b.valid   ),
      .io_nasti_b_ready              ( mem_nasti_b.ready   ),
      .io_nasti_b_bits_id            ( mem_nasti_b.id      ),
      .io_nasti_b_bits_resp          ( mem_nasti_b.resp    ),
      .io_nasti_b_bits_user          ( mem_nasti_b.user    ),

      .io_nasti_ar_valid             ( mem_nasti_ar.valid  ),
      .io_nasti_ar_ready             ( mem_nasti_ar.ready  ),
      .io_nasti_ar_bits_id           ( mem_nasti_ar.id     ),
      .io_nasti_ar_bits_addr         ( mem_nasti_ar.addr   ),
      .io_nasti_ar_bits_len          ( mem_nasti_ar.len    ),
      .io_nasti_ar_bits_size         ( mem_nasti_ar.size   ),
      .io_nasti_ar_bits_burst        ( mem_nasti_ar.burst  ),
      .io_nasti_ar_bits_lock         ( mem_nasti_ar.lock   ),
      .io_nasti_ar_bits_cache        ( mem_nasti_ar.cache  ),
      .io_nasti_ar_bits_prot         ( mem_nasti_ar.prot   ),
      .io_nasti_ar_bits_qos          ( mem_nasti_ar.qos    ),
      .io_nasti_ar_bits_region       ( mem_nasti_ar.region ),
      .io_nasti_ar_bits_user         ( mem_nasti_ar.user   ),

      .io_nasti_r_valid              ( mem_nasti_r.valid   ),
      .io_nasti_r_ready              ( mem_nasti_r.ready   ),
      .io_nasti_r_bits_id            ( mem_nasti_r.id      ),
      .io_nasti_r_bits_data          ( mem_nasti_r.data    ),
      .io_nasti_r_bits_resp          ( mem_nasti_r.resp    ),
      .io_nasti_r_bits_last          ( mem_nasti_r.last    ),
      .io_nasti_r_bits_user          ( mem_nasti_r.user    ),

      .io_nasti_lite_aw_valid        ( io_nasti_aw.valid   ),
      .io_nasti_lite_aw_ready        ( io_nasti_aw.ready   ),
      .io_nasti_lite_aw_bits_id      ( io_nasti_aw.id      ),
      .io_nasti_lite_aw_bits_addr    ( io_nasti_aw.addr    ),
      .io_nasti_lite_aw_bits_prot    ( io_nasti_aw.prot    ),
      .io_nasti_lite_aw_bits_qos     ( io_nasti_aw.qos     ),
      .io_nasti_lite_aw_bits_region  ( io_nasti_aw.region  ),
      .io_nasti_lite_aw_bits_user    ( io_nasti_aw.user    ),

      .io_nasti_lite_w_valid         ( io_nasti_w.valid    ),
      .io_nasti_lite_w_ready         ( io_nasti_w.ready    ),
      .io_nasti_lite_w_bits_data     ( io_nasti_w.data     ),
      .io_nasti_lite_w_bits_strb     ( io_nasti_w.strb     ),
      .io_nasti_lite_w_bits_user     ( io_nasti_w.user     ),

      .io_nasti_lite_b_valid         ( io_nasti_b.valid    ),
      .io_nasti_lite_b_ready         ( io_nasti_b.ready    ),
      .io_nasti_lite_b_bits_id       ( io_nasti_b.id       ),
      .io_nasti_lite_b_bits_resp     ( io_nasti_b.resp     ),
      .io_nasti_lite_b_bits_user     ( io_nasti_b.user     ),

      .io_nasti_lite_ar_valid        ( io_nasti_ar.valid   ),
      .io_nasti_lite_ar_ready        ( io_nasti_ar.ready   ),
      .io_nasti_lite_ar_bits_id      ( io_nasti_ar.id      ),
      .io_nasti_lite_ar_bits_addr    ( io_nasti_ar.addr    ),
      .io_nasti_lite_ar_bits_prot    ( io_nasti_ar.prot    ),
      .io_nasti_lite_ar_bits_qos     ( io_nasti_ar.qos     ),
      .io_nasti_lite_ar_bits_region  ( io_nasti_ar.region  ),
      .io_nasti_lite_ar_bits_user    ( io_nasti_ar.user    ),

      .io_nasti_lite_r_valid         ( io_nasti_r.valid    ),
      .io_nasti_lite_r_ready         ( io_nasti_r.ready    ),
      .io_nasti_lite_r_bits_id       ( io_nasti_r.id       ),
      .io_nasti_lite_r_bits_data     ( io_nasti_r.data     ),
      .io_nasti_lite_r_bits_resp     ( io_nasti_r.resp     ),
      .io_nasti_lite_r_bits_user     ( io_nasti_r.user     )
      );

   // the memory contoller
`ifdef FPGA
   
   localparam MEM_DATA_WIDTH = 128;
   localparam MEM_ADDR_WIDTH = 14;     // 16K
   localparam MEM_LINE = 2 ** MEM_ADDR_WIDTH / MEM_DATA_WIDTH * 8;
   localparam MEM_LINE_OFFSET = $clog2(MEM_DATA_WIDTH/8);
   
   logic ram_clk, ram_rst, ram_en;
   logic [MEM_DATA_WIDTH/8-1:0] ram_we;
   logic [MEM_ADDR_WIDTH-1:0] ram_addr;
   logic [MEM_DATA_WIDTH-1:0] ram_wrdata, ram_rddata;

   axi_bram_ctrl_top #(.ADDR_WIDTH(MEM_ADDR_WIDTH), .DATA_WIDTH(MEM_DATA_WIDTH)) 
   BramCtl (
            .*,
            .aw    ( mem_nasti_aw ),
            .w     ( mem_nasti_w  ),
            .b     ( mem_nasti_b  ),
            .ar    ( mem_nasti_ar ),
            .r     ( mem_nasti_r  )
           );

   // the inferred BRAMs
   reg [MEM_DATA_WIDTH-1:0] ram [0 : MEM_LINE-1];
   reg [MEM_ADDR_WIDTH-1:MEM_LINE_OFFSET] ram_addr_dly;
   
   always_ff @(posedge ram_clk)
     if(ram_en) begin
        ram_addr_dly <= ram_addr[MEM_ADDR_WIDTH-1:MEM_LINE_OFFSET];
        foreach (ram_we[i])
          if(ram_we[i]) ram[ram_addr[MEM_ADDR_WIDTH-1:MEM_LINE_OFFSET]][i*8 +:8] <= ram_wrdata[i*8 +: 8];
     end

   assign ram_rddata = ram[ram_addr_dly];

   initial $readmemh("boot.mem", ram);
   
 `ifdef USE_XIL_UART
   // Xilinx UART IP
   axi_uart16550_0 uart_i
     (
      .s_axi_aclk      ( clk                ),
      .s_axi_aresetn   ( rstn               ),
      .s_axi_araddr    ( io_nasti_ar.addr   ),
      .s_axi_arready   ( io_nasti_ar.ready  ),
      .s_axi_arvalid   ( io_nasti_ar.valid  ),
      .s_axi_awaddr    ( io_nasti_aw.addr   ),
      .s_axi_awready   ( io_nasti_aw.ready  ),
      .s_axi_awvalid   ( io_nasti_aw.valid  ),
      .s_axi_bready    ( io_nasti_b.ready   ),
      .s_axi_bresp     ( io_nasti_b.resp    ),
      .s_axi_bvalid    ( io_nasti_b.valid   ),
      .s_axi_rdata     ( io_nasti_r.data    ),
      .s_axi_rready    ( io_nasti_r.ready   ),
      .s_axi_rresp     ( io_nasti_r.resp    ),
      .s_axi_rvalid    ( io_nasti_r.valid   ),
      .s_axi_wdata     ( io_nasti_w.data    ),
      .s_axi_wready    ( io_nasti_w.ready   ),
      .s_axi_wstrb     ( io_nasti_w.strb    ),
      .s_axi_wvalid    ( io_nasti_w.valid   ),
      .freeze          ( 1'b0               ),
      .rin             ( 1'b1               ),
      .dcdn            ( 1'b1               ),
      .dsrn            ( 1'b1               ),
      .sin             ( rxd                ),
      .sout            ( txd                ),
      .ctsn            ( 1'b1               ),
      .rtsn            (                    )
      );

 `else // !`ifdef USE_XIL_UART

   NASTILiteUART
     #(
       .NASTI_ADDR_WIDTH = 8,
       .NASTI_DATA_WIDTH = 8,
       .ClockFreq =	100000000,
	   .Baud = 115200,
	   .Parity = 0,
	   .StopBits = 1
       )
   uart_i (
           .clk        ( clk          ),
           .rstn       ( rstn         ),
           .nasti_aw   ( io_nasti_aw  ),
           .nasti_w    ( io_nasti_w   ),
           .nasti_b    ( io_nasti_b   ),
           .nasti_ar   ( io_nasti_ar  ),
           .nasti_r    ( io_nasti_r   ),
           .rxd        ( rxd          ),
           .txd        ( txd          )
           );
   
 `endif //  `ifdef USE_XIL_UART
`endif //  `ifdef FPGA

endmodule // chip_top
