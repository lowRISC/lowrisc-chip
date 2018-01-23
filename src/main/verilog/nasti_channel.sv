// See LICENSE for license details.

// Define the SV interfaces for NASTI channels

interface nasti_channel
  #(
    N_PORT = 1,                 // number of nasti ports
    ID_WIDTH = 1,               // id width
    ADDR_WIDTH = 8,             // address width
    DATA_WIDTH = 8,             // width of data
    USER_WIDTH = 1              // width of user field, must > 0, let synthesizer trim it if not in use
    );

   initial assert(USER_WIDTH > 0) else $fatal(1, "[nasti interface] User field must have at least 1 bit!");

   // write/read address
   logic [N_PORT-1:0][ID_WIDTH-1:0]     aw_id,     ar_id;
   logic [N_PORT-1:0][ADDR_WIDTH-1:0]   aw_addr,   ar_addr;
   logic [N_PORT-1:0][7:0]              aw_len,    ar_len;
   logic [N_PORT-1:0][2:0]              aw_size,   ar_size;
   logic [N_PORT-1:0][1:0]              aw_burst,  ar_burst;
   logic [N_PORT-1:0]                   aw_lock,   ar_lock;
   logic [N_PORT-1:0][3:0]              aw_cache,  ar_cache;
   logic [N_PORT-1:0][2:0]              aw_prot,   ar_prot;
   logic [N_PORT-1:0][3:0]              aw_qos,    ar_qos;
   logic [N_PORT-1:0][3:0]              aw_region, ar_region;
   logic [N_PORT-1:0][USER_WIDTH-1:0]   aw_user,   ar_user;
   logic [N_PORT-1:0]                   aw_valid,  ar_valid;
   logic [N_PORT-1:0]                   aw_ready,  ar_ready;

   // write/read data
   logic [N_PORT-1:0][DATA_WIDTH-1:0]   w_data,    r_data;
   logic [N_PORT-1:0][DATA_WIDTH/8-1:0] w_strb;
   logic [N_PORT-1:0]                   w_last,    r_last;
   logic [N_PORT-1:0][USER_WIDTH-1:0]   w_user;
   logic [N_PORT-1:0]                   w_valid;
   logic [N_PORT-1:0]                   w_ready;

   // write/read response
   logic [N_PORT-1:0][ID_WIDTH-1:0]     b_id,      r_id;
   logic [N_PORT-1:0][1:0]              b_resp,    r_resp;
   logic [N_PORT-1:0][USER_WIDTH-1:0]   b_user,    r_user;
   logic [N_PORT-1:0]                   b_valid,   r_valid;
   logic [N_PORT-1:0]                   b_ready,   r_ready;


   modport master (
                   // write/read address
                   output aw_id,     ar_id,
                   output aw_addr,   ar_addr,
                   output aw_len,    ar_len,
                   output aw_size,   ar_size,
                   output aw_burst,  ar_burst,
                   output aw_lock,   ar_lock,
                   output aw_cache,  ar_cache,
                   output aw_prot,   ar_prot,
                   output aw_qos,    ar_qos,
                   output aw_region, ar_region,
                   output aw_user,   ar_user,
                   output aw_valid,  ar_valid,
                   input  aw_ready,  ar_ready,
                   // write data
                   output w_data,
                   output w_strb,
                   output w_last,
                   output w_user,
                   output w_valid,
                   input  w_ready,
                   // read data
                   input  r_data,
                   input  r_last,
                   // write/read response
                   input  b_id,    r_id,
                   input  b_resp,  r_resp,
                   input  b_user,  r_user,
                   input  b_valid, r_valid,
                   output b_ready, r_ready
                   );

   modport slave (
                  // write/read address
                  input  aw_id,     ar_id,
                  input  aw_addr,   ar_addr,
                  input  aw_len,    ar_len,
                  input  aw_size,   ar_size,
                  input  aw_burst,  ar_burst,
                  input  aw_lock,   ar_lock,
                  input  aw_cache,  ar_cache,
                  input  aw_prot,   ar_prot,
                  input  aw_qos,    ar_qos,
                  input  aw_region, ar_region,
                  input  aw_user,   ar_user,
                  input  aw_valid,  ar_valid,
                  output aw_ready,  ar_ready,
                   // write data
                  input  w_data,
                  input  w_strb,
                  input  w_last,
                  input  w_user,
                  input  w_valid,
                  output w_ready,
                   // read data
                  output r_data,
                  output r_last,
                   // write/read response
                  output b_id,    r_id,
                  output b_resp,  r_resp,
                  output b_user,  r_user,
                  output b_valid, r_valid,
                  input  b_ready, r_ready
                   );

endinterface // nasti_channel



