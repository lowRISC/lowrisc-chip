`define CMD_RDID 8'h9F
`define CMD_MIORDID 8'hAF
`define CMD_RDSR 8'h05
`define CMD_RFSR 8'h70
`define CMD_RDVECR 8'h65
`define CMD_WRVECR 8'h61
`define CMD_WREN 8'h06
`define CMD_SE 8'hD8
`define CMD_BE 8'hC7
`define CMD_PP 8'h02
`define CMD_QCFR 8'h0B

`define JEDEC_ID 8'h20

`define tPPmax 'd5 //ms
`define tBEmax 'd250_000 //ms
`define tSEmax 'd3_000 //ms
`define input_freq 'd31_250 //kHz
