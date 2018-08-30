// See LICENSE for license details.

module nasti_ram_sim
  #(
    ID_WIDTH = 8,
    ADDR_WIDTH = 16,
    DATA_WIDTH = 128,
    USER_WIDTH = 1
    )
   (
    input clk, rstn,
    nasti_channel.slave nasti
    );

  parameter base = 32'h80200000;

  integer i, fd, first, last;

  reg [7:0] mem[32'h0:32'h1000000];

  // Read input arguments and initialize
   
   function bit memory_load_mem (input string filename);

     begin
     end

   endfunction // memory_load_mem

  SimAXIMem SimAXIMem (
    .clock(clk),
    .reset(~rstn),
    .io_axi4_0_ar_ready(nasti.ar_ready),
    .io_axi4_0_ar_valid(nasti.ar_valid),
    .io_axi4_0_ar_bits_id(nasti.ar_id),
    .io_axi4_0_ar_bits_addr(nasti.ar_addr),
    .io_axi4_0_ar_bits_len(nasti.ar_len),
    .io_axi4_0_ar_bits_size(nasti.ar_size),
    .io_axi4_0_ar_bits_burst(nasti.ar_burst),
    .io_axi4_0_r_ready(nasti.r_ready),
    .io_axi4_0_r_valid(nasti.r_valid),
    .io_axi4_0_r_bits_id(nasti.r_id),
    .io_axi4_0_r_bits_data(nasti.r_data),
    .io_axi4_0_r_bits_resp(nasti.r_resp),
    .io_axi4_0_r_bits_last(nasti.r_last),
    .io_axi4_0_aw_ready(nasti.aw_ready),
    .io_axi4_0_aw_valid(nasti.aw_valid),
    .io_axi4_0_aw_bits_id(nasti.aw_id),
    .io_axi4_0_aw_bits_addr(nasti.aw_addr),
    .io_axi4_0_aw_bits_len(nasti.aw_len),
    .io_axi4_0_aw_bits_size(nasti.aw_size),
    .io_axi4_0_aw_bits_burst(nasti.aw_burst),
    .io_axi4_0_w_ready(nasti.w_ready),
    .io_axi4_0_w_valid(nasti.w_valid),
    .io_axi4_0_w_bits_data(nasti.w_data),
    .io_axi4_0_w_bits_strb(nasti.w_strb),
    .io_axi4_0_w_bits_last(nasti.w_last),
    .io_axi4_0_b_ready(nasti.b_ready),
    .io_axi4_0_b_valid(nasti.b_valid),
    .io_axi4_0_b_bits_id(nasti.b_id),
    .io_axi4_0_b_bits_resp(nasti.b_resp)
  );

/*
 not used   
      .s_axi_arlock    ( nasti.ar_lock  ),
      .s_axi_arcache   ( nasti.ar_cache ),
      .s_axi_arprot    ( nasti.ar_prot  ),

      .s_axi_awlock    ( nasti.aw_lock  ),
      .s_axi_awcache   ( nasti.aw_cache ),
      .s_axi_awprot    ( nasti.aw_prot  ),
      .s_axi_awready   ( nasti.aw_ready ),
*/
   
endmodule // nasti_ram_behav
