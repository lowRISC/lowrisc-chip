// See LICENSE for license details.
`default_nettype none

module lowrisc_hwrng
  (
   // clock and reset
   input wire clk_i,
   input wire rst_ni,   
   input wire rdfifo,
   output wire [11:0] rdcount, wrcount,
   output wire [31:0] fifo_out,
   output wire full, empty, rderr, wrerr
   );
 
localparam wid = 8;

integer j;
(* dont_touch = "true" *) logic [wid-1:0] x0, x1;
logic [wid-1:0] x2, x3;
(* dont_touch = "true" *) logic [wid:1] d, raddr, dly;
(* dont_touch = "false" *) reg [31:0] x4;
reg write, rd_en0, rd_en;

(* dont_touch = "true" *) wire x1inv = x0[wid-1] ^ x0[0] ^ x0[1];

BUFG ringbuf (.O(x1[0]), .I(rst_ni && ~x1inv));

for (genvar g = 1; g < wid-1; g=g+1)
    begin:gx1
        assign x1[g] = x0[g-1] ^ x0[g] ^ x0[g+1];
    end

assign x1[wid-1] = x0[wid-2] ^ x0[wid-1] ^ x0[0];

for (genvar g = 0; g < wid; g=g+1)
    begin:gio
    BUF bufx0_inst (
       .O(x0[g]), // 1-bit wire: Clock wire
       .I(x1[g])  // 1-bit reg: Clock reg
    );
     end

always @(posedge clk_i)
    begin
        x2 <= x1;
        x3[0] <= x2[0] ^ d[1] ^ x3[1];
        for (j = 1; j < wid-1; j=j+1)
            x3[j] <= x3[j-1] ^ x2[j] ^ d[j+1] ^ x3[j+1];
        x3[wid-1] <= x3[wid-2] ^ x2[wid-1] ^ d[wid];
        raddr <= raddr + 'b1;
        if (raddr == x3)
          begin
             dly <= dly + 'b1;
             x4 <= {x4[23:0],x3};
             write <= (dly == x3) && rst_ni && !full;
          end
        else
          write <= 0;
        rd_en0 <= rdfifo;
        rd_en <= rdfifo && ~rd_en0;
    end
    
for (genvar g = 1; g <= wid; g=g+1)
    begin:gbufh
    BUF bufd_inst (
       .O(d[g]), // 1-bit wire: Clock wire
       .I(x3[g-1])  // 1-bit reg: Clock reg
    );
    end

     FIFO18E1 #(
                .ALMOST_EMPTY_OFFSET(13'h0080),    // Sets the almost empty threshold
                .ALMOST_FULL_OFFSET(13'h0080),     // Sets almost full threshold
                .DATA_WIDTH(36),                   // Sets data width to 4-36
                .DO_REG(1),                        // Enable output register (1-0) Must be 1 if EN_SYN = FALSE
                .EN_SYN("FALSE"),                  // Specifies FIFO as dual-clock (FALSE) or Synchronous (TRUE)
                .FIFO_MODE("FIFO18_36"),           // Sets mode to FIFO18 or FIFO18_36
                .FIRST_WORD_FALL_THROUGH("FALSE"), // Sets the FIFO FWFT to FALSE, TRUE
                .INIT(36'h000000000),              // Initial values on output port
                .SIM_DEVICE("7SERIES"),            // Must be set to "7SERIES" for simulation behavior
                .SRVAL(36'h000000000)              // Set/Reset value for output port
                )
      rand_fifo (
                        // Read Data: 32-bit (each) output: Read output data
                        .DO(fifo_out),             // 32-bit output: Data output
                        .DOP(),                    // 4-bit output: Parity data output
                        // Status: 1-bit (each) output: Flags and other FIFO status outputs
                        .ALMOSTEMPTY(),            // 1-bit output: Almost empty flag
                        .ALMOSTFULL(),             // 1-bit output: Almost full flag
                        .EMPTY(empty),             // 1-bit output: Empty flag
                        .FULL(full),               // 1-bit output: Full flag
                        .RDCOUNT(rdcount),         // 12-bit output: Read count
                        .RDERR(rderr),             // 1-bit output: Read error
                        .WRCOUNT(wrcount),         // 12-bit output: Write count
                        .WRERR(wrerr),             // 1-bit output: Write error
                        // Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
                        .RDCLK(clk_i),             // 1-bit input: Read clock
                        .RDEN(rd_en),              // 1-bit input: Read enable
                        .REGCE(1'b1),              // 1-bit input: Clock enable
                        .RST(~rst_ni),             // 1-bit input: Asynchronous Reset
                        // Write Control Signals: 1-bit (each) input: Write clock and enable input signals
                        .WRCLK(clk_i),             // 1-bit input: Write clock
                        .WREN(write),              // 1-bit input: Write enable
                        // Write Data: 32-bit (each) input: Write input data
                        .DI(x4),                   // 32-bit input: Data input
                        .DIP(4'b0)                 // 4-bit input: Parity input
                        );

`ifdef XLNX_ILA_RNG
xlnx_ila_rng rng_ila (
  .clk(clk_i), // input wire clk
  .probe0(rst_ni),
  .probe1(rdfifo),
  .probe2(rdcount),
  .probe3(wrcount),
  .probe4(fifo_out),
  .probe5(full),
  .probe6(empty),
  .probe7(rderr),
  .probe8(wrerr),
  .probe9(rd_en),
  .probe10(write),
  .probe11(x4),
  .probe12(raddr),
  .probe13(dly),
  .probe14(x3),
  .probe15(x2)  
  );
`endif   

endmodule // chip_top
`default_nettype wire
