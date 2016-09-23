import dii_package::dii_flit;

`include "consts.vh"

module debug_system
  #(parameter N_CORES        = 1,
    parameter MAM_DATA_WIDTH = 16,
    parameter MAM_REGIONS    = 2,
    parameter MAM_BASE_ADDR0 = 0,
    parameter MAM_MEM_SIZE0  = 'h10000,
    parameter MAM_BASE_ADDR1 = 'h40000000,
    parameter MAM_MEM_SIZE1  = 'h8000000,
    parameter MAM_ADDR_WIDTH = 64,
    parameter FREQ_CLK_IO    = 'x,
    parameter UART_BAUD      = 'x)
  (
   input                        clk, rstn,
   input                        clk_io,

   input                        rx,
   output                       tx,
   input                        cts,
   output                       rts,

   output                       uart_irq,

   input [12:0]                 uart_ar_addr,
   input                        uart_ar_valid,
   output                       uart_ar_ready,

   output [1:0]                 uart_r_resp,
   output [31:0]                uart_r_data,
   output                       uart_r_valid,
   input                        uart_r_ready,

   input [12:0]                 uart_aw_addr,
   input                        uart_aw_valid,
   output                       uart_aw_ready,

   input [31:0]                 uart_w_data,
   input                        uart_w_valid,
   output                       uart_w_ready,

   output [1:0]                 uart_b_resp,
   output                       uart_b_valid,
   input                        uart_b_ready,

   output                       sys_rst, cpu_rst,

   input  dii_flit [1:0]        ring_in,
   output [1:0]                 ring_in_ready,
   output dii_flit [1:0]        ring_out,
   input [1:0]                  ring_out_ready,

   output                       req_valid,
   input                        req_ready,
   output                       req_rw,
   output [MAM_ADDR_WIDTH-1:0]  req_addr,
   output                       req_burst,
   output [13:0]                req_beats,

   output                       write_valid,
   input                        write_ready,
   output [MAM_DATA_WIDTH-1:0]  write_data,
   logic [MAM_DATA_WIDTH/8-1:0] write_strb,

   input                        read_valid,
   input [MAM_DATA_WIDTH-1:0]   read_data,
   output                       read_ready
   );

   localparam MAX_PKT_LEN = 16;

   initial assert (MAM_DATA_WIDTH == 16) else $fatal(1, "MAM_DATA_WIDTH must be 16!");

   logic  rst;
   assign rst = ~rstn;

   glip_channel #(.WIDTH(16)) fifo_in (.*);
   glip_channel #(.WIDTH(16)) fifo_out (.*);

   logic  logic_rst, com_rst;

`ifdef FPGA_FULL
   logic [15:0]  fifo_out_data;
   logic         fifo_out_valid;
   logic         fifo_out_ready;
   logic  [15:0] fifo_in_data;
   logic         fifo_in_valid;
   logic         fifo_in_ready;

   assign fifo_in.data = fifo_in_data;
   assign fifo_in.valid = fifo_in_valid;
   assign fifo_in_ready = fifo_in.ready;
   assign fifo_out_data = fifo_out.data;
   assign fifo_out_valid = fifo_out.valid;
   assign fifo_out.ready = fifo_out_ready;

   glip_uart_toplevel
     #(.WIDTH(16), .BAUD(UART_BAUD), .FREQ_CLK_IO(FREQ_CLK_IO))
   u_glip(.clk_io    (clk_io),
          .clk       (clk),
          .rst       (rst),
          .ctrl_logic_rst (logic_rst),
          .com_rst   (com_rst),
          .fifo_in_data  (fifo_in_data[15:0]),
          .fifo_in_valid (fifo_in_valid),
          .fifo_in_ready (fifo_in_ready),
          .fifo_out_data  (fifo_out_data[15:0]),
          .fifo_out_valid (fifo_out_valid),
          .fifo_out_ready (fifo_out_ready),
          .uart_rx (rx),
          .uart_tx (tx),
          .uart_cts_n (cts),
          .uart_rts_n (rts),
          .error ());
`else // !`ifdef FPGA

   glip_tcp_toplevel
     #(.WIDTH(16))
   u_glip(.clk_io    (clk),
          .clk_logic (clk),
          .rst       (rst),
          .logic_rst (logic_rst),
          .com_rst   (com_rst),
          .fifo_in   (fifo_in),
          .fifo_out  (fifo_out));
