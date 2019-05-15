set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

set ipName xlnx_ila_sd

create_project $ipName $::env(BOARD) -force -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name ila -vendor xilinx.com -library ip -module_name $ipName
set_property -dict [list  CONFIG.C_NUM_OF_PROBES {90} \
                          CONFIG.C_PROBE2_WIDTH {1} \
                          CONFIG.C_PROBE3_WIDTH {1} \
                          CONFIG.C_PROBE5_WIDTH {32} \
                          CONFIG.C_PROBE6_WIDTH {32} \
                          CONFIG.C_PROBE7_WIDTH {64} \
                          CONFIG.C_PROBE8_WIDTH {64} \
                          CONFIG.C_PROBE9_WIDTH {8} \
                          CONFIG.C_PROBE11_WIDTH {2} \
                          CONFIG.C_PROBE12_WIDTH {2} \
                          CONFIG.C_PROBE13_WIDTH {16} \
                          CONFIG.C_PROBE14_WIDTH {16} \
                          CONFIG.C_PROBE15_WIDTH {12} \
                          CONFIG.C_PROBE16_WIDTH {12} \
                          CONFIG.C_PROBE17_WIDTH {7} \
                          CONFIG.C_PROBE20_WIDTH {16} \
                          CONFIG.C_PROBE21_WIDTH {16} \
                          CONFIG.C_PROBE26_WIDTH {32} \
                          CONFIG.C_PROBE27_WIDTH {32} \
                          CONFIG.C_PROBE29_WIDTH {7} \
                          CONFIG.C_PROBE30_WIDTH {6} \
                          CONFIG.C_PROBE32_WIDTH {6} \
                          CONFIG.C_PROBE34_WIDTH {48} \
                          CONFIG.C_PROBE35_WIDTH {48} \
                          CONFIG.C_PROBE36_WIDTH {134} \
                          CONFIG.C_PROBE37_WIDTH {134} \
                          CONFIG.C_PROBE38_WIDTH {32} \
                          CONFIG.C_PROBE40_WIDTH {3} \
                          CONFIG.C_PROBE41_WIDTH {3} \
                          CONFIG.C_PROBE44_WIDTH {32} \
                          CONFIG.C_PROBE45_WIDTH {32} \
                          CONFIG.C_PROBE48_WIDTH {32} \
                          CONFIG.C_PROBE49_WIDTH {32} \
                          CONFIG.C_PROBE50_WIDTH {4} \
                          CONFIG.C_PROBE53_WIDTH {3} \
                          CONFIG.C_PROBE54_WIDTH {3} \
                          CONFIG.C_PROBE55_WIDTH {32} \
                          CONFIG.C_PROBE56_WIDTH {32} \
                          CONFIG.C_PROBE58_WIDTH {4} \
                          CONFIG.C_PROBE59_WIDTH {4} \
                          CONFIG.C_PROBE60_WIDTH {4} \
                          CONFIG.C_PROBE63_WIDTH {4} \
                          CONFIG.C_PROBE64_WIDTH {4} \
                          CONFIG.C_PROBE66_WIDTH {32} \
                          CONFIG.C_PROBE67_WIDTH {32} \
                          CONFIG.C_PROBE68_WIDTH {16} \
                          CONFIG.C_PROBE69_WIDTH {16} \
                          CONFIG.C_PROBE70_WIDTH {10} \
                          CONFIG.C_PROBE72_WIDTH {16} \
                          CONFIG.C_PROBE74_WIDTH {8} \
                          CONFIG.C_PROBE75_WIDTH {64} \
                          CONFIG.C_PROBE76_WIDTH {64} \
                          CONFIG.C_PROBE77_WIDTH {32} \
                          CONFIG.C_DATA_DEPTH {1024}  \
                          CONFIG.C_INPUT_PIPE_STAGES {1} \
                    ] [get_ips $ipName]


generate_target {instantiation_template} [get_files $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
