module DebugTransportModuleJTAG(
  input         clock,
  input         reset,
  input         io_dmi_req_ready,
  output        io_dmi_req_valid,
  output [6:0]  io_dmi_req_bits_addr,
  output [31:0] io_dmi_req_bits_data,
  output [1:0]  io_dmi_req_bits_op,
  output        io_dmi_resp_ready,
  input         io_dmi_resp_valid,
  input  [31:0] io_dmi_resp_bits_data,
  input  [1:0]  io_dmi_resp_bits_resp,
  input         io_jtag_TMS,
  input         io_jtag_TDI,
  output        io_jtag_TDO_data,
  output        io_jtag_TDO_driven,
  input         io_jtag_reset,
  input  [10:0] io_jtag_mfr_id,
  output        io_fsmReset
);
  reg  busyReg;
  reg [31:0] _RAND_0;
  reg  stickyBusyReg;
  reg [31:0] _RAND_1;
  reg  stickyNonzeroRespReg;
  reg [31:0] _RAND_2;
  reg  skipOpReg;
  reg [31:0] _RAND_3;
  reg  downgradeOpReg;
  reg [31:0] _RAND_4;
  reg [6:0] dmiReqReg_addr;
  reg [31:0] _RAND_5;
  reg [31:0] dmiReqReg_data;
  reg [31:0] _RAND_6;
  reg [1:0] dmiReqReg_op;
  reg [31:0] _RAND_7;
  reg  dmiReqValidReg;
  reg [31:0] _RAND_8;
  wire  _T_47;
  wire [1:0] _T_48;
  wire  dtmInfoChain_clock;
  wire  dtmInfoChain_reset;
  wire  dtmInfoChain_io_chainIn_shift;
  wire  dtmInfoChain_io_chainIn_data;
  wire  dtmInfoChain_io_chainIn_capture;
  wire  dtmInfoChain_io_chainIn_update;
  wire  dtmInfoChain_io_chainOut_data;
  wire [14:0] dtmInfoChain_io_capture_bits_reserved1;
  wire  dtmInfoChain_io_capture_bits_dmireset;
  wire  dtmInfoChain_io_capture_bits_reserved0;
  wire [2:0] dtmInfoChain_io_capture_bits_dmiIdleCycles;
  wire [1:0] dtmInfoChain_io_capture_bits_dmiStatus;
  wire [5:0] dtmInfoChain_io_capture_bits_debugAddrBits;
  wire [3:0] dtmInfoChain_io_capture_bits_debugVersion;
  wire  dtmInfoChain_io_update_valid;
  wire  dtmInfoChain_io_update_bits_dmireset;
  wire  dmiAccessChain_clock;
  wire  dmiAccessChain_reset;
  wire  dmiAccessChain_io_chainIn_shift;
  wire  dmiAccessChain_io_chainIn_data;
  wire  dmiAccessChain_io_chainIn_capture;
  wire  dmiAccessChain_io_chainIn_update;
  wire  dmiAccessChain_io_chainOut_data;
  wire [6:0] dmiAccessChain_io_capture_bits_addr;
  wire [31:0] dmiAccessChain_io_capture_bits_data;
  wire [1:0] dmiAccessChain_io_capture_bits_resp;
  wire  dmiAccessChain_io_capture_capture;
  wire  dmiAccessChain_io_update_valid;
  wire [6:0] dmiAccessChain_io_update_bits_addr;
  wire [31:0] dmiAccessChain_io_update_bits_data;
  wire [1:0] dmiAccessChain_io_update_bits_op;
  wire  _GEN_0;
  wire  _T_59;
  wire  _GEN_1;
  wire  _T_62;
  wire  _T_63;
  wire  _T_64;
  wire  _GEN_2;
  wire  _GEN_3;
  wire  _T_68;
  wire  _T_69;
  wire  _GEN_4;
  wire  _GEN_5;
  wire  _GEN_6;
  wire  _GEN_7;
  wire  _GEN_8;
  wire  _GEN_9;
  wire  _GEN_10;
  wire  _GEN_11;
  wire  _T_73;
  wire  _T_74;
  wire  _T_75;
  wire  _T_77;
  wire  _T_78;
  wire  _T_80;
  wire  _T_82;
  wire  _T_83;
  wire  _T_85;
  wire [6:0] _T_96_addr;
  wire [31:0] _T_96_data;
  wire [1:0] _T_96_resp;
  wire [6:0] _T_97_addr;
  wire [31:0] _T_97_data;
  wire [1:0] _T_97_resp;
  wire  _GEN_12;
  wire  _GEN_13;
  wire  _GEN_14;
  wire  _GEN_15;
  wire  _GEN_16;
  wire  _GEN_17;
  wire  _T_105;
  wire  _T_106;
  wire  _T_108;
  wire  _T_109;
  wire  _T_111;
  wire  _T_113;
  wire  _T_114;
  wire  _T_116;
  wire  _T_117;
  wire [6:0] _GEN_18;
  wire [31:0] _GEN_19;
  wire [1:0] _GEN_20;
  wire  _T_124;
  wire  _T_125;
  wire [6:0] _GEN_21;
  wire [31:0] _GEN_22;
  wire [1:0] _GEN_23;
  wire  _GEN_24;
  wire [6:0] _GEN_26;
  wire [31:0] _GEN_27;
  wire [1:0] _GEN_28;
  wire  _GEN_29;
  wire  _GEN_30;
  wire  _GEN_31;
  wire  tapIO_jtag_TDO_data;
  wire  tapIO_jtag_TDO_driven;
  wire  tapIO_output_reset;
  wire  idcodeChain_clock;
  wire  idcodeChain_reset;
  wire  idcodeChain_io_chainIn_shift;
  wire  idcodeChain_io_chainIn_data;
  wire  idcodeChain_io_chainIn_capture;
  wire  idcodeChain_io_chainIn_update;
  wire  idcodeChain_io_chainOut_data;
  wire [3:0] idcodeChain_io_capture_bits_version;
  wire [15:0] idcodeChain_io_capture_bits_partNumber;
  wire [10:0] idcodeChain_io_capture_bits_mfrId;
  wire  idcodeChain_io_capture_bits_always1;
  wire [11:0] _T_174;
  wire [31:0] _T_176;
  wire [31:0] _GEN_25;
  wire [1:0] _T_178;
  wire  _T_180;
  wire  _T_181;
  wire  _T_183;
  wire [30:0] _T_184;
  wire [12:0] _T_188;
  wire [12:0] _T_189;
  wire [11:0] _T_190;
  wire [30:0] _GEN_72;
  wire [30:0] _T_191;
  wire  _T_193;
  wire  _T_194;
  wire  _T_196;
  wire  JtagTapController_clock;
  wire  JtagTapController_reset;
  wire  JtagTapController_io_jtag_TMS;
  wire  JtagTapController_io_jtag_TDI;
  wire  JtagTapController_io_jtag_TDO_data;
  wire  JtagTapController_io_jtag_TDO_driven;
  wire  JtagTapController_io_control_jtag_reset;
  wire [4:0] JtagTapController_io_output_instruction;
  wire  JtagTapController_io_output_reset;
  wire  JtagTapController_io_dataChainOut_shift;
  wire  JtagTapController_io_dataChainOut_data;
  wire  JtagTapController_io_dataChainOut_capture;
  wire  JtagTapController_io_dataChainOut_update;
  wire  JtagTapController_io_dataChainIn_data;
  wire  JtagBypassChain_clock;
  wire  JtagBypassChain_reset;
  wire  JtagBypassChain_io_chainIn_shift;
  wire  JtagBypassChain_io_chainIn_data;
  wire  JtagBypassChain_io_chainIn_capture;
  wire  JtagBypassChain_io_chainIn_update;
  wire  JtagBypassChain_io_chainOut_data;
  wire  _T_204;
  wire  _T_206;
  wire  _T_208;
  wire  _GEN_34;
  wire  _T_216;
  wire  _T_218;
  wire  _GEN_38;
  wire  _T_225;
  wire  _T_226;
  wire  _T_227;
  wire  _GEN_42;
  wire  _T_237;
  wire  _T_238;
  wire  _GEN_46;
  wire  _GEN_48;
  wire  _GEN_49;
  wire  _GEN_50;
  wire  _GEN_51;
  wire  _GEN_52;
  wire  _GEN_53;
  wire  _GEN_54;
  wire  _GEN_55;
  wire  _GEN_60;
  wire  _GEN_61;
  wire  _GEN_62;
  wire  _GEN_63;
  wire  _GEN_68;
  wire  _GEN_69;
  wire  _GEN_70;
  wire  _GEN_71;
  CaptureUpdateChain dtmInfoChain (
    .clock(dtmInfoChain_clock),
    .reset(dtmInfoChain_reset),
    .io_chainIn_shift(dtmInfoChain_io_chainIn_shift),
    .io_chainIn_data(dtmInfoChain_io_chainIn_data),
    .io_chainIn_capture(dtmInfoChain_io_chainIn_capture),
    .io_chainIn_update(dtmInfoChain_io_chainIn_update),
    .io_chainOut_data(dtmInfoChain_io_chainOut_data),
    .io_capture_bits_reserved1(dtmInfoChain_io_capture_bits_reserved1),
    .io_capture_bits_dmireset(dtmInfoChain_io_capture_bits_dmireset),
    .io_capture_bits_reserved0(dtmInfoChain_io_capture_bits_reserved0),
    .io_capture_bits_dmiIdleCycles(dtmInfoChain_io_capture_bits_dmiIdleCycles),
    .io_capture_bits_dmiStatus(dtmInfoChain_io_capture_bits_dmiStatus),
    .io_capture_bits_debugAddrBits(dtmInfoChain_io_capture_bits_debugAddrBits),
    .io_capture_bits_debugVersion(dtmInfoChain_io_capture_bits_debugVersion),
    .io_update_valid(dtmInfoChain_io_update_valid),
    .io_update_bits_dmireset(dtmInfoChain_io_update_bits_dmireset)
  );
  CaptureUpdateChain_1 dmiAccessChain (
    .clock(dmiAccessChain_clock),
    .reset(dmiAccessChain_reset),
    .io_chainIn_shift(dmiAccessChain_io_chainIn_shift),
    .io_chainIn_data(dmiAccessChain_io_chainIn_data),
    .io_chainIn_capture(dmiAccessChain_io_chainIn_capture),
    .io_chainIn_update(dmiAccessChain_io_chainIn_update),
    .io_chainOut_data(dmiAccessChain_io_chainOut_data),
    .io_capture_bits_addr(dmiAccessChain_io_capture_bits_addr),
    .io_capture_bits_data(dmiAccessChain_io_capture_bits_data),
    .io_capture_bits_resp(dmiAccessChain_io_capture_bits_resp),
    .io_capture_capture(dmiAccessChain_io_capture_capture),
    .io_update_valid(dmiAccessChain_io_update_valid),
    .io_update_bits_addr(dmiAccessChain_io_update_bits_addr),
    .io_update_bits_data(dmiAccessChain_io_update_bits_data),
    .io_update_bits_op(dmiAccessChain_io_update_bits_op)
  );
  CaptureChain idcodeChain (
    .clock(idcodeChain_clock),
    .reset(idcodeChain_reset),
    .io_chainIn_shift(idcodeChain_io_chainIn_shift),
    .io_chainIn_data(idcodeChain_io_chainIn_data),
    .io_chainIn_capture(idcodeChain_io_chainIn_capture),
    .io_chainIn_update(idcodeChain_io_chainIn_update),
    .io_chainOut_data(idcodeChain_io_chainOut_data),
    .io_capture_bits_version(idcodeChain_io_capture_bits_version),
    .io_capture_bits_partNumber(idcodeChain_io_capture_bits_partNumber),
    .io_capture_bits_mfrId(idcodeChain_io_capture_bits_mfrId),
    .io_capture_bits_always1(idcodeChain_io_capture_bits_always1)
  );
  JtagTapController JtagTapController (
    .clock(JtagTapController_clock),
    .reset(JtagTapController_reset),
    .io_jtag_TMS(JtagTapController_io_jtag_TMS),
    .io_jtag_TDI(JtagTapController_io_jtag_TDI),
    .io_jtag_TDO_data(JtagTapController_io_jtag_TDO_data),
    .io_jtag_TDO_driven(JtagTapController_io_jtag_TDO_driven),
    .io_control_jtag_reset(JtagTapController_io_control_jtag_reset),
    .io_output_instruction(JtagTapController_io_output_instruction),
    .io_output_reset(JtagTapController_io_output_reset),
    .io_dataChainOut_shift(JtagTapController_io_dataChainOut_shift),
    .io_dataChainOut_data(JtagTapController_io_dataChainOut_data),
    .io_dataChainOut_capture(JtagTapController_io_dataChainOut_capture),
    .io_dataChainOut_update(JtagTapController_io_dataChainOut_update),
    .io_dataChainIn_data(JtagTapController_io_dataChainIn_data)
  );
  JtagBypassChain JtagBypassChain (
    .clock(JtagBypassChain_clock),
    .reset(JtagBypassChain_reset),
    .io_chainIn_shift(JtagBypassChain_io_chainIn_shift),
    .io_chainIn_data(JtagBypassChain_io_chainIn_data),
    .io_chainIn_capture(JtagBypassChain_io_chainIn_capture),
    .io_chainIn_update(JtagBypassChain_io_chainIn_update),
    .io_chainOut_data(JtagBypassChain_io_chainOut_data)
  );
  assign io_dmi_req_valid = dmiReqValidReg;
  assign io_dmi_req_bits_addr = dmiReqReg_addr;
  assign io_dmi_req_bits_data = dmiReqReg_data;
  assign io_dmi_req_bits_op = dmiReqReg_op;
  assign io_dmi_resp_ready = dmiAccessChain_io_capture_capture;
  assign io_jtag_TDO_data = tapIO_jtag_TDO_data;
  assign io_jtag_TDO_driven = tapIO_jtag_TDO_driven;
  assign io_fsmReset = tapIO_output_reset;
  assign _T_47 = stickyNonzeroRespReg | stickyBusyReg;
  assign _T_48 = {stickyNonzeroRespReg,_T_47};
  assign dtmInfoChain_clock = clock;
  assign dtmInfoChain_reset = reset;
  assign dtmInfoChain_io_chainIn_shift = _GEN_71;
  assign dtmInfoChain_io_chainIn_data = _GEN_70;
  assign dtmInfoChain_io_chainIn_capture = _GEN_69;
  assign dtmInfoChain_io_chainIn_update = _GEN_68;
  assign dtmInfoChain_io_capture_bits_reserved1 = 15'h0;
  assign dtmInfoChain_io_capture_bits_dmireset = 1'h0;
  assign dtmInfoChain_io_capture_bits_reserved0 = 1'h0;
  assign dtmInfoChain_io_capture_bits_dmiIdleCycles = 3'h5;
  assign dtmInfoChain_io_capture_bits_dmiStatus = _T_48;
  assign dtmInfoChain_io_capture_bits_debugAddrBits = 6'h7;
  assign dtmInfoChain_io_capture_bits_debugVersion = 4'h1;
  assign dmiAccessChain_clock = clock;
  assign dmiAccessChain_reset = reset;
  assign dmiAccessChain_io_chainIn_shift = _GEN_63;
  assign dmiAccessChain_io_chainIn_data = _GEN_62;
  assign dmiAccessChain_io_chainIn_capture = _GEN_61;
  assign dmiAccessChain_io_chainIn_update = _GEN_60;
  assign dmiAccessChain_io_capture_bits_addr = _T_97_addr;
  assign dmiAccessChain_io_capture_bits_data = _T_97_data;
  assign dmiAccessChain_io_capture_bits_resp = _T_97_resp;
  assign _GEN_0 = io_dmi_req_valid ? 1'h1 : busyReg;
  assign _T_59 = io_dmi_resp_ready & io_dmi_resp_valid;
  assign _GEN_1 = _T_59 ? 1'h0 : _GEN_0;
  assign _T_62 = io_dmi_resp_valid == 1'h0;
  assign _T_63 = busyReg & _T_62;
  assign _T_64 = _T_63 | stickyBusyReg;
  assign _GEN_2 = dmiAccessChain_io_update_valid ? 1'h0 : skipOpReg;
  assign _GEN_3 = dmiAccessChain_io_update_valid ? 1'h0 : downgradeOpReg;
  assign _T_68 = _T_64 == 1'h0;
  assign _T_69 = _T_68 & _T_75;
  assign _GEN_4 = dmiAccessChain_io_capture_capture ? _T_64 : _GEN_2;
  assign _GEN_5 = dmiAccessChain_io_capture_capture ? _T_69 : _GEN_3;
  assign _GEN_6 = dmiAccessChain_io_capture_capture ? _T_64 : stickyBusyReg;
  assign _GEN_7 = dmiAccessChain_io_capture_capture ? _T_75 : stickyNonzeroRespReg;
  assign _GEN_8 = dtmInfoChain_io_update_bits_dmireset ? 1'h0 : _GEN_7;
  assign _GEN_9 = dtmInfoChain_io_update_bits_dmireset ? 1'h0 : _GEN_6;
  assign _GEN_10 = dtmInfoChain_io_update_valid ? _GEN_8 : _GEN_7;
  assign _GEN_11 = dtmInfoChain_io_update_valid ? _GEN_9 : _GEN_6;
  assign _T_73 = io_dmi_resp_bits_resp != 2'h0;
  assign _T_74 = io_dmi_resp_valid & _T_73;
  assign _T_75 = stickyNonzeroRespReg | _T_74;
  assign _T_77 = _T_75 == 1'h0;
  assign _T_78 = _T_77 | reset;
  assign _T_80 = _T_78 == 1'h0;
  assign _T_82 = stickyNonzeroRespReg == 1'h0;
  assign _T_83 = _T_82 | reset;
  assign _T_85 = _T_83 == 1'h0;
  assign _T_96_addr = io_dmi_resp_valid ? dmiReqReg_addr : 7'h0;
  assign _T_96_data = io_dmi_resp_valid ? io_dmi_resp_bits_data : 32'h0;
  assign _T_96_resp = io_dmi_resp_valid ? io_dmi_resp_bits_resp : 2'h0;
  assign _T_97_addr = _T_64 ? 7'h0 : _T_96_addr;
  assign _T_97_data = _T_64 ? 32'h0 : _T_96_data;
  assign _T_97_resp = _T_64 ? 2'h3 : _T_96_resp;
  assign _GEN_12 = dmiAccessChain_io_update_valid ? 1'h0 : _GEN_4;
  assign _GEN_13 = dmiAccessChain_io_update_valid ? 1'h0 : _GEN_5;
  assign _GEN_14 = dmiAccessChain_io_capture_capture ? _T_64 : _GEN_12;
  assign _GEN_15 = dmiAccessChain_io_capture_capture ? _T_69 : _GEN_13;
  assign _GEN_16 = dmiAccessChain_io_capture_capture ? _T_64 : _GEN_11;
  assign _GEN_17 = dmiAccessChain_io_capture_capture ? _T_75 : _GEN_10;
  assign _T_105 = io_dmi_req_ready & io_dmi_req_valid;
  assign _T_106 = _GEN_30 & _T_105;
  assign _T_108 = _T_106 == 1'h0;
  assign _T_109 = _T_108 | reset;
  assign _T_111 = _T_109 == 1'h0;
  assign _T_113 = dmiAccessChain_io_update_bits_op == 2'h0;
  assign _T_114 = downgradeOpReg | _T_113;
  assign _T_116 = skipOpReg == 1'h0;
  assign _T_117 = _T_116 & _T_114;
  assign _GEN_18 = _T_117 ? 7'h0 : dmiReqReg_addr;
  assign _GEN_19 = _T_117 ? 32'h0 : dmiReqReg_data;
  assign _GEN_20 = _T_117 ? 2'h0 : dmiReqReg_op;
  assign _T_124 = _T_114 == 1'h0;
  assign _T_125 = _T_116 & _T_124;
  assign _GEN_21 = _T_125 ? dmiAccessChain_io_update_bits_addr : _GEN_18;
  assign _GEN_22 = _T_125 ? dmiAccessChain_io_update_bits_data : _GEN_19;
  assign _GEN_23 = _T_125 ? dmiAccessChain_io_update_bits_op : _GEN_20;
  assign _GEN_24 = _T_125 ? 1'h1 : dmiReqValidReg;
  assign _GEN_26 = dmiAccessChain_io_update_valid ? _GEN_21 : dmiReqReg_addr;
  assign _GEN_27 = dmiAccessChain_io_update_valid ? _GEN_22 : dmiReqReg_data;
  assign _GEN_28 = dmiAccessChain_io_update_valid ? _GEN_23 : dmiReqReg_op;
  assign _GEN_29 = dmiAccessChain_io_update_valid ? _GEN_24 : dmiReqValidReg;
  assign _GEN_30 = dmiAccessChain_io_update_valid ? _T_125 : 1'h0;
  assign _GEN_31 = _T_105 ? 1'h0 : _GEN_29;
  assign tapIO_jtag_TDO_data = JtagTapController_io_jtag_TDO_data;
  assign tapIO_jtag_TDO_driven = JtagTapController_io_jtag_TDO_driven;
  assign tapIO_output_reset = JtagTapController_io_output_reset;
  assign idcodeChain_clock = clock;
  assign idcodeChain_reset = reset;
  assign idcodeChain_io_chainIn_shift = _GEN_55;
  assign idcodeChain_io_chainIn_data = _GEN_54;
  assign idcodeChain_io_chainIn_capture = _GEN_53;
  assign idcodeChain_io_chainIn_update = _GEN_52;
  assign idcodeChain_io_capture_bits_version = 4'h0;
  assign idcodeChain_io_capture_bits_partNumber = 16'h0;
  assign idcodeChain_io_capture_bits_mfrId = io_jtag_mfr_id;
  assign idcodeChain_io_capture_bits_always1 = 1'h1;
  assign _T_174 = {io_jtag_mfr_id,1'h1};
  assign _T_176 = {20'h0,_T_174};
  assign _GEN_25 = _T_176 % 32'h2;
  assign _T_178 = _GEN_25[1:0];
  assign _T_180 = _T_178 == 2'h1;
  assign _T_181 = _T_180 | reset;
  assign _T_183 = _T_181 == 1'h0;
  assign _T_184 = _T_176[31:1];
  assign _T_188 = 12'h800 - 12'h1;
  assign _T_189 = $unsigned(_T_188);
  assign _T_190 = _T_189[11:0];
  assign _GEN_72 = {{19'd0}, _T_190};
  assign _T_191 = _T_184 & _GEN_72;
  assign _T_193 = _T_191 != 31'h7f;
  assign _T_194 = _T_193 | reset;
  assign _T_196 = _T_194 == 1'h0;
  assign JtagTapController_clock = clock;
  assign JtagTapController_reset = reset;
  assign JtagTapController_io_jtag_TMS = io_jtag_TMS;
  assign JtagTapController_io_jtag_TDI = io_jtag_TDI;
  assign JtagTapController_io_control_jtag_reset = io_jtag_reset;
  assign JtagTapController_io_dataChainIn_data = _GEN_46;
  assign JtagBypassChain_clock = clock;
  assign JtagBypassChain_reset = reset;
  assign JtagBypassChain_io_chainIn_shift = JtagTapController_io_dataChainOut_shift;
  assign JtagBypassChain_io_chainIn_data = JtagTapController_io_dataChainOut_data;
  assign JtagBypassChain_io_chainIn_capture = JtagTapController_io_dataChainOut_capture;
  assign JtagBypassChain_io_chainIn_update = JtagTapController_io_dataChainOut_update;
  assign _T_204 = JtagTapController_io_output_instruction == 5'h1;
  assign _T_206 = JtagTapController_io_output_instruction == 5'h11;
  assign _T_208 = JtagTapController_io_output_instruction == 5'h10;
  assign _GEN_34 = idcodeChain_io_chainOut_data;
  assign _T_216 = _T_204 == 1'h0;
  assign _T_218 = _T_216 & _T_206;
  assign _GEN_38 = _T_218 ? dmiAccessChain_io_chainOut_data : _GEN_34;
  assign _T_225 = _T_206 == 1'h0;
  assign _T_226 = _T_216 & _T_225;
  assign _T_227 = _T_226 & _T_208;
  assign _GEN_42 = _T_227 ? dtmInfoChain_io_chainOut_data : _GEN_38;
  assign _T_237 = _T_208 == 1'h0;
  assign _T_238 = _T_226 & _T_237;
  assign _GEN_46 = _T_238 ? JtagBypassChain_io_chainOut_data : _GEN_42;
  assign _GEN_48 = JtagTapController_io_dataChainOut_update;
  assign _GEN_49 = JtagTapController_io_dataChainOut_capture;
  assign _GEN_50 = JtagTapController_io_dataChainOut_data;
  assign _GEN_51 = JtagTapController_io_dataChainOut_shift;
  assign _GEN_52 = _T_216 ? 1'h0 : _GEN_48;
  assign _GEN_53 = _T_216 ? 1'h0 : _GEN_49;
  assign _GEN_54 = _T_216 ? 1'h0 : _GEN_50;
  assign _GEN_55 = _T_216 ? 1'h0 : _GEN_51;
  assign _GEN_60 = _T_225 ? 1'h0 : _GEN_48;
  assign _GEN_61 = _T_225 ? 1'h0 : _GEN_49;
  assign _GEN_62 = _T_225 ? 1'h0 : _GEN_50;
  assign _GEN_63 = _T_225 ? 1'h0 : _GEN_51;
  assign _GEN_68 = _T_237 ? 1'h0 : _GEN_48;
  assign _GEN_69 = _T_237 ? 1'h0 : _GEN_49;
  assign _GEN_70 = _T_237 ? 1'h0 : _GEN_50;
  assign _GEN_71 = _T_237 ? 1'h0 : _GEN_51;
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifndef verilator
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{$random}};
  busyReg = _RAND_0[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{$random}};
  stickyBusyReg = _RAND_1[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_2 = {1{$random}};
  stickyNonzeroRespReg = _RAND_2[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_3 = {1{$random}};
  skipOpReg = _RAND_3[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_4 = {1{$random}};
  downgradeOpReg = _RAND_4[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_5 = {1{$random}};
  dmiReqReg_addr = _RAND_5[6:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_6 = {1{$random}};
  dmiReqReg_data = _RAND_6[31:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_7 = {1{$random}};
  dmiReqReg_op = _RAND_7[1:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_8 = {1{$random}};
  dmiReqValidReg = _RAND_8[0:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (reset) begin
      busyReg <= 1'h0;
    end else begin
      if (_T_59) begin
        busyReg <= 1'h0;
      end else begin
        if (io_dmi_req_valid) begin
          busyReg <= 1'h1;
        end
      end
    end
    if (reset) begin
      stickyBusyReg <= 1'h0;
    end else begin
      if (dmiAccessChain_io_capture_capture) begin
        stickyBusyReg <= _T_64;
      end else begin
        if (dtmInfoChain_io_update_valid) begin
          if (dtmInfoChain_io_update_bits_dmireset) begin
            stickyBusyReg <= 1'h0;
          end else begin
            if (dmiAccessChain_io_capture_capture) begin
              stickyBusyReg <= _T_64;
            end
          end
        end else begin
          if (dmiAccessChain_io_capture_capture) begin
            stickyBusyReg <= _T_64;
          end
        end
      end
    end
    if (reset) begin
      stickyNonzeroRespReg <= 1'h0;
    end else begin
      if (dmiAccessChain_io_capture_capture) begin
        stickyNonzeroRespReg <= _T_75;
      end else begin
        if (dtmInfoChain_io_update_valid) begin
          if (dtmInfoChain_io_update_bits_dmireset) begin
            stickyNonzeroRespReg <= 1'h0;
          end else begin
            if (dmiAccessChain_io_capture_capture) begin
              stickyNonzeroRespReg <= _T_75;
            end
          end
        end else begin
          if (dmiAccessChain_io_capture_capture) begin
            stickyNonzeroRespReg <= _T_75;
          end
        end
      end
    end
    if (reset) begin
      skipOpReg <= 1'h0;
    end else begin
      if (dmiAccessChain_io_capture_capture) begin
        skipOpReg <= _T_64;
      end else begin
        if (dmiAccessChain_io_update_valid) begin
          skipOpReg <= 1'h0;
        end else begin
          if (dmiAccessChain_io_capture_capture) begin
            skipOpReg <= _T_64;
          end else begin
            if (dmiAccessChain_io_update_valid) begin
              skipOpReg <= 1'h0;
            end
          end
        end
      end
    end
    if (reset) begin
      downgradeOpReg <= 1'h0;
    end else begin
      if (dmiAccessChain_io_capture_capture) begin
        downgradeOpReg <= _T_69;
      end else begin
        if (dmiAccessChain_io_update_valid) begin
          downgradeOpReg <= 1'h0;
        end else begin
          if (dmiAccessChain_io_capture_capture) begin
            downgradeOpReg <= _T_69;
          end else begin
            if (dmiAccessChain_io_update_valid) begin
              downgradeOpReg <= 1'h0;
            end
          end
        end
      end
    end
    if (dmiAccessChain_io_update_valid) begin
      if (_T_125) begin
        dmiReqReg_addr <= dmiAccessChain_io_update_bits_addr;
      end else begin
        if (_T_117) begin
          dmiReqReg_addr <= 7'h0;
        end
      end
    end
    if (dmiAccessChain_io_update_valid) begin
      if (_T_125) begin
        dmiReqReg_data <= dmiAccessChain_io_update_bits_data;
      end else begin
        if (_T_117) begin
          dmiReqReg_data <= 32'h0;
        end
      end
    end
    if (dmiAccessChain_io_update_valid) begin
      if (_T_125) begin
        dmiReqReg_op <= dmiAccessChain_io_update_bits_op;
      end else begin
        if (_T_117) begin
          dmiReqReg_op <= 2'h0;
        end
      end
    end
    if (reset) begin
      dmiReqValidReg <= 1'h0;
    end else begin
      if (_T_105) begin
        dmiReqValidReg <= 1'h0;
      end else begin
        if (dmiAccessChain_io_update_valid) begin
          if (_T_125) begin
            dmiReqValidReg <= 1'h1;
          end
        end
      end
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_80) begin
          $fwrite(32'h80000001,"Assertion failed: There is no reason to get a non zero response in the current system.\n    at DebugTransport.scala:176 assert(!nonzeroResp, \"There is no reason to get a non zero response in the current system.\");\n");
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_80) begin
          $fatal;
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_85) begin
          $fwrite(32'h80000001,"Assertion failed: There is no reason to have a sticky non zero response in the current system.\n    at DebugTransport.scala:177 assert(!stickyNonzeroRespReg, \"There is no reason to have a sticky non zero response in the current system.\");\n");
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_85) begin
          $fatal;
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_111) begin
          $fwrite(32'h80000001,"Assertion failed: Conflicting updates for dmiReqValidReg, should not happen.\n    at DebugTransport.scala:210 assert(!(dmiReqValidCheck && io.dmi.req.fire()), \"Conflicting updates for dmiReqValidReg, should not happen.\");\n");
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_111) begin
          $fatal;
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_183) begin
          $fwrite(32'h80000001,"Assertion failed: LSB must be set in IDCODE, see 12.1.1d\n    at JtagTap.scala:175 assert(i %% 2.U === 1.U, \"LSB must be set in IDCODE, see 12.1.1d\")\n");
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_183) begin
          $fatal;
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_196) begin
          $fwrite(32'h80000001,"Assertion failed: IDCODE must not have 0b00001111111 as manufacturer identity, see 12.2.1b\n    at JtagTap.scala:176 assert(((i >> 1) & ((1.U << 11) - 1.U)) =/= JtagIdcode.dummyMfrId.U,\n");
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_196) begin
          $fatal;
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
endmodule