`endif

   parameter PERCORE = 2;
   localparam N_OSD = 4;
   localparam N = N_CORES*PERCORE+N_OSD;

   logic [N_OSD-1:0][9:0] id_map;
   assign id_map[0] = 0;        // HIM
   assign id_map[1] = 1;        // SCM
   assign id_map[2] = 2;        // UART
   assign id_map[3] = 3;        // MAM

   dii_flit [N_OSD-1:0] dii_out; logic [N_OSD-1:0] dii_out_ready;
   dii_flit [N_OSD-1:0] dii_in; logic [N_OSD-1:0] dii_in_ready;

   osd_him
     #(.MAX_PKT_LEN(MAX_PKT_LEN))
     u_him(.*,
           .glip_in  (fifo_in),
           .glip_out (fifo_out),
           .dii_out        ( dii_out[0]        ),
           .dii_out_ready  ( dii_out_ready[0]  ),
           .dii_in         ( dii_in[0]         ),
           .dii_in_ready   ( dii_in_ready[0]   )
           );

   osd_scm
     #(.SYSTEMID(16'hdead), .NUM_MOD(N-1),
       .MAX_PKT_LEN(MAX_PKT_LEN))
   u_scm(.*,
         .id              ( id_map[1]        ),
         .debug_in        ( dii_in[1]        ),
         .debug_in_ready  ( dii_in_ready[1]  ),
         .debug_out       ( dii_out[1]       ),
         .debug_out_ready ( dii_out_ready[1] )
         );

   assign uart_r_data[31:8] = 0;

   osd_dem_uart_nasti
     u_uart (.*,
             .id ( id_map[2] ),
             .irq (uart_irq),
             .ar_addr (uart_ar_addr[4:2]),
             .ar_valid (uart_ar_valid),
             .ar_ready (uart_ar_ready),
             .r_data (uart_r_data[7:0]),
             .r_valid (uart_r_valid),
             .r_ready (uart_r_ready),
             .r_resp (uart_r_resp),
             .aw_addr (uart_aw_addr[4:2]),
             .aw_valid (uart_aw_valid),
             .aw_ready (uart_aw_ready),
             .w_data (uart_w_data),
             .w_valid (uart_w_valid),
             .w_ready (uart_w_ready),
             .b_valid (uart_b_valid),
             .b_ready (uart_b_ready),
             .b_resp (uart_b_resp),

             .debug_in        ( dii_in[2]        ),
             .debug_in_ready  ( dii_in_ready[2]  ),
             .debug_out       ( dii_out[2]       ),
             .debug_out_ready ( dii_out_ready[2] )
             );

   osd_mam
     #(.DATA_WIDTH(MAM_DATA_WIDTH), .REGIONS(MAM_REGIONS),
       .BASE_ADDR0(MAM_BASE_ADDR0), .MEM_SIZE0(MAM_MEM_SIZE0),
       .BASE_ADDR1(MAM_BASE_ADDR1), .MEM_SIZE1(MAM_MEM_SIZE1),
       .ADDR_WIDTH(MAM_ADDR_WIDTH), .MAX_PKT_LEN(MAX_PKT_LEN),
       .ENDIAN(0))
   u_mam (.*,
          .id              ( id_map[3]        ),
          .debug_in        ( dii_in[3]        ),
          .debug_in_ready  ( dii_in_ready[3]  ),
          .debug_out       ( dii_out[3]       ),
          .debug_out_ready ( dii_out_ready[3] ),
          .read_data       ( read_data        ),
          .write_data      ( write_data       )
          );

   dii_flit [1:0] ext_in;  logic [1:0] ext_in_ready;
   dii_flit [1:0] ext_out; logic [1:0] ext_out_ready;

   debug_ring_expand
     #(.PORTS(N_OSD))
   u_ring(.*,
          .dii_in        ( dii_out        ),
          .dii_in_ready  ( dii_out_ready  ),
          .dii_out       ( dii_in         ),
          .dii_out_ready ( dii_in_ready   ),
          .ext_in        ( ext_in         ),
          .ext_in_ready  ( ext_in_ready   ),
          .ext_out       ( ext_out        ),
          .ext_out_ready ( ext_out_ready  )
          );

   assign ext_in[0].valid = 1'b0;
   assign ext_in[1] = ring_in[0];
   assign ring_in_ready[0] = ext_in_ready[1];
   assign ring_out = ext_out;
   assign ext_out_ready = ring_out_ready;
   assign ring_in_ready[1] = 1'b1;

endmodule // debug_system
