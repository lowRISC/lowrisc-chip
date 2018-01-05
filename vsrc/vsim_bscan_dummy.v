///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995/2010 Xilinx, Inc.
// All Right Reserved.
///////////////////////////////////////////////////////////////////////////////
// This version is a simulation stub.

module BSCANE2 (
  output CAPTURE,
  output DRCK,
  output RESET,
  output RUNTEST,
  output SEL,
  output SHIFT,
  output TCK,
  output TDI,
  output TMS,
  output UPDATE,

  input TDO
);

  parameter DISABLE_JTAG = "FALSE";
  parameter integer JTAG_CHAIN = 1;

  pulldown (CAPTURE);
  pulldown (DRCK);
  pulldown (RESET);
  pulldown (RUNTEST);
  pulldown (SEL);
  pulldown (SHIFT);
  pulldown (TCK);
  pulldown (TDI);
  pulldown (TMS);
  pulldown (UPDATE);

endmodule
