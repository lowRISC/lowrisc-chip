module PHY_CONTROL (
  AUXOUTPUT,
  INBURSTPENDING,
  INRANKA,
  INRANKB,
  INRANKC,
  INRANKD,
  OUTBURSTPENDING,
  PCENABLECALIB,
  PHYCTLALMOSTFULL,
  PHYCTLEMPTY,
  PHYCTLFULL,
  PHYCTLREADY,

  MEMREFCLK,
  PHYCLK,
  PHYCTLMSTREMPTY,
  PHYCTLWD,
  PHYCTLWRENABLE,
  PLLLOCK,
  READCALIBENABLE,
  REFDLLLOCK,
  RESET,
  SYNCIN,
  WRITECALIBENABLE
);
  output PHYCTLALMOSTFULL;
  output PHYCTLEMPTY;
  output PHYCTLFULL;
  output PHYCTLREADY;
  output [1:0] INRANKA;
  output [1:0] INRANKB;
  output [1:0] INRANKC;
  output [1:0] INRANKD;
  output [1:0] PCENABLECALIB;
  output [3:0] AUXOUTPUT;
  output [3:0] INBURSTPENDING;
  output [3:0] OUTBURSTPENDING;

  input MEMREFCLK;
  input PHYCLK;
  input PHYCTLMSTREMPTY;
  input PHYCTLWRENABLE;
  input PLLLOCK;
  input READCALIBENABLE;
  input REFDLLLOCK;
  input RESET;
  input SYNCIN;
  input WRITECALIBENABLE;
  input [31:0] PHYCTLWD;
endmodule // PHY_CONTROL

module IN_FIFO (
  ALMOSTEMPTY,
  ALMOSTFULL,
  EMPTY,
  FULL,
  Q0,
  Q1,
  Q2,
  Q3,
  Q4,
  Q5,
  Q6,
  Q7,
  Q8,
  Q9,

  D0,
  D1,
  D2,
  D3,
  D4,
  D5,
  D6,
  D7,
  D8,
  D9,
  RDCLK,
  RDEN,
  RESET,
  WRCLK,
  WREN
);

  output ALMOSTEMPTY;
  output ALMOSTFULL;
  output EMPTY;
  output FULL;
  output [7:0] Q0;
  output [7:0] Q1;
  output [7:0] Q2;
  output [7:0] Q3;
  output [7:0] Q4;
  output [7:0] Q5;
  output [7:0] Q6;
  output [7:0] Q7;
  output [7:0] Q8;
  output [7:0] Q9;

  input RDCLK;
  input RDEN;
  input RESET;
  input WRCLK;
  input WREN;
  input [3:0] D0;
  input [3:0] D1;
  input [3:0] D2;
  input [3:0] D3;
  input [3:0] D4;
  input [3:0] D7;
  input [3:0] D8;
  input [3:0] D9;
  input [7:0] D5;
  input [7:0] D6;

endmodule // IN_FIFO
module ISERDESE2 (
  O,
  Q1,
  Q2,
  Q3,
  Q4,
  Q5,
  Q6,
  Q7,
  Q8,
  SHIFTOUT1,
  SHIFTOUT2,

  BITSLIP,
  CE1,
  CE2,
  CLK,
  CLKB,
  CLKDIV,
  CLKDIVP,
  D,
  DDLY,
  DYNCLKDIVSEL,
  DYNCLKSEL,
  OCLK,
  OCLKB,
  OFB,
  RST,
  SHIFTIN1,
  SHIFTIN2
);

     output O;
  output Q1;
  output Q2;
  output Q3;
  output Q4;
  output Q5;
  output Q6;
  output Q7;
  output Q8;
  output SHIFTOUT1;
  output SHIFTOUT2;

  input BITSLIP;
  input CE1;
  input CE2;
  input CLK;
  input CLKB;
  input CLKDIV;
  input CLKDIVP;
  input D;
  input DDLY;
  input DYNCLKDIVSEL;
  input DYNCLKSEL;
  input OCLK;
  input OCLKB;
  input OFB;
  input RST;
  input SHIFTIN1;
  input SHIFTIN2;

endmodule // ISERDESE2

