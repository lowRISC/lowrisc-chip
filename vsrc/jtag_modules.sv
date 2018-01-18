module CaptureUpdateChain(
  input         clock,
  input         reset,
  input         io_chainIn_shift,
  input         io_chainIn_data,
  input         io_chainIn_capture,
  input         io_chainIn_update,
  output        io_chainOut_data,
  input  [14:0] io_capture_bits_reserved1,
  input         io_capture_bits_dmireset,
  input         io_capture_bits_reserved0,
  input  [2:0]  io_capture_bits_dmiIdleCycles,
  input  [1:0]  io_capture_bits_dmiStatus,
  input  [5:0]  io_capture_bits_debugAddrBits,
  input  [3:0]  io_capture_bits_debugVersion,
  output        io_update_valid,
  output        io_update_bits_dmireset
);
  reg  regs_0;
  reg [31:0] _RAND_0;
  reg  regs_1;
  reg [31:0] _RAND_1;
  reg  regs_2;
  reg [31:0] _RAND_2;
  reg  regs_3;
  reg [31:0] _RAND_3;
  reg  regs_4;
  reg [31:0] _RAND_4;
  reg  regs_5;
  reg [31:0] _RAND_5;
  reg  regs_6;
  reg [31:0] _RAND_6;
  reg  regs_7;
  reg [31:0] _RAND_7;
  reg  regs_8;
  reg [31:0] _RAND_8;
  reg  regs_9;
  reg [31:0] _RAND_9;
  reg  regs_10;
  reg [31:0] _RAND_10;
  reg  regs_11;
  reg [31:0] _RAND_11;
  reg  regs_12;
  reg [31:0] _RAND_12;
  reg  regs_13;
  reg [31:0] _RAND_13;
  reg  regs_14;
  reg [31:0] _RAND_14;
  reg  regs_15;
  reg [31:0] _RAND_15;
  reg  regs_16;
  reg [31:0] _RAND_16;
  reg  regs_17;
  reg [31:0] _RAND_17;
  reg  regs_18;
  reg [31:0] _RAND_18;
  reg  regs_19;
  reg [31:0] _RAND_19;
  reg  regs_20;
  reg [31:0] _RAND_20;
  reg  regs_21;
  reg [31:0] _RAND_21;
  reg  regs_22;
  reg [31:0] _RAND_22;
  reg  regs_23;
  reg [31:0] _RAND_23;
  reg  regs_24;
  reg [31:0] _RAND_24;
  reg  regs_25;
  reg [31:0] _RAND_25;
  reg  regs_26;
  reg [31:0] _RAND_26;
  reg  regs_27;
  reg [31:0] _RAND_27;
  reg  regs_28;
  reg [31:0] _RAND_28;
  reg  regs_29;
  reg [31:0] _RAND_29;
  reg  regs_30;
  reg [31:0] _RAND_30;
  reg  regs_31;
  reg [31:0] _RAND_31;
  wire [1:0] _T_39;
  wire [1:0] _T_40;
  wire [3:0] _T_41;
  wire [1:0] _T_42;
  wire [1:0] _T_43;
  wire [3:0] _T_44;
  wire [7:0] _T_45;
  wire [1:0] _T_46;
  wire [1:0] _T_47;
  wire [3:0] _T_48;
  wire [1:0] _T_49;
  wire [1:0] _T_50;
  wire [3:0] _T_51;
  wire [7:0] _T_52;
  wire [15:0] _T_53;
  wire [1:0] _T_54;
  wire [1:0] _T_55;
  wire [3:0] _T_56;
  wire [1:0] _T_57;
  wire [1:0] _T_58;
  wire [3:0] _T_59;
  wire [7:0] _T_60;
  wire [1:0] _T_61;
  wire [1:0] _T_62;
  wire [3:0] _T_63;
  wire [1:0] _T_64;
  wire [1:0] _T_65;
  wire [3:0] _T_66;
  wire [7:0] _T_67;
  wire [15:0] _T_68;
  wire [31:0] _T_69;
  wire  _T_79;
  wire [7:0] _T_81;
  wire [11:0] _T_82;
  wire [3:0] _T_83;
  wire [15:0] _T_84;
  wire [19:0] _T_85;
  wire [31:0] captureBits;
  wire  _T_86;
  wire  _T_87;
  wire  _T_88;
  wire  _T_89;
  wire  _T_90;
  wire  _T_91;
  wire  _T_92;
  wire  _T_93;
  wire  _T_94;
  wire  _T_95;
  wire  _T_96;
  wire  _T_97;
  wire  _T_98;
  wire  _T_99;
  wire  _T_100;
  wire  _T_101;
  wire  _T_102;
  wire  _T_103;
  wire  _T_104;
  wire  _T_105;
  wire  _T_106;
  wire  _T_107;
  wire  _T_108;
  wire  _T_109;
  wire  _T_110;
  wire  _T_111;
  wire  _T_112;
  wire  _T_113;
  wire  _T_114;
  wire  _T_115;
  wire  _T_116;
  wire  _T_117;
  wire  _GEN_0;
  wire  _GEN_1;
  wire  _GEN_2;
  wire  _GEN_3;
  wire  _GEN_4;
  wire  _GEN_5;
  wire  _GEN_6;
  wire  _GEN_7;
  wire  _GEN_8;
  wire  _GEN_9;
  wire  _GEN_10;
  wire  _GEN_11;
  wire  _GEN_12;
  wire  _GEN_13;
  wire  _GEN_14;
  wire  _GEN_15;
  wire  _GEN_16;
  wire  _GEN_17;
  wire  _GEN_18;
  wire  _GEN_19;
  wire  _GEN_20;
  wire  _GEN_21;
  wire  _GEN_22;
  wire  _GEN_23;
  wire  _GEN_24;
  wire  _GEN_25;
  wire  _GEN_26;
  wire  _GEN_27;
  wire  _GEN_28;
  wire  _GEN_29;
  wire  _GEN_30;
  wire  _GEN_31;
  wire  _T_121;
  wire  _T_122;
  wire  _T_128;
  wire  _T_129;
  wire  _T_130;
  wire  _GEN_36;
  wire  _GEN_37;
  wire  _GEN_38;
  wire  _GEN_39;
  wire  _GEN_40;
  wire  _GEN_41;
  wire  _GEN_42;
  wire  _GEN_43;
  wire  _GEN_44;
  wire  _GEN_45;
  wire  _GEN_46;
  wire  _GEN_47;
  wire  _GEN_48;
  wire  _GEN_49;
  wire  _GEN_50;
  wire  _GEN_51;
  wire  _GEN_52;
  wire  _GEN_53;
  wire  _GEN_54;
  wire  _GEN_55;
  wire  _GEN_56;
  wire  _GEN_57;
  wire  _GEN_58;
  wire  _GEN_59;
  wire  _GEN_60;
  wire  _GEN_61;
  wire  _GEN_62;
  wire  _GEN_63;
  wire  _GEN_64;
  wire  _GEN_65;
  wire  _GEN_66;
  wire  _GEN_67;
  wire  _GEN_69;
  wire  _T_139;
  wire  _T_140;
  wire  _GEN_71;
  wire  _T_143;
  wire  _T_145;
  wire  _T_146;
  wire  _T_148;
  wire  _T_149;
  wire  _T_150;
  wire  _T_152;
  wire  _T_153;
  wire  _T_154;
  wire  _T_156;
  assign io_chainOut_data = regs_0;
  assign io_update_valid = _GEN_71;
  assign io_update_bits_dmireset = _T_79;
  assign _T_39 = {regs_1,regs_0};
  assign _T_40 = {regs_3,regs_2};
  assign _T_41 = {_T_40,_T_39};
  assign _T_42 = {regs_5,regs_4};
  assign _T_43 = {regs_7,regs_6};
  assign _T_44 = {_T_43,_T_42};
  assign _T_45 = {_T_44,_T_41};
  assign _T_46 = {regs_9,regs_8};
  assign _T_47 = {regs_11,regs_10};
  assign _T_48 = {_T_47,_T_46};
  assign _T_49 = {regs_13,regs_12};
  assign _T_50 = {regs_15,regs_14};
  assign _T_51 = {_T_50,_T_49};
  assign _T_52 = {_T_51,_T_48};
  assign _T_53 = {_T_52,_T_45};
  assign _T_54 = {regs_17,regs_16};
  assign _T_55 = {regs_19,regs_18};
  assign _T_56 = {_T_55,_T_54};
  assign _T_57 = {regs_21,regs_20};
  assign _T_58 = {regs_23,regs_22};
  assign _T_59 = {_T_58,_T_57};
  assign _T_60 = {_T_59,_T_56};
  assign _T_61 = {regs_25,regs_24};
  assign _T_62 = {regs_27,regs_26};
  assign _T_63 = {_T_62,_T_61};
  assign _T_64 = {regs_29,regs_28};
  assign _T_65 = {regs_31,regs_30};
  assign _T_66 = {_T_65,_T_64};
  assign _T_67 = {_T_66,_T_63};
  assign _T_68 = {_T_67,_T_60};
  assign _T_69 = {_T_68,_T_53};
  assign _T_79 = _T_69[16];
  assign _T_81 = {io_capture_bits_dmiStatus,io_capture_bits_debugAddrBits};
  assign _T_82 = {_T_81,io_capture_bits_debugVersion};
  assign _T_83 = {io_capture_bits_reserved0,io_capture_bits_dmiIdleCycles};
  assign _T_84 = {io_capture_bits_reserved1,io_capture_bits_dmireset};
  assign _T_85 = {_T_84,_T_83};
  assign captureBits = {_T_85,_T_82};
  assign _T_86 = captureBits[0];
  assign _T_87 = captureBits[1];
  assign _T_88 = captureBits[2];
  assign _T_89 = captureBits[3];
  assign _T_90 = captureBits[4];
  assign _T_91 = captureBits[5];
  assign _T_92 = captureBits[6];
  assign _T_93 = captureBits[7];
  assign _T_94 = captureBits[8];
  assign _T_95 = captureBits[9];
  assign _T_96 = captureBits[10];
  assign _T_97 = captureBits[11];
  assign _T_98 = captureBits[12];
  assign _T_99 = captureBits[13];
  assign _T_100 = captureBits[14];
  assign _T_101 = captureBits[15];
  assign _T_102 = captureBits[16];
  assign _T_103 = captureBits[17];
  assign _T_104 = captureBits[18];
  assign _T_105 = captureBits[19];
  assign _T_106 = captureBits[20];
  assign _T_107 = captureBits[21];
  assign _T_108 = captureBits[22];
  assign _T_109 = captureBits[23];
  assign _T_110 = captureBits[24];
  assign _T_111 = captureBits[25];
  assign _T_112 = captureBits[26];
  assign _T_113 = captureBits[27];
  assign _T_114 = captureBits[28];
  assign _T_115 = captureBits[29];
  assign _T_116 = captureBits[30];
  assign _T_117 = captureBits[31];
  assign _GEN_0 = io_chainIn_capture ? _T_86 : regs_0;
  assign _GEN_1 = io_chainIn_capture ? _T_87 : regs_1;
  assign _GEN_2 = io_chainIn_capture ? _T_88 : regs_2;
  assign _GEN_3 = io_chainIn_capture ? _T_89 : regs_3;
  assign _GEN_4 = io_chainIn_capture ? _T_90 : regs_4;
  assign _GEN_5 = io_chainIn_capture ? _T_91 : regs_5;
  assign _GEN_6 = io_chainIn_capture ? _T_92 : regs_6;
  assign _GEN_7 = io_chainIn_capture ? _T_93 : regs_7;
  assign _GEN_8 = io_chainIn_capture ? _T_94 : regs_8;
  assign _GEN_9 = io_chainIn_capture ? _T_95 : regs_9;
  assign _GEN_10 = io_chainIn_capture ? _T_96 : regs_10;
  assign _GEN_11 = io_chainIn_capture ? _T_97 : regs_11;
  assign _GEN_12 = io_chainIn_capture ? _T_98 : regs_12;
  assign _GEN_13 = io_chainIn_capture ? _T_99 : regs_13;
  assign _GEN_14 = io_chainIn_capture ? _T_100 : regs_14;
  assign _GEN_15 = io_chainIn_capture ? _T_101 : regs_15;
  assign _GEN_16 = io_chainIn_capture ? _T_102 : regs_16;
  assign _GEN_17 = io_chainIn_capture ? _T_103 : regs_17;
  assign _GEN_18 = io_chainIn_capture ? _T_104 : regs_18;
  assign _GEN_19 = io_chainIn_capture ? _T_105 : regs_19;
  assign _GEN_20 = io_chainIn_capture ? _T_106 : regs_20;
  assign _GEN_21 = io_chainIn_capture ? _T_107 : regs_21;
  assign _GEN_22 = io_chainIn_capture ? _T_108 : regs_22;
  assign _GEN_23 = io_chainIn_capture ? _T_109 : regs_23;
  assign _GEN_24 = io_chainIn_capture ? _T_110 : regs_24;
  assign _GEN_25 = io_chainIn_capture ? _T_111 : regs_25;
  assign _GEN_26 = io_chainIn_capture ? _T_112 : regs_26;
  assign _GEN_27 = io_chainIn_capture ? _T_113 : regs_27;
  assign _GEN_28 = io_chainIn_capture ? _T_114 : regs_28;
  assign _GEN_29 = io_chainIn_capture ? _T_115 : regs_29;
  assign _GEN_30 = io_chainIn_capture ? _T_116 : regs_30;
  assign _GEN_31 = io_chainIn_capture ? _T_117 : regs_31;
  assign _T_121 = io_chainIn_capture == 1'h0;
  assign _T_122 = _T_121 & io_chainIn_update;
  assign _T_128 = io_chainIn_update == 1'h0;
  assign _T_129 = _T_121 & _T_128;
  assign _T_130 = _T_129 & io_chainIn_shift;
  assign _GEN_36 = _T_130 ? io_chainIn_data : _GEN_31;
  assign _GEN_37 = _T_130 ? regs_1 : _GEN_0;
  assign _GEN_38 = _T_130 ? regs_2 : _GEN_1;
  assign _GEN_39 = _T_130 ? regs_3 : _GEN_2;
  assign _GEN_40 = _T_130 ? regs_4 : _GEN_3;
  assign _GEN_41 = _T_130 ? regs_5 : _GEN_4;
  assign _GEN_42 = _T_130 ? regs_6 : _GEN_5;
  assign _GEN_43 = _T_130 ? regs_7 : _GEN_6;
  assign _GEN_44 = _T_130 ? regs_8 : _GEN_7;
  assign _GEN_45 = _T_130 ? regs_9 : _GEN_8;
  assign _GEN_46 = _T_130 ? regs_10 : _GEN_9;
  assign _GEN_47 = _T_130 ? regs_11 : _GEN_10;
  assign _GEN_48 = _T_130 ? regs_12 : _GEN_11;
  assign _GEN_49 = _T_130 ? regs_13 : _GEN_12;
  assign _GEN_50 = _T_130 ? regs_14 : _GEN_13;
  assign _GEN_51 = _T_130 ? regs_15 : _GEN_14;
  assign _GEN_52 = _T_130 ? regs_16 : _GEN_15;
  assign _GEN_53 = _T_130 ? regs_17 : _GEN_16;
  assign _GEN_54 = _T_130 ? regs_18 : _GEN_17;
  assign _GEN_55 = _T_130 ? regs_19 : _GEN_18;
  assign _GEN_56 = _T_130 ? regs_20 : _GEN_19;
  assign _GEN_57 = _T_130 ? regs_21 : _GEN_20;
  assign _GEN_58 = _T_130 ? regs_22 : _GEN_21;
  assign _GEN_59 = _T_130 ? regs_23 : _GEN_22;
  assign _GEN_60 = _T_130 ? regs_24 : _GEN_23;
  assign _GEN_61 = _T_130 ? regs_25 : _GEN_24;
  assign _GEN_62 = _T_130 ? regs_26 : _GEN_25;
  assign _GEN_63 = _T_130 ? regs_27 : _GEN_26;
  assign _GEN_64 = _T_130 ? regs_28 : _GEN_27;
  assign _GEN_65 = _T_130 ? regs_29 : _GEN_28;
  assign _GEN_66 = _T_130 ? regs_30 : _GEN_29;
  assign _GEN_67 = _T_130 ? regs_31 : _GEN_30;
  assign _GEN_69 = _T_130 ? 1'h0 : _T_122;
  assign _T_139 = io_chainIn_shift == 1'h0;
  assign _T_140 = _T_129 & _T_139;
  assign _GEN_71 = _T_140 ? 1'h0 : _GEN_69;
  assign _T_143 = io_chainIn_capture & io_chainIn_update;
  assign _T_145 = _T_143 == 1'h0;
  assign _T_146 = io_chainIn_capture & io_chainIn_shift;
  assign _T_148 = _T_146 == 1'h0;
  assign _T_149 = _T_145 & _T_148;
  assign _T_150 = io_chainIn_update & io_chainIn_shift;
  assign _T_152 = _T_150 == 1'h0;
  assign _T_153 = _T_149 & _T_152;
  assign _T_154 = _T_153 | reset;
  assign _T_156 = _T_154 == 1'h0;
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifndef verilator
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{$random}};
  regs_0 = _RAND_0[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{$random}};
  regs_1 = _RAND_1[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_2 = {1{$random}};
  regs_2 = _RAND_2[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_3 = {1{$random}};
  regs_3 = _RAND_3[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_4 = {1{$random}};
  regs_4 = _RAND_4[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_5 = {1{$random}};
  regs_5 = _RAND_5[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_6 = {1{$random}};
  regs_6 = _RAND_6[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_7 = {1{$random}};
  regs_7 = _RAND_7[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_8 = {1{$random}};
  regs_8 = _RAND_8[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_9 = {1{$random}};
  regs_9 = _RAND_9[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_10 = {1{$random}};
  regs_10 = _RAND_10[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_11 = {1{$random}};
  regs_11 = _RAND_11[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_12 = {1{$random}};
  regs_12 = _RAND_12[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_13 = {1{$random}};
  regs_13 = _RAND_13[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_14 = {1{$random}};
  regs_14 = _RAND_14[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_15 = {1{$random}};
  regs_15 = _RAND_15[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_16 = {1{$random}};
  regs_16 = _RAND_16[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_17 = {1{$random}};
  regs_17 = _RAND_17[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_18 = {1{$random}};
  regs_18 = _RAND_18[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_19 = {1{$random}};
  regs_19 = _RAND_19[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_20 = {1{$random}};
  regs_20 = _RAND_20[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_21 = {1{$random}};
  regs_21 = _RAND_21[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_22 = {1{$random}};
  regs_22 = _RAND_22[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_23 = {1{$random}};
  regs_23 = _RAND_23[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_24 = {1{$random}};
  regs_24 = _RAND_24[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_25 = {1{$random}};
  regs_25 = _RAND_25[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_26 = {1{$random}};
  regs_26 = _RAND_26[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_27 = {1{$random}};
  regs_27 = _RAND_27[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_28 = {1{$random}};
  regs_28 = _RAND_28[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_29 = {1{$random}};
  regs_29 = _RAND_29[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_30 = {1{$random}};
  regs_30 = _RAND_30[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_31 = {1{$random}};
  regs_31 = _RAND_31[0:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (_T_130) begin
      regs_0 <= regs_1;
    end else begin
      if (io_chainIn_capture) begin
        regs_0 <= _T_86;
      end
    end
    if (_T_130) begin
      regs_1 <= regs_2;
    end else begin
      if (io_chainIn_capture) begin
        regs_1 <= _T_87;
      end
    end
    if (_T_130) begin
      regs_2 <= regs_3;
    end else begin
      if (io_chainIn_capture) begin
        regs_2 <= _T_88;
      end
    end
    if (_T_130) begin
      regs_3 <= regs_4;
    end else begin
      if (io_chainIn_capture) begin
        regs_3 <= _T_89;
      end
    end
    if (_T_130) begin
      regs_4 <= regs_5;
    end else begin
      if (io_chainIn_capture) begin
        regs_4 <= _T_90;
      end
    end
    if (_T_130) begin
      regs_5 <= regs_6;
    end else begin
      if (io_chainIn_capture) begin
        regs_5 <= _T_91;
      end
    end
    if (_T_130) begin
      regs_6 <= regs_7;
    end else begin
      if (io_chainIn_capture) begin
        regs_6 <= _T_92;
      end
    end
    if (_T_130) begin
      regs_7 <= regs_8;
    end else begin
      if (io_chainIn_capture) begin
        regs_7 <= _T_93;
      end
    end
    if (_T_130) begin
      regs_8 <= regs_9;
    end else begin
      if (io_chainIn_capture) begin
        regs_8 <= _T_94;
      end
    end
    if (_T_130) begin
      regs_9 <= regs_10;
    end else begin
      if (io_chainIn_capture) begin
        regs_9 <= _T_95;
      end
    end
    if (_T_130) begin
      regs_10 <= regs_11;
    end else begin
      if (io_chainIn_capture) begin
        regs_10 <= _T_96;
      end
    end
    if (_T_130) begin
      regs_11 <= regs_12;
    end else begin
      if (io_chainIn_capture) begin
        regs_11 <= _T_97;
      end
    end
    if (_T_130) begin
      regs_12 <= regs_13;
    end else begin
      if (io_chainIn_capture) begin
        regs_12 <= _T_98;
      end
    end
    if (_T_130) begin
      regs_13 <= regs_14;
    end else begin
      if (io_chainIn_capture) begin
        regs_13 <= _T_99;
      end
    end
    if (_T_130) begin
      regs_14 <= regs_15;
    end else begin
      if (io_chainIn_capture) begin
        regs_14 <= _T_100;
      end
    end
    if (_T_130) begin
      regs_15 <= regs_16;
    end else begin
      if (io_chainIn_capture) begin
        regs_15 <= _T_101;
      end
    end
    if (_T_130) begin
      regs_16 <= regs_17;
    end else begin
      if (io_chainIn_capture) begin
        regs_16 <= _T_102;
      end
    end
    if (_T_130) begin
      regs_17 <= regs_18;
    end else begin
      if (io_chainIn_capture) begin
        regs_17 <= _T_103;
      end
    end
    if (_T_130) begin
      regs_18 <= regs_19;
    end else begin
      if (io_chainIn_capture) begin
        regs_18 <= _T_104;
      end
    end
    if (_T_130) begin
      regs_19 <= regs_20;
    end else begin
      if (io_chainIn_capture) begin
        regs_19 <= _T_105;
      end
    end
    if (_T_130) begin
      regs_20 <= regs_21;
    end else begin
      if (io_chainIn_capture) begin
        regs_20 <= _T_106;
      end
    end
    if (_T_130) begin
      regs_21 <= regs_22;
    end else begin
      if (io_chainIn_capture) begin
        regs_21 <= _T_107;
      end
    end
    if (_T_130) begin
      regs_22 <= regs_23;
    end else begin
      if (io_chainIn_capture) begin
        regs_22 <= _T_108;
      end
    end
    if (_T_130) begin
      regs_23 <= regs_24;
    end else begin
      if (io_chainIn_capture) begin
        regs_23 <= _T_109;
      end
    end
    if (_T_130) begin
      regs_24 <= regs_25;
    end else begin
      if (io_chainIn_capture) begin
        regs_24 <= _T_110;
      end
    end
    if (_T_130) begin
      regs_25 <= regs_26;
    end else begin
      if (io_chainIn_capture) begin
        regs_25 <= _T_111;
      end
    end
    if (_T_130) begin
      regs_26 <= regs_27;
    end else begin
      if (io_chainIn_capture) begin
        regs_26 <= _T_112;
      end
    end
    if (_T_130) begin
      regs_27 <= regs_28;
    end else begin
      if (io_chainIn_capture) begin
        regs_27 <= _T_113;
      end
    end
    if (_T_130) begin
      regs_28 <= regs_29;
    end else begin
      if (io_chainIn_capture) begin
        regs_28 <= _T_114;
      end
    end
    if (_T_130) begin
      regs_29 <= regs_30;
    end else begin
      if (io_chainIn_capture) begin
        regs_29 <= _T_115;
      end
    end
    if (_T_130) begin
      regs_30 <= regs_31;
    end else begin
      if (io_chainIn_capture) begin
        regs_30 <= _T_116;
      end
    end
    if (_T_130) begin
      regs_31 <= io_chainIn_data;
    end else begin
      if (io_chainIn_capture) begin
        regs_31 <= _T_117;
      end
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_156) begin
          $fwrite(32'h80000001,"Assertion failed\n    at JtagShifter.scala:174 assert(!(io.chainIn.capture && io.chainIn.update)\n");
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_156) begin
          $fatal;
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
endmodule
module CaptureUpdateChain_1(
  input         clock,
  input         reset,
  input         io_chainIn_shift,
  input         io_chainIn_data,
  input         io_chainIn_capture,
  input         io_chainIn_update,
  output        io_chainOut_data,
  input  [6:0]  io_capture_bits_addr,
  input  [31:0] io_capture_bits_data,
  input  [1:0]  io_capture_bits_resp,
  output        io_capture_capture,
  output        io_update_valid,
  output [6:0]  io_update_bits_addr,
  output [31:0] io_update_bits_data,
  output [1:0]  io_update_bits_op
);
  reg  regs_0;
  reg [31:0] _RAND_0;
  reg  regs_1;
  reg [31:0] _RAND_1;
  reg  regs_2;
  reg [31:0] _RAND_2;
  reg  regs_3;
  reg [31:0] _RAND_3;
  reg  regs_4;
  reg [31:0] _RAND_4;
  reg  regs_5;
  reg [31:0] _RAND_5;
  reg  regs_6;
  reg [31:0] _RAND_6;
  reg  regs_7;
  reg [31:0] _RAND_7;
  reg  regs_8;
  reg [31:0] _RAND_8;
  reg  regs_9;
  reg [31:0] _RAND_9;
  reg  regs_10;
  reg [31:0] _RAND_10;
  reg  regs_11;
  reg [31:0] _RAND_11;
  reg  regs_12;
  reg [31:0] _RAND_12;
  reg  regs_13;
  reg [31:0] _RAND_13;
  reg  regs_14;
  reg [31:0] _RAND_14;
  reg  regs_15;
  reg [31:0] _RAND_15;
  reg  regs_16;
  reg [31:0] _RAND_16;
  reg  regs_17;
  reg [31:0] _RAND_17;
  reg  regs_18;
  reg [31:0] _RAND_18;
  reg  regs_19;
  reg [31:0] _RAND_19;
  reg  regs_20;
  reg [31:0] _RAND_20;
  reg  regs_21;
  reg [31:0] _RAND_21;
  reg  regs_22;
  reg [31:0] _RAND_22;
  reg  regs_23;
  reg [31:0] _RAND_23;
  reg  regs_24;
  reg [31:0] _RAND_24;
  reg  regs_25;
  reg [31:0] _RAND_25;
  reg  regs_26;
  reg [31:0] _RAND_26;
  reg  regs_27;
  reg [31:0] _RAND_27;
  reg  regs_28;
  reg [31:0] _RAND_28;
  reg  regs_29;
  reg [31:0] _RAND_29;
  reg  regs_30;
  reg [31:0] _RAND_30;
  reg  regs_31;
  reg [31:0] _RAND_31;
  reg  regs_32;
  reg [31:0] _RAND_32;
  reg  regs_33;
  reg [31:0] _RAND_33;
  reg  regs_34;
  reg [31:0] _RAND_34;
  reg  regs_35;
  reg [31:0] _RAND_35;
  reg  regs_36;
  reg [31:0] _RAND_36;
  reg  regs_37;
  reg [31:0] _RAND_37;
  reg  regs_38;
  reg [31:0] _RAND_38;
  reg  regs_39;
  reg [31:0] _RAND_39;
  reg  regs_40;
  reg [31:0] _RAND_40;
  wire [1:0] _T_48;
  wire [1:0] _T_49;
  wire [2:0] _T_50;
  wire [4:0] _T_51;
  wire [1:0] _T_52;
  wire [1:0] _T_53;
  wire [2:0] _T_54;
  wire [4:0] _T_55;
  wire [9:0] _T_56;
  wire [1:0] _T_57;
  wire [1:0] _T_58;
  wire [2:0] _T_59;
  wire [4:0] _T_60;
  wire [1:0] _T_61;
  wire [1:0] _T_62;
  wire [2:0] _T_63;
  wire [4:0] _T_64;
  wire [9:0] _T_65;
  wire [19:0] _T_66;
  wire [1:0] _T_67;
  wire [1:0] _T_68;
  wire [2:0] _T_69;
  wire [4:0] _T_70;
  wire [1:0] _T_71;
  wire [1:0] _T_72;
  wire [2:0] _T_73;
  wire [4:0] _T_74;
  wire [9:0] _T_75;
  wire [1:0] _T_76;
  wire [1:0] _T_77;
  wire [2:0] _T_78;
  wire [4:0] _T_79;
  wire [1:0] _T_80;
  wire [2:0] _T_81;
  wire [1:0] _T_82;
  wire [2:0] _T_83;
  wire [5:0] _T_84;
  wire [10:0] _T_85;
  wire [20:0] _T_86;
  wire [40:0] _T_87;
  wire [1:0] _T_92;
  wire [31:0] _T_93;
  wire [6:0] _T_94;
  wire [38:0] _T_95;
  wire [40:0] captureBits;
  wire  _T_96;
  wire  _T_97;
  wire  _T_98;
  wire  _T_99;
  wire  _T_100;
  wire  _T_101;
  wire  _T_102;
  wire  _T_103;
  wire  _T_104;
  wire  _T_105;
  wire  _T_106;
  wire  _T_107;
  wire  _T_108;
  wire  _T_109;
  wire  _T_110;
  wire  _T_111;
  wire  _T_112;
  wire  _T_113;
  wire  _T_114;
  wire  _T_115;
  wire  _T_116;
  wire  _T_117;
  wire  _T_118;
  wire  _T_119;
  wire  _T_120;
  wire  _T_121;
  wire  _T_122;
  wire  _T_123;
  wire  _T_124;
  wire  _T_125;
  wire  _T_126;
  wire  _T_127;
  wire  _T_128;
  wire  _T_129;
  wire  _T_130;
  wire  _T_131;
  wire  _T_132;
  wire  _T_133;
  wire  _T_134;
  wire  _T_135;
  wire  _T_136;
  wire  _GEN_0;
  wire  _GEN_1;
  wire  _GEN_2;
  wire  _GEN_3;
  wire  _GEN_4;
  wire  _GEN_5;
  wire  _GEN_6;
  wire  _GEN_7;
  wire  _GEN_8;
  wire  _GEN_9;
  wire  _GEN_10;
  wire  _GEN_11;
  wire  _GEN_12;
  wire  _GEN_13;
  wire  _GEN_14;
  wire  _GEN_15;
  wire  _GEN_16;
  wire  _GEN_17;
  wire  _GEN_18;
  wire  _GEN_19;
  wire  _GEN_20;
  wire  _GEN_21;
  wire  _GEN_22;
  wire  _GEN_23;
  wire  _GEN_24;
  wire  _GEN_25;
  wire  _GEN_26;
  wire  _GEN_27;
  wire  _GEN_28;
  wire  _GEN_29;
  wire  _GEN_30;
  wire  _GEN_31;
  wire  _GEN_32;
  wire  _GEN_33;
  wire  _GEN_34;
  wire  _GEN_35;
  wire  _GEN_36;
  wire  _GEN_37;
  wire  _GEN_38;
  wire  _GEN_39;
  wire  _GEN_40;
  wire  _T_140;
  wire  _T_141;
  wire  _GEN_43;
  wire  _T_147;
  wire  _T_148;
  wire  _T_149;
  wire  _GEN_45;
  wire  _GEN_46;
  wire  _GEN_47;
  wire  _GEN_48;
  wire  _GEN_49;
  wire  _GEN_50;
  wire  _GEN_51;
  wire  _GEN_52;
  wire  _GEN_53;
  wire  _GEN_54;
  wire  _GEN_55;
  wire  _GEN_56;
  wire  _GEN_57;
  wire  _GEN_58;
  wire  _GEN_59;
  wire  _GEN_60;
  wire  _GEN_61;
  wire  _GEN_62;
  wire  _GEN_63;
  wire  _GEN_64;
  wire  _GEN_65;
  wire  _GEN_66;
  wire  _GEN_67;
  wire  _GEN_68;
  wire  _GEN_69;
  wire  _GEN_70;
  wire  _GEN_71;
  wire  _GEN_72;
  wire  _GEN_73;
  wire  _GEN_74;
  wire  _GEN_75;
  wire  _GEN_76;
  wire  _GEN_77;
  wire  _GEN_78;
  wire  _GEN_79;
  wire  _GEN_80;
  wire  _GEN_81;
  wire  _GEN_82;
  wire  _GEN_83;
  wire  _GEN_84;
  wire  _GEN_85;
  wire  _GEN_86;
  wire  _GEN_87;
  wire  _T_158;
  wire  _T_159;
  wire  _GEN_88;
  wire  _GEN_89;
  wire  _T_162;
  wire  _T_164;
  wire  _T_165;
  wire  _T_167;
  wire  _T_168;
  wire  _T_169;
  wire  _T_171;
  wire  _T_172;
  wire  _T_173;
  wire  _T_175;
  assign io_chainOut_data = regs_0;
  assign io_capture_capture = _GEN_88;
  assign io_update_valid = _GEN_89;
  assign io_update_bits_addr = _T_94;
  assign io_update_bits_data = _T_93;
  assign io_update_bits_op = _T_92;
  assign _T_48 = {regs_1,regs_0};
  assign _T_49 = {regs_4,regs_3};
  assign _T_50 = {_T_49,regs_2};
  assign _T_51 = {_T_50,_T_48};
  assign _T_52 = {regs_6,regs_5};
  assign _T_53 = {regs_9,regs_8};
  assign _T_54 = {_T_53,regs_7};
  assign _T_55 = {_T_54,_T_52};
  assign _T_56 = {_T_55,_T_51};
  assign _T_57 = {regs_11,regs_10};
  assign _T_58 = {regs_14,regs_13};
  assign _T_59 = {_T_58,regs_12};
  assign _T_60 = {_T_59,_T_57};
  assign _T_61 = {regs_16,regs_15};
  assign _T_62 = {regs_19,regs_18};
  assign _T_63 = {_T_62,regs_17};
  assign _T_64 = {_T_63,_T_61};
  assign _T_65 = {_T_64,_T_60};
  assign _T_66 = {_T_65,_T_56};
  assign _T_67 = {regs_21,regs_20};
  assign _T_68 = {regs_24,regs_23};
  assign _T_69 = {_T_68,regs_22};
  assign _T_70 = {_T_69,_T_67};
  assign _T_71 = {regs_26,regs_25};
  assign _T_72 = {regs_29,regs_28};
  assign _T_73 = {_T_72,regs_27};
  assign _T_74 = {_T_73,_T_71};
  assign _T_75 = {_T_74,_T_70};
  assign _T_76 = {regs_31,regs_30};
  assign _T_77 = {regs_34,regs_33};
  assign _T_78 = {_T_77,regs_32};
  assign _T_79 = {_T_78,_T_76};
  assign _T_80 = {regs_37,regs_36};
  assign _T_81 = {_T_80,regs_35};
  assign _T_82 = {regs_40,regs_39};
  assign _T_83 = {_T_82,regs_38};
  assign _T_84 = {_T_83,_T_81};
  assign _T_85 = {_T_84,_T_79};
  assign _T_86 = {_T_85,_T_75};
  assign _T_87 = {_T_86,_T_66};
  assign _T_92 = _T_87[1:0];
  assign _T_93 = _T_87[33:2];
  assign _T_94 = _T_87[40:34];
  assign _T_95 = {io_capture_bits_addr,io_capture_bits_data};
  assign captureBits = {_T_95,io_capture_bits_resp};
  assign _T_96 = captureBits[0];
  assign _T_97 = captureBits[1];
  assign _T_98 = captureBits[2];
  assign _T_99 = captureBits[3];
  assign _T_100 = captureBits[4];
  assign _T_101 = captureBits[5];
  assign _T_102 = captureBits[6];
  assign _T_103 = captureBits[7];
  assign _T_104 = captureBits[8];
  assign _T_105 = captureBits[9];
  assign _T_106 = captureBits[10];
  assign _T_107 = captureBits[11];
  assign _T_108 = captureBits[12];
  assign _T_109 = captureBits[13];
  assign _T_110 = captureBits[14];
  assign _T_111 = captureBits[15];
  assign _T_112 = captureBits[16];
  assign _T_113 = captureBits[17];
  assign _T_114 = captureBits[18];
  assign _T_115 = captureBits[19];
  assign _T_116 = captureBits[20];
  assign _T_117 = captureBits[21];
  assign _T_118 = captureBits[22];
  assign _T_119 = captureBits[23];
  assign _T_120 = captureBits[24];
  assign _T_121 = captureBits[25];
  assign _T_122 = captureBits[26];
  assign _T_123 = captureBits[27];
  assign _T_124 = captureBits[28];
  assign _T_125 = captureBits[29];
  assign _T_126 = captureBits[30];
  assign _T_127 = captureBits[31];
  assign _T_128 = captureBits[32];
  assign _T_129 = captureBits[33];
  assign _T_130 = captureBits[34];
  assign _T_131 = captureBits[35];
  assign _T_132 = captureBits[36];
  assign _T_133 = captureBits[37];
  assign _T_134 = captureBits[38];
  assign _T_135 = captureBits[39];
  assign _T_136 = captureBits[40];
  assign _GEN_0 = io_chainIn_capture ? _T_96 : regs_0;
  assign _GEN_1 = io_chainIn_capture ? _T_97 : regs_1;
  assign _GEN_2 = io_chainIn_capture ? _T_98 : regs_2;
  assign _GEN_3 = io_chainIn_capture ? _T_99 : regs_3;
  assign _GEN_4 = io_chainIn_capture ? _T_100 : regs_4;
  assign _GEN_5 = io_chainIn_capture ? _T_101 : regs_5;
  assign _GEN_6 = io_chainIn_capture ? _T_102 : regs_6;
  assign _GEN_7 = io_chainIn_capture ? _T_103 : regs_7;
  assign _GEN_8 = io_chainIn_capture ? _T_104 : regs_8;
  assign _GEN_9 = io_chainIn_capture ? _T_105 : regs_9;
  assign _GEN_10 = io_chainIn_capture ? _T_106 : regs_10;
  assign _GEN_11 = io_chainIn_capture ? _T_107 : regs_11;
  assign _GEN_12 = io_chainIn_capture ? _T_108 : regs_12;
  assign _GEN_13 = io_chainIn_capture ? _T_109 : regs_13;
  assign _GEN_14 = io_chainIn_capture ? _T_110 : regs_14;
  assign _GEN_15 = io_chainIn_capture ? _T_111 : regs_15;
  assign _GEN_16 = io_chainIn_capture ? _T_112 : regs_16;
  assign _GEN_17 = io_chainIn_capture ? _T_113 : regs_17;
  assign _GEN_18 = io_chainIn_capture ? _T_114 : regs_18;
  assign _GEN_19 = io_chainIn_capture ? _T_115 : regs_19;
  assign _GEN_20 = io_chainIn_capture ? _T_116 : regs_20;
  assign _GEN_21 = io_chainIn_capture ? _T_117 : regs_21;
  assign _GEN_22 = io_chainIn_capture ? _T_118 : regs_22;
  assign _GEN_23 = io_chainIn_capture ? _T_119 : regs_23;
  assign _GEN_24 = io_chainIn_capture ? _T_120 : regs_24;
  assign _GEN_25 = io_chainIn_capture ? _T_121 : regs_25;
  assign _GEN_26 = io_chainIn_capture ? _T_122 : regs_26;
  assign _GEN_27 = io_chainIn_capture ? _T_123 : regs_27;
  assign _GEN_28 = io_chainIn_capture ? _T_124 : regs_28;
  assign _GEN_29 = io_chainIn_capture ? _T_125 : regs_29;
  assign _GEN_30 = io_chainIn_capture ? _T_126 : regs_30;
  assign _GEN_31 = io_chainIn_capture ? _T_127 : regs_31;
  assign _GEN_32 = io_chainIn_capture ? _T_128 : regs_32;
  assign _GEN_33 = io_chainIn_capture ? _T_129 : regs_33;
  assign _GEN_34 = io_chainIn_capture ? _T_130 : regs_34;
  assign _GEN_35 = io_chainIn_capture ? _T_131 : regs_35;
  assign _GEN_36 = io_chainIn_capture ? _T_132 : regs_36;
  assign _GEN_37 = io_chainIn_capture ? _T_133 : regs_37;
  assign _GEN_38 = io_chainIn_capture ? _T_134 : regs_38;
  assign _GEN_39 = io_chainIn_capture ? _T_135 : regs_39;
  assign _GEN_40 = io_chainIn_capture ? _T_136 : regs_40;
  assign _T_140 = io_chainIn_capture == 1'h0;
  assign _T_141 = _T_140 & io_chainIn_update;
  assign _GEN_43 = _T_141 ? 1'h0 : 1'h1;
  assign _T_147 = io_chainIn_update == 1'h0;
  assign _T_148 = _T_140 & _T_147;
  assign _T_149 = _T_148 & io_chainIn_shift;
  assign _GEN_45 = _T_149 ? io_chainIn_data : _GEN_40;
  assign _GEN_46 = _T_149 ? regs_1 : _GEN_0;
  assign _GEN_47 = _T_149 ? regs_2 : _GEN_1;
  assign _GEN_48 = _T_149 ? regs_3 : _GEN_2;
  assign _GEN_49 = _T_149 ? regs_4 : _GEN_3;
  assign _GEN_50 = _T_149 ? regs_5 : _GEN_4;
  assign _GEN_51 = _T_149 ? regs_6 : _GEN_5;
  assign _GEN_52 = _T_149 ? regs_7 : _GEN_6;
  assign _GEN_53 = _T_149 ? regs_8 : _GEN_7;
  assign _GEN_54 = _T_149 ? regs_9 : _GEN_8;
  assign _GEN_55 = _T_149 ? regs_10 : _GEN_9;
  assign _GEN_56 = _T_149 ? regs_11 : _GEN_10;
  assign _GEN_57 = _T_149 ? regs_12 : _GEN_11;
  assign _GEN_58 = _T_149 ? regs_13 : _GEN_12;
  assign _GEN_59 = _T_149 ? regs_14 : _GEN_13;
  assign _GEN_60 = _T_149 ? regs_15 : _GEN_14;
  assign _GEN_61 = _T_149 ? regs_16 : _GEN_15;
  assign _GEN_62 = _T_149 ? regs_17 : _GEN_16;
  assign _GEN_63 = _T_149 ? regs_18 : _GEN_17;
  assign _GEN_64 = _T_149 ? regs_19 : _GEN_18;
  assign _GEN_65 = _T_149 ? regs_20 : _GEN_19;
  assign _GEN_66 = _T_149 ? regs_21 : _GEN_20;
  assign _GEN_67 = _T_149 ? regs_22 : _GEN_21;
  assign _GEN_68 = _T_149 ? regs_23 : _GEN_22;
  assign _GEN_69 = _T_149 ? regs_24 : _GEN_23;
  assign _GEN_70 = _T_149 ? regs_25 : _GEN_24;
  assign _GEN_71 = _T_149 ? regs_26 : _GEN_25;
  assign _GEN_72 = _T_149 ? regs_27 : _GEN_26;
  assign _GEN_73 = _T_149 ? regs_28 : _GEN_27;
  assign _GEN_74 = _T_149 ? regs_29 : _GEN_28;
  assign _GEN_75 = _T_149 ? regs_30 : _GEN_29;
  assign _GEN_76 = _T_149 ? regs_31 : _GEN_30;
  assign _GEN_77 = _T_149 ? regs_32 : _GEN_31;
  assign _GEN_78 = _T_149 ? regs_33 : _GEN_32;
  assign _GEN_79 = _T_149 ? regs_34 : _GEN_33;
  assign _GEN_80 = _T_149 ? regs_35 : _GEN_34;
  assign _GEN_81 = _T_149 ? regs_36 : _GEN_35;
  assign _GEN_82 = _T_149 ? regs_37 : _GEN_36;
  assign _GEN_83 = _T_149 ? regs_38 : _GEN_37;
  assign _GEN_84 = _T_149 ? regs_39 : _GEN_38;
  assign _GEN_85 = _T_149 ? regs_40 : _GEN_39;
  assign _GEN_86 = _T_149 ? 1'h0 : _GEN_43;
  assign _GEN_87 = _T_149 ? 1'h0 : _T_141;
  assign _T_158 = io_chainIn_shift == 1'h0;
  assign _T_159 = _T_148 & _T_158;
  assign _GEN_88 = _T_159 ? 1'h0 : _GEN_86;
  assign _GEN_89 = _T_159 ? 1'h0 : _GEN_87;
  assign _T_162 = io_chainIn_capture & io_chainIn_update;
  assign _T_164 = _T_162 == 1'h0;
  assign _T_165 = io_chainIn_capture & io_chainIn_shift;
  assign _T_167 = _T_165 == 1'h0;
  assign _T_168 = _T_164 & _T_167;
  assign _T_169 = io_chainIn_update & io_chainIn_shift;
  assign _T_171 = _T_169 == 1'h0;
  assign _T_172 = _T_168 & _T_171;
  assign _T_173 = _T_172 | reset;
  assign _T_175 = _T_173 == 1'h0;
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifndef verilator
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{$random}};
  regs_0 = _RAND_0[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{$random}};
  regs_1 = _RAND_1[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_2 = {1{$random}};
  regs_2 = _RAND_2[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_3 = {1{$random}};
  regs_3 = _RAND_3[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_4 = {1{$random}};
  regs_4 = _RAND_4[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_5 = {1{$random}};
  regs_5 = _RAND_5[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_6 = {1{$random}};
  regs_6 = _RAND_6[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_7 = {1{$random}};
  regs_7 = _RAND_7[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_8 = {1{$random}};
  regs_8 = _RAND_8[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_9 = {1{$random}};
  regs_9 = _RAND_9[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_10 = {1{$random}};
  regs_10 = _RAND_10[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_11 = {1{$random}};
  regs_11 = _RAND_11[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_12 = {1{$random}};
  regs_12 = _RAND_12[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_13 = {1{$random}};
  regs_13 = _RAND_13[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_14 = {1{$random}};
  regs_14 = _RAND_14[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_15 = {1{$random}};
  regs_15 = _RAND_15[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_16 = {1{$random}};
  regs_16 = _RAND_16[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_17 = {1{$random}};
  regs_17 = _RAND_17[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_18 = {1{$random}};
  regs_18 = _RAND_18[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_19 = {1{$random}};
  regs_19 = _RAND_19[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_20 = {1{$random}};
  regs_20 = _RAND_20[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_21 = {1{$random}};
  regs_21 = _RAND_21[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_22 = {1{$random}};
  regs_22 = _RAND_22[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_23 = {1{$random}};
  regs_23 = _RAND_23[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_24 = {1{$random}};
  regs_24 = _RAND_24[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_25 = {1{$random}};
  regs_25 = _RAND_25[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_26 = {1{$random}};
  regs_26 = _RAND_26[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_27 = {1{$random}};
  regs_27 = _RAND_27[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_28 = {1{$random}};
  regs_28 = _RAND_28[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_29 = {1{$random}};
  regs_29 = _RAND_29[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_30 = {1{$random}};
  regs_30 = _RAND_30[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_31 = {1{$random}};
  regs_31 = _RAND_31[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_32 = {1{$random}};
  regs_32 = _RAND_32[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_33 = {1{$random}};
  regs_33 = _RAND_33[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_34 = {1{$random}};
  regs_34 = _RAND_34[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_35 = {1{$random}};
  regs_35 = _RAND_35[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_36 = {1{$random}};
  regs_36 = _RAND_36[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_37 = {1{$random}};
  regs_37 = _RAND_37[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_38 = {1{$random}};
  regs_38 = _RAND_38[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_39 = {1{$random}};
  regs_39 = _RAND_39[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_40 = {1{$random}};
  regs_40 = _RAND_40[0:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (_T_149) begin
      regs_0 <= regs_1;
    end else begin
      if (io_chainIn_capture) begin
        regs_0 <= _T_96;
      end
    end
    if (_T_149) begin
      regs_1 <= regs_2;
    end else begin
      if (io_chainIn_capture) begin
        regs_1 <= _T_97;
      end
    end
    if (_T_149) begin
      regs_2 <= regs_3;
    end else begin
      if (io_chainIn_capture) begin
        regs_2 <= _T_98;
      end
    end
    if (_T_149) begin
      regs_3 <= regs_4;
    end else begin
      if (io_chainIn_capture) begin
        regs_3 <= _T_99;
      end
    end
    if (_T_149) begin
      regs_4 <= regs_5;
    end else begin
      if (io_chainIn_capture) begin
        regs_4 <= _T_100;
      end
    end
    if (_T_149) begin
      regs_5 <= regs_6;
    end else begin
      if (io_chainIn_capture) begin
        regs_5 <= _T_101;
      end
    end
    if (_T_149) begin
      regs_6 <= regs_7;
    end else begin
      if (io_chainIn_capture) begin
        regs_6 <= _T_102;
      end
    end
    if (_T_149) begin
      regs_7 <= regs_8;
    end else begin
      if (io_chainIn_capture) begin
        regs_7 <= _T_103;
      end
    end
    if (_T_149) begin
      regs_8 <= regs_9;
    end else begin
      if (io_chainIn_capture) begin
        regs_8 <= _T_104;
      end
    end
    if (_T_149) begin
      regs_9 <= regs_10;
    end else begin
      if (io_chainIn_capture) begin
        regs_9 <= _T_105;
      end
    end
    if (_T_149) begin
      regs_10 <= regs_11;
    end else begin
      if (io_chainIn_capture) begin
        regs_10 <= _T_106;
      end
    end
    if (_T_149) begin
      regs_11 <= regs_12;
    end else begin
      if (io_chainIn_capture) begin
        regs_11 <= _T_107;
      end
    end
    if (_T_149) begin
      regs_12 <= regs_13;
    end else begin
      if (io_chainIn_capture) begin
        regs_12 <= _T_108;
      end
    end
    if (_T_149) begin
      regs_13 <= regs_14;
    end else begin
      if (io_chainIn_capture) begin
        regs_13 <= _T_109;
      end
    end
    if (_T_149) begin
      regs_14 <= regs_15;
    end else begin
      if (io_chainIn_capture) begin
        regs_14 <= _T_110;
      end
    end
    if (_T_149) begin
      regs_15 <= regs_16;
    end else begin
      if (io_chainIn_capture) begin
        regs_15 <= _T_111;
      end
    end
    if (_T_149) begin
      regs_16 <= regs_17;
    end else begin
      if (io_chainIn_capture) begin
        regs_16 <= _T_112;
      end
    end
    if (_T_149) begin
      regs_17 <= regs_18;
    end else begin
      if (io_chainIn_capture) begin
        regs_17 <= _T_113;
      end
    end
    if (_T_149) begin
      regs_18 <= regs_19;
    end else begin
      if (io_chainIn_capture) begin
        regs_18 <= _T_114;
      end
    end
    if (_T_149) begin
      regs_19 <= regs_20;
    end else begin
      if (io_chainIn_capture) begin
        regs_19 <= _T_115;
      end
    end
    if (_T_149) begin
      regs_20 <= regs_21;
    end else begin
      if (io_chainIn_capture) begin
        regs_20 <= _T_116;
      end
    end
    if (_T_149) begin
      regs_21 <= regs_22;
    end else begin
      if (io_chainIn_capture) begin
        regs_21 <= _T_117;
      end
    end
    if (_T_149) begin
      regs_22 <= regs_23;
    end else begin
      if (io_chainIn_capture) begin
        regs_22 <= _T_118;
      end
    end
    if (_T_149) begin
      regs_23 <= regs_24;
    end else begin
      if (io_chainIn_capture) begin
        regs_23 <= _T_119;
      end
    end
    if (_T_149) begin
      regs_24 <= regs_25;
    end else begin
      if (io_chainIn_capture) begin
        regs_24 <= _T_120;
      end
    end
    if (_T_149) begin
      regs_25 <= regs_26;
    end else begin
      if (io_chainIn_capture) begin
        regs_25 <= _T_121;
      end
    end
    if (_T_149) begin
      regs_26 <= regs_27;
    end else begin
      if (io_chainIn_capture) begin
        regs_26 <= _T_122;
      end
    end
    if (_T_149) begin
      regs_27 <= regs_28;
    end else begin
      if (io_chainIn_capture) begin
        regs_27 <= _T_123;
      end
    end
    if (_T_149) begin
      regs_28 <= regs_29;
    end else begin
      if (io_chainIn_capture) begin
        regs_28 <= _T_124;
      end
    end
    if (_T_149) begin
      regs_29 <= regs_30;
    end else begin
      if (io_chainIn_capture) begin
        regs_29 <= _T_125;
      end
    end
    if (_T_149) begin
      regs_30 <= regs_31;
    end else begin
      if (io_chainIn_capture) begin
        regs_30 <= _T_126;
      end
    end
    if (_T_149) begin
      regs_31 <= regs_32;
    end else begin
      if (io_chainIn_capture) begin
        regs_31 <= _T_127;
      end
    end
    if (_T_149) begin
      regs_32 <= regs_33;
    end else begin
      if (io_chainIn_capture) begin
        regs_32 <= _T_128;
      end
    end
    if (_T_149) begin
      regs_33 <= regs_34;
    end else begin
      if (io_chainIn_capture) begin
        regs_33 <= _T_129;
      end
    end
    if (_T_149) begin
      regs_34 <= regs_35;
    end else begin
      if (io_chainIn_capture) begin
        regs_34 <= _T_130;
      end
    end
    if (_T_149) begin
      regs_35 <= regs_36;
    end else begin
      if (io_chainIn_capture) begin
        regs_35 <= _T_131;
      end
    end
    if (_T_149) begin
      regs_36 <= regs_37;
    end else begin
      if (io_chainIn_capture) begin
        regs_36 <= _T_132;
      end
    end
    if (_T_149) begin
      regs_37 <= regs_38;
    end else begin
      if (io_chainIn_capture) begin
        regs_37 <= _T_133;
      end
    end
    if (_T_149) begin
      regs_38 <= regs_39;
    end else begin
      if (io_chainIn_capture) begin
        regs_38 <= _T_134;
      end
    end
    if (_T_149) begin
      regs_39 <= regs_40;
    end else begin
      if (io_chainIn_capture) begin
        regs_39 <= _T_135;
      end
    end
    if (_T_149) begin
      regs_40 <= io_chainIn_data;
    end else begin
      if (io_chainIn_capture) begin
        regs_40 <= _T_136;
      end
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_175) begin
          $fwrite(32'h80000001,"Assertion failed\n    at JtagShifter.scala:174 assert(!(io.chainIn.capture && io.chainIn.update)\n");
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_175) begin
          $fatal;
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
endmodule
module CaptureChain(
  input         clock,
  input         reset,
  input         io_chainIn_shift,
  input         io_chainIn_data,
  input         io_chainIn_capture,
  input         io_chainIn_update,
  output        io_chainOut_data,
  input  [3:0]  io_capture_bits_version,
  input  [15:0] io_capture_bits_partNumber,
  input  [10:0] io_capture_bits_mfrId,
  input         io_capture_bits_always1
);
  reg  regs_0;
  reg [31:0] _RAND_0;
  reg  regs_1;
  reg [31:0] _RAND_1;
  reg  regs_2;
  reg [31:0] _RAND_2;
  reg  regs_3;
  reg [31:0] _RAND_3;
  reg  regs_4;
  reg [31:0] _RAND_4;
  reg  regs_5;
  reg [31:0] _RAND_5;
  reg  regs_6;
  reg [31:0] _RAND_6;
  reg  regs_7;
  reg [31:0] _RAND_7;
  reg  regs_8;
  reg [31:0] _RAND_8;
  reg  regs_9;
  reg [31:0] _RAND_9;
  reg  regs_10;
  reg [31:0] _RAND_10;
  reg  regs_11;
  reg [31:0] _RAND_11;
  reg  regs_12;
  reg [31:0] _RAND_12;
  reg  regs_13;
  reg [31:0] _RAND_13;
  reg  regs_14;
  reg [31:0] _RAND_14;
  reg  regs_15;
  reg [31:0] _RAND_15;
  reg  regs_16;
  reg [31:0] _RAND_16;
  reg  regs_17;
  reg [31:0] _RAND_17;
  reg  regs_18;
  reg [31:0] _RAND_18;
  reg  regs_19;
  reg [31:0] _RAND_19;
  reg  regs_20;
  reg [31:0] _RAND_20;
  reg  regs_21;
  reg [31:0] _RAND_21;
  reg  regs_22;
  reg [31:0] _RAND_22;
  reg  regs_23;
  reg [31:0] _RAND_23;
  reg  regs_24;
  reg [31:0] _RAND_24;
  reg  regs_25;
  reg [31:0] _RAND_25;
  reg  regs_26;
  reg [31:0] _RAND_26;
  reg  regs_27;
  reg [31:0] _RAND_27;
  reg  regs_28;
  reg [31:0] _RAND_28;
  reg  regs_29;
  reg [31:0] _RAND_29;
  reg  regs_30;
  reg [31:0] _RAND_30;
  reg  regs_31;
  reg [31:0] _RAND_31;
  wire [11:0] _T_37;
  wire [19:0] _T_38;
  wire [31:0] _T_39;
  wire  _T_40;
  wire  _T_44;
  wire  _T_48;
  wire  _T_52;
  wire  _T_56;
  wire  _T_60;
  wire  _T_64;
  wire  _T_68;
  wire  _T_72;
  wire  _T_76;
  wire  _T_80;
  wire  _T_84;
  wire  _T_88;
  wire  _T_92;
  wire  _T_96;
  wire  _T_100;
  wire  _T_104;
  wire  _T_108;
  wire  _T_112;
  wire  _T_116;
  wire  _T_120;
  wire  _T_124;
  wire  _T_128;
  wire  _T_132;
  wire  _T_136;
  wire  _T_140;
  wire  _T_144;
  wire  _T_148;
  wire  _T_152;
  wire  _T_156;
  wire  _T_160;
  wire  _T_164;
  wire  _GEN_0;
  wire  _GEN_1;
  wire  _GEN_2;
  wire  _GEN_3;
  wire  _GEN_4;
  wire  _GEN_5;
  wire  _GEN_6;
  wire  _GEN_7;
  wire  _GEN_8;
  wire  _GEN_9;
  wire  _GEN_10;
  wire  _GEN_11;
  wire  _GEN_12;
  wire  _GEN_13;
  wire  _GEN_14;
  wire  _GEN_15;
  wire  _GEN_16;
  wire  _GEN_17;
  wire  _GEN_18;
  wire  _GEN_19;
  wire  _GEN_20;
  wire  _GEN_21;
  wire  _GEN_22;
  wire  _GEN_23;
  wire  _GEN_24;
  wire  _GEN_25;
  wire  _GEN_26;
  wire  _GEN_27;
  wire  _GEN_28;
  wire  _GEN_29;
  wire  _GEN_30;
  wire  _GEN_31;
  wire  _T_167;
  wire  _T_168;
  wire  _GEN_33;
  wire  _GEN_34;
  wire  _GEN_35;
  wire  _GEN_36;
  wire  _GEN_37;
  wire  _GEN_38;
  wire  _GEN_39;
  wire  _GEN_40;
  wire  _GEN_41;
  wire  _GEN_42;
  wire  _GEN_43;
  wire  _GEN_44;
  wire  _GEN_45;
  wire  _GEN_46;
  wire  _GEN_47;
  wire  _GEN_48;
  wire  _GEN_49;
  wire  _GEN_50;
  wire  _GEN_51;
  wire  _GEN_52;
  wire  _GEN_53;
  wire  _GEN_54;
  wire  _GEN_55;
  wire  _GEN_56;
  wire  _GEN_57;
  wire  _GEN_58;
  wire  _GEN_59;
  wire  _GEN_60;
  wire  _GEN_61;
  wire  _GEN_62;
  wire  _GEN_63;
  wire  _GEN_64;
  wire  _T_176;
  wire  _T_178;
  wire  _T_179;
  wire  _T_181;
  wire  _T_182;
  wire  _T_183;
  wire  _T_185;
  wire  _T_186;
  wire  _T_187;
  wire  _T_189;
  assign io_chainOut_data = regs_0;
  assign _T_37 = {io_capture_bits_mfrId,io_capture_bits_always1};
  assign _T_38 = {io_capture_bits_version,io_capture_bits_partNumber};
  assign _T_39 = {_T_38,_T_37};
  assign _T_40 = _T_39[0];
  assign _T_44 = _T_39[1];
  assign _T_48 = _T_39[2];
  assign _T_52 = _T_39[3];
  assign _T_56 = _T_39[4];
  assign _T_60 = _T_39[5];
  assign _T_64 = _T_39[6];
  assign _T_68 = _T_39[7];
  assign _T_72 = _T_39[8];
  assign _T_76 = _T_39[9];
  assign _T_80 = _T_39[10];
  assign _T_84 = _T_39[11];
  assign _T_88 = _T_39[12];
  assign _T_92 = _T_39[13];
  assign _T_96 = _T_39[14];
  assign _T_100 = _T_39[15];
  assign _T_104 = _T_39[16];
  assign _T_108 = _T_39[17];
  assign _T_112 = _T_39[18];
  assign _T_116 = _T_39[19];
  assign _T_120 = _T_39[20];
  assign _T_124 = _T_39[21];
  assign _T_128 = _T_39[22];
  assign _T_132 = _T_39[23];
  assign _T_136 = _T_39[24];
  assign _T_140 = _T_39[25];
  assign _T_144 = _T_39[26];
  assign _T_148 = _T_39[27];
  assign _T_152 = _T_39[28];
  assign _T_156 = _T_39[29];
  assign _T_160 = _T_39[30];
  assign _T_164 = _T_39[31];
  assign _GEN_0 = io_chainIn_capture ? _T_40 : regs_0;
  assign _GEN_1 = io_chainIn_capture ? _T_44 : regs_1;
  assign _GEN_2 = io_chainIn_capture ? _T_48 : regs_2;
  assign _GEN_3 = io_chainIn_capture ? _T_52 : regs_3;
  assign _GEN_4 = io_chainIn_capture ? _T_56 : regs_4;
  assign _GEN_5 = io_chainIn_capture ? _T_60 : regs_5;
  assign _GEN_6 = io_chainIn_capture ? _T_64 : regs_6;
  assign _GEN_7 = io_chainIn_capture ? _T_68 : regs_7;
  assign _GEN_8 = io_chainIn_capture ? _T_72 : regs_8;
  assign _GEN_9 = io_chainIn_capture ? _T_76 : regs_9;
  assign _GEN_10 = io_chainIn_capture ? _T_80 : regs_10;
  assign _GEN_11 = io_chainIn_capture ? _T_84 : regs_11;
  assign _GEN_12 = io_chainIn_capture ? _T_88 : regs_12;
  assign _GEN_13 = io_chainIn_capture ? _T_92 : regs_13;
  assign _GEN_14 = io_chainIn_capture ? _T_96 : regs_14;
  assign _GEN_15 = io_chainIn_capture ? _T_100 : regs_15;
  assign _GEN_16 = io_chainIn_capture ? _T_104 : regs_16;
  assign _GEN_17 = io_chainIn_capture ? _T_108 : regs_17;
  assign _GEN_18 = io_chainIn_capture ? _T_112 : regs_18;
  assign _GEN_19 = io_chainIn_capture ? _T_116 : regs_19;
  assign _GEN_20 = io_chainIn_capture ? _T_120 : regs_20;
  assign _GEN_21 = io_chainIn_capture ? _T_124 : regs_21;
  assign _GEN_22 = io_chainIn_capture ? _T_128 : regs_22;
  assign _GEN_23 = io_chainIn_capture ? _T_132 : regs_23;
  assign _GEN_24 = io_chainIn_capture ? _T_136 : regs_24;
  assign _GEN_25 = io_chainIn_capture ? _T_140 : regs_25;
  assign _GEN_26 = io_chainIn_capture ? _T_144 : regs_26;
  assign _GEN_27 = io_chainIn_capture ? _T_148 : regs_27;
  assign _GEN_28 = io_chainIn_capture ? _T_152 : regs_28;
  assign _GEN_29 = io_chainIn_capture ? _T_156 : regs_29;
  assign _GEN_30 = io_chainIn_capture ? _T_160 : regs_30;
  assign _GEN_31 = io_chainIn_capture ? _T_164 : regs_31;
  assign _T_167 = io_chainIn_capture == 1'h0;
  assign _T_168 = _T_167 & io_chainIn_shift;
  assign _GEN_33 = _T_168 ? io_chainIn_data : _GEN_31;
  assign _GEN_34 = _T_168 ? regs_1 : _GEN_0;
  assign _GEN_35 = _T_168 ? regs_2 : _GEN_1;
  assign _GEN_36 = _T_168 ? regs_3 : _GEN_2;
  assign _GEN_37 = _T_168 ? regs_4 : _GEN_3;
  assign _GEN_38 = _T_168 ? regs_5 : _GEN_4;
  assign _GEN_39 = _T_168 ? regs_6 : _GEN_5;
  assign _GEN_40 = _T_168 ? regs_7 : _GEN_6;
  assign _GEN_41 = _T_168 ? regs_8 : _GEN_7;
  assign _GEN_42 = _T_168 ? regs_9 : _GEN_8;
  assign _GEN_43 = _T_168 ? regs_10 : _GEN_9;
  assign _GEN_44 = _T_168 ? regs_11 : _GEN_10;
  assign _GEN_45 = _T_168 ? regs_12 : _GEN_11;
  assign _GEN_46 = _T_168 ? regs_13 : _GEN_12;
  assign _GEN_47 = _T_168 ? regs_14 : _GEN_13;
  assign _GEN_48 = _T_168 ? regs_15 : _GEN_14;
  assign _GEN_49 = _T_168 ? regs_16 : _GEN_15;
  assign _GEN_50 = _T_168 ? regs_17 : _GEN_16;
  assign _GEN_51 = _T_168 ? regs_18 : _GEN_17;
  assign _GEN_52 = _T_168 ? regs_19 : _GEN_18;
  assign _GEN_53 = _T_168 ? regs_20 : _GEN_19;
  assign _GEN_54 = _T_168 ? regs_21 : _GEN_20;
  assign _GEN_55 = _T_168 ? regs_22 : _GEN_21;
  assign _GEN_56 = _T_168 ? regs_23 : _GEN_22;
  assign _GEN_57 = _T_168 ? regs_24 : _GEN_23;
  assign _GEN_58 = _T_168 ? regs_25 : _GEN_24;
  assign _GEN_59 = _T_168 ? regs_26 : _GEN_25;
  assign _GEN_60 = _T_168 ? regs_27 : _GEN_26;
  assign _GEN_61 = _T_168 ? regs_28 : _GEN_27;
  assign _GEN_62 = _T_168 ? regs_29 : _GEN_28;
  assign _GEN_63 = _T_168 ? regs_30 : _GEN_29;
  assign _GEN_64 = _T_168 ? regs_31 : _GEN_30;
  assign _T_176 = io_chainIn_capture & io_chainIn_update;
  assign _T_178 = _T_176 == 1'h0;
  assign _T_179 = io_chainIn_capture & io_chainIn_shift;
  assign _T_181 = _T_179 == 1'h0;
  assign _T_182 = _T_178 & _T_181;
  assign _T_183 = io_chainIn_update & io_chainIn_shift;
  assign _T_185 = _T_183 == 1'h0;
  assign _T_186 = _T_182 & _T_185;
  assign _T_187 = _T_186 | reset;
  assign _T_189 = _T_187 == 1'h0;
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifndef verilator
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{$random}};
  regs_0 = _RAND_0[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{$random}};
  regs_1 = _RAND_1[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_2 = {1{$random}};
  regs_2 = _RAND_2[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_3 = {1{$random}};
  regs_3 = _RAND_3[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_4 = {1{$random}};
  regs_4 = _RAND_4[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_5 = {1{$random}};
  regs_5 = _RAND_5[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_6 = {1{$random}};
  regs_6 = _RAND_6[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_7 = {1{$random}};
  regs_7 = _RAND_7[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_8 = {1{$random}};
  regs_8 = _RAND_8[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_9 = {1{$random}};
  regs_9 = _RAND_9[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_10 = {1{$random}};
  regs_10 = _RAND_10[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_11 = {1{$random}};
  regs_11 = _RAND_11[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_12 = {1{$random}};
  regs_12 = _RAND_12[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_13 = {1{$random}};
  regs_13 = _RAND_13[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_14 = {1{$random}};
  regs_14 = _RAND_14[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_15 = {1{$random}};
  regs_15 = _RAND_15[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_16 = {1{$random}};
  regs_16 = _RAND_16[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_17 = {1{$random}};
  regs_17 = _RAND_17[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_18 = {1{$random}};
  regs_18 = _RAND_18[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_19 = {1{$random}};
  regs_19 = _RAND_19[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_20 = {1{$random}};
  regs_20 = _RAND_20[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_21 = {1{$random}};
  regs_21 = _RAND_21[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_22 = {1{$random}};
  regs_22 = _RAND_22[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_23 = {1{$random}};
  regs_23 = _RAND_23[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_24 = {1{$random}};
  regs_24 = _RAND_24[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_25 = {1{$random}};
  regs_25 = _RAND_25[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_26 = {1{$random}};
  regs_26 = _RAND_26[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_27 = {1{$random}};
  regs_27 = _RAND_27[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_28 = {1{$random}};
  regs_28 = _RAND_28[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_29 = {1{$random}};
  regs_29 = _RAND_29[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_30 = {1{$random}};
  regs_30 = _RAND_30[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_31 = {1{$random}};
  regs_31 = _RAND_31[0:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (_T_168) begin
      regs_0 <= regs_1;
    end else begin
      if (io_chainIn_capture) begin
        regs_0 <= _T_40;
      end
    end
    if (_T_168) begin
      regs_1 <= regs_2;
    end else begin
      if (io_chainIn_capture) begin
        regs_1 <= _T_44;
      end
    end
    if (_T_168) begin
      regs_2 <= regs_3;
    end else begin
      if (io_chainIn_capture) begin
        regs_2 <= _T_48;
      end
    end
    if (_T_168) begin
      regs_3 <= regs_4;
    end else begin
      if (io_chainIn_capture) begin
        regs_3 <= _T_52;
      end
    end
    if (_T_168) begin
      regs_4 <= regs_5;
    end else begin
      if (io_chainIn_capture) begin
        regs_4 <= _T_56;
      end
    end
    if (_T_168) begin
      regs_5 <= regs_6;
    end else begin
      if (io_chainIn_capture) begin
        regs_5 <= _T_60;
      end
    end
    if (_T_168) begin
      regs_6 <= regs_7;
    end else begin
      if (io_chainIn_capture) begin
        regs_6 <= _T_64;
      end
    end
    if (_T_168) begin
      regs_7 <= regs_8;
    end else begin
      if (io_chainIn_capture) begin
        regs_7 <= _T_68;
      end
    end
    if (_T_168) begin
      regs_8 <= regs_9;
    end else begin
      if (io_chainIn_capture) begin
        regs_8 <= _T_72;
      end
    end
    if (_T_168) begin
      regs_9 <= regs_10;
    end else begin
      if (io_chainIn_capture) begin
        regs_9 <= _T_76;
      end
    end
    if (_T_168) begin
      regs_10 <= regs_11;
    end else begin
      if (io_chainIn_capture) begin
        regs_10 <= _T_80;
      end
    end
    if (_T_168) begin
      regs_11 <= regs_12;
    end else begin
      if (io_chainIn_capture) begin
        regs_11 <= _T_84;
      end
    end
    if (_T_168) begin
      regs_12 <= regs_13;
    end else begin
      if (io_chainIn_capture) begin
        regs_12 <= _T_88;
      end
    end
    if (_T_168) begin
      regs_13 <= regs_14;
    end else begin
      if (io_chainIn_capture) begin
        regs_13 <= _T_92;
      end
    end
    if (_T_168) begin
      regs_14 <= regs_15;
    end else begin
      if (io_chainIn_capture) begin
        regs_14 <= _T_96;
      end
    end
    if (_T_168) begin
      regs_15 <= regs_16;
    end else begin
      if (io_chainIn_capture) begin
        regs_15 <= _T_100;
      end
    end
    if (_T_168) begin
      regs_16 <= regs_17;
    end else begin
      if (io_chainIn_capture) begin
        regs_16 <= _T_104;
      end
    end
    if (_T_168) begin
      regs_17 <= regs_18;
    end else begin
      if (io_chainIn_capture) begin
        regs_17 <= _T_108;
      end
    end
    if (_T_168) begin
      regs_18 <= regs_19;
    end else begin
      if (io_chainIn_capture) begin
        regs_18 <= _T_112;
      end
    end
    if (_T_168) begin
      regs_19 <= regs_20;
    end else begin
      if (io_chainIn_capture) begin
        regs_19 <= _T_116;
      end
    end
    if (_T_168) begin
      regs_20 <= regs_21;
    end else begin
      if (io_chainIn_capture) begin
        regs_20 <= _T_120;
      end
    end
    if (_T_168) begin
      regs_21 <= regs_22;
    end else begin
      if (io_chainIn_capture) begin
        regs_21 <= _T_124;
      end
    end
    if (_T_168) begin
      regs_22 <= regs_23;
    end else begin
      if (io_chainIn_capture) begin
        regs_22 <= _T_128;
      end
    end
    if (_T_168) begin
      regs_23 <= regs_24;
    end else begin
      if (io_chainIn_capture) begin
        regs_23 <= _T_132;
      end
    end
    if (_T_168) begin
      regs_24 <= regs_25;
    end else begin
      if (io_chainIn_capture) begin
        regs_24 <= _T_136;
      end
    end
    if (_T_168) begin
      regs_25 <= regs_26;
    end else begin
      if (io_chainIn_capture) begin
        regs_25 <= _T_140;
      end
    end
    if (_T_168) begin
      regs_26 <= regs_27;
    end else begin
      if (io_chainIn_capture) begin
        regs_26 <= _T_144;
      end
    end
    if (_T_168) begin
      regs_27 <= regs_28;
    end else begin
      if (io_chainIn_capture) begin
        regs_27 <= _T_148;
      end
    end
    if (_T_168) begin
      regs_28 <= regs_29;
    end else begin
      if (io_chainIn_capture) begin
        regs_28 <= _T_152;
      end
    end
    if (_T_168) begin
      regs_29 <= regs_30;
    end else begin
      if (io_chainIn_capture) begin
        regs_29 <= _T_156;
      end
    end
    if (_T_168) begin
      regs_30 <= regs_31;
    end else begin
      if (io_chainIn_capture) begin
        regs_30 <= _T_160;
      end
    end
    if (_T_168) begin
      regs_31 <= io_chainIn_data;
    end else begin
      if (io_chainIn_capture) begin
        regs_31 <= _T_164;
      end
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_189) begin
          $fwrite(32'h80000001,"Assertion failed\n    at JtagShifter.scala:111 assert(!(io.chainIn.capture && io.chainIn.update)\n");
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_189) begin
          $fatal;
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
endmodule
module JtagBypassChain(
  input   clock,
  input   reset,
  input   io_chainIn_shift,
  input   io_chainIn_data,
  input   io_chainIn_capture,
  input   io_chainIn_update,
  output  io_chainOut_data
);
  reg  reg$;
  reg [31:0] _RAND_0;
  wire  _GEN_0;
  wire  _T_7;
  wire  _T_8;
  wire  _GEN_1;
  wire  _T_9;
  wire  _T_11;
  wire  _T_12;
  wire  _T_14;
  wire  _T_15;
  wire  _T_16;
  wire  _T_18;
  wire  _T_19;
  wire  _T_20;
  wire  _T_22;
  assign io_chainOut_data = reg$;
  assign _GEN_0 = io_chainIn_capture ? 1'h0 : reg$;
  assign _T_7 = io_chainIn_capture == 1'h0;
  assign _T_8 = _T_7 & io_chainIn_shift;
  assign _GEN_1 = _T_8 ? io_chainIn_data : _GEN_0;
  assign _T_9 = io_chainIn_capture & io_chainIn_update;
  assign _T_11 = _T_9 == 1'h0;
  assign _T_12 = io_chainIn_capture & io_chainIn_shift;
  assign _T_14 = _T_12 == 1'h0;
  assign _T_15 = _T_11 & _T_14;
  assign _T_16 = io_chainIn_update & io_chainIn_shift;
  assign _T_18 = _T_16 == 1'h0;
  assign _T_19 = _T_15 & _T_18;
  assign _T_20 = _T_19 | reset;
  assign _T_22 = _T_20 == 1'h0;
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifndef verilator
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{$random}};
  reg$ = _RAND_0[0:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (_T_8) begin
      reg$ <= io_chainIn_data;
    end else begin
      if (io_chainIn_capture) begin
        reg$ <= 1'h0;
      end
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_22) begin
          $fwrite(32'h80000001,"Assertion failed\n    at JtagShifter.scala:68 assert(!(io.chainIn.capture && io.chainIn.update)\n");
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_22) begin
          $fatal;
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
endmodule