module OSERDESE2 (
  OFB,
  OQ,
  SHIFTOUT1,
  SHIFTOUT2,
  TBYTEOUT,
  TFB,
  TQ,

  CLK,
  CLKDIV,
  D1,
  D2,
  D3,
  D4,
  D5,
  D6,
  D7,
  D8,
  OCE,
  RST,
  SHIFTIN1,
  SHIFTIN2,
  T1,
  T2,
  T3,
  T4,
  TBYTEIN,
  TCE
);
  output OFB;
  output OQ;
  output SHIFTOUT1;
  output SHIFTOUT2;
  output TBYTEOUT;
  output TFB;
  output TQ;

  input CLK;
  input CLKDIV;
  input D1;
  input D2;
  input D3;
  input D4;
  input D5;
  input D6;
  input D7;
  input D8;
  input OCE;
  input RST;
  input SHIFTIN1;
  input SHIFTIN2;
  input T1;
  input T2;
  input T3;
  input T4;
  input TBYTEIN;
  input TCE;

endmodule // OSERDESE2

module OUT_FIFO (
  ALMOSTEMPTY,
  ALMOSTFULL,
  EMPTY,
  FULL,
  Q0,
  Q1,
  Q2,
  Q3,
  Q4,
  Q5,
  Q6,
  Q7,
  Q8,
  Q9,

  D0,
  D1,
  D2,
  D3,
  D4,
  D5,
  D6,
  D7,
  D8,
  D9,
  RDCLK,
  RDEN,
  RESET,
  WRCLK,
  WREN
);

  output ALMOSTEMPTY;
  output ALMOSTFULL;
  output EMPTY;
  output FULL;
  output [3:0] Q0;
  output [3:0] Q1;
  output [3:0] Q2;
  output [3:0] Q3;
  output [3:0] Q4;
  output [3:0] Q7;
  output [3:0] Q8;
  output [3:0] Q9;
  output [7:0] Q5;
  output [7:0] Q6;

  input RDCLK;
  input RDEN;
  input RESET;
  input WRCLK;
  input WREN;
  input [7:0] D0;
  input [7:0] D1;
  input [7:0] D2;
  input [7:0] D3;
  input [7:0] D4;
  input [7:0] D5;
  input [7:0] D6;
  input [7:0] D7;
  input [7:0] D8;
  input [7:0] D9;

endmodule // OUT_FIFO

module PHASER_IN_PHY
(
  output [5:0] COUNTERREADVAL,
  output DQSFOUND,
  output DQSOUTOFRANGE,
  output FINEOVERFLOW,
  output ICLK,
  output ICLKDIV,
  output ISERDESRST,
  output PHASELOCKED,
  output RCLK,
  output WRENABLE,

  input BURSTPENDINGPHY,
  input COUNTERLOADEN,
  input [5:0] COUNTERLOADVAL,
  input COUNTERREADEN,
  input [1:0] ENCALIBPHY,
  input FINEENABLE,
  input FINEINC,
  input FREQREFCLK,
  input MEMREFCLK,
  input PHASEREFCLK,
  input [1:0] RANKSELPHY,
  input RST,
  input RSTDQSFIND,
  input SYNCIN,
  input SYSCLK
);

endmodule // PHASER_IN_PHY

module PHASER_OUT_PHY (
  COARSEOVERFLOW,
  COUNTERREADVAL,
  CTSBUS,
  DQSBUS,
  DTSBUS,
  FINEOVERFLOW,
  OCLK,
  OCLKDELAYED,
  OCLKDIV,
  OSERDESRST,
  RDENABLE,

  BURSTPENDINGPHY,
  COARSEENABLE,
  COARSEINC,
  COUNTERLOADEN,
  COUNTERLOADVAL,
  COUNTERREADEN,
  ENCALIBPHY,
  FINEENABLE,
  FINEINC,
  FREQREFCLK,
  MEMREFCLK,
  PHASEREFCLK,
  RST,
  SELFINEOCLKDELAY,
  SYNCIN,
  SYSCLK
);

 output COARSEOVERFLOW;
  output FINEOVERFLOW;
  output OCLK;
  output OCLKDELAYED;
  output OCLKDIV;
  output OSERDESRST;
  output RDENABLE;
  output [1:0] CTSBUS;
  output [1:0] DQSBUS;
  output [1:0] DTSBUS;
  output [8:0] COUNTERREADVAL;

  input BURSTPENDINGPHY;
  input COARSEENABLE;
  input COARSEINC;
  input COUNTERLOADEN;
  input COUNTERREADEN;
  input FINEENABLE;
  input FINEINC;
  input FREQREFCLK;
  input MEMREFCLK;
  input PHASEREFCLK;
  input RST;
  input SELFINEOCLKDELAY;
  input SYNCIN;
  input SYSCLK;
  input [1:0] ENCALIBPHY;
  input [8:0] COUNTERLOADVAL;

endmodule // PHASER_OUT_PHY
