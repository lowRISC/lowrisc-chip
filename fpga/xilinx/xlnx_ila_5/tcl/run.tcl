set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

set ipName xlnx_ila_5

create_project $ipName $::env(BOARD) -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name ila -vendor xilinx.com -library ip -module_name $ipName
set_property -dict [list \
                        CONFIG.C_PROBE0_WIDTH {1} \
                        CONFIG.C_PROBE1_WIDTH {1} \
                        CONFIG.C_PROBE2_WIDTH {1} \
                        CONFIG.C_PROBE3_WIDTH {32} \
                        CONFIG.C_PROBE4_WIDTH {1} \
                        CONFIG.C_PROBE5_WIDTH {1} \
                        CONFIG.C_PROBE6_WIDTH {1} \
                        CONFIG.C_PROBE7_WIDTH {2} \
                        CONFIG.C_PROBE8_WIDTH {5} \
                        CONFIG.C_PROBE9_WIDTH {5} \
                        CONFIG.C_PROBE10_WIDTH {64} \
                        CONFIG.C_PROBE11_WIDTH {64} \
                        CONFIG.C_PROBE12_WIDTH {1} \
                        CONFIG.C_PROBE13_WIDTH {1} \
                        CONFIG.C_PROBE14_WIDTH {1} \
                        CONFIG.C_PROBE15_WIDTH {1} \
                        CONFIG.C_PROBE16_WIDTH {2} \
                        CONFIG.C_PROBE17_WIDTH {1} \
                        CONFIG.C_PROBE18_WIDTH {64} \
                        CONFIG.C_PROBE19_WIDTH {1} \
                        CONFIG.C_PROBE20_WIDTH {1} \
                        CONFIG.C_PROBE21_WIDTH {64} \
                        CONFIG.C_PROBE22_WIDTH {2} \
                        CONFIG.C_PROBE11_WIDTH {64} \
                        CONFIG.C_PROBE12_WIDTH {1} \
                        CONFIG.C_PROBE13_WIDTH {1} \
                        CONFIG.C_PROBE14_WIDTH {1} \
                        CONFIG.C_PROBE15_WIDTH {1} \
                        CONFIG.C_PROBE16_WIDTH {2} \
                        CONFIG.C_PROBE17_WIDTH {1} \
                        CONFIG.C_PROBE18_WIDTH {64} \
                        CONFIG.C_PROBE19_WIDTH {1} \
                        CONFIG.C_PROBE20_WIDTH {1} \
                        CONFIG.C_PROBE21_WIDTH {64} \
                        CONFIG.C_PROBE11_WIDTH {64} \
                        CONFIG.C_PROBE12_WIDTH {1} \
                        CONFIG.C_PROBE13_WIDTH {1} \
                        CONFIG.C_PROBE14_WIDTH {1} \
                        CONFIG.C_PROBE15_WIDTH {1} \
                        CONFIG.C_PROBE16_WIDTH {2} \
                        CONFIG.C_PROBE17_WIDTH {1} \
                        CONFIG.C_PROBE18_WIDTH {64} \
                        CONFIG.C_PROBE19_WIDTH {1} \
                        CONFIG.C_PROBE20_WIDTH {1} \
                        CONFIG.C_PROBE21_WIDTH {64} \
                        CONFIG.C_PROBE22_WIDTH {2} \
                        CONFIG.C_PROBE23_WIDTH {1} \
                        CONFIG.C_PROBE24_WIDTH {1} \
                        CONFIG.C_PROBE25_WIDTH {64} \
                        CONFIG.C_PROBE26_WIDTH {64} \
                        CONFIG.C_PROBE27_WIDTH {64} \
                        CONFIG.C_PROBE28_WIDTH {1} \
                        CONFIG.C_PROBE29_WIDTH {64} \
                        CONFIG.C_PROBE30_WIDTH {64} \
                        CONFIG.C_PROBE31_WIDTH {64} \
                        CONFIG.C_PROBE31_WIDTH {64} \
                        CONFIG.C_PROBE32_WIDTH {64} \
                        CONFIG.C_PROBE33_WIDTH {3} \
                        CONFIG.C_PROBE34_WIDTH {4} \
                        CONFIG.C_PROBE35_WIDTH {7} \
                        CONFIG.C_PROBE36_WIDTH {6} \
                        CONFIG.C_PROBE37_WIDTH {6} \
                        CONFIG.C_PROBE38_WIDTH {6} \
                        CONFIG.C_PROBE39_WIDTH {64} \
                        CONFIG.C_PROBE40_WIDTH {1} \
                        CONFIG.C_PROBE41_WIDTH {1} \
                        CONFIG.C_PROBE42_WIDTH {1} \
                        CONFIG.C_PROBE43_WIDTH {1} \
                        CONFIG.C_PROBE44_WIDTH {64} \
                        CONFIG.C_PROBE45_WIDTH {64} \
                        CONFIG.C_PROBE46_WIDTH {1} \
                        CONFIG.C_PROBE47_WIDTH {68} \
                        CONFIG.C_PROBE48_WIDTH {1} \
                        CONFIG.C_PROBE49_WIDTH {64} \
                        CONFIG.C_PROBE50_WIDTH {64} \
                        CONFIG.C_PROBE51_WIDTH {1} \
                        CONFIG.C_PROBE52_WIDTH {1} \
                        CONFIG.C_PROBE53_WIDTH {1} \
                        CONFIG.C_PROBE54_WIDTH {1} \
                        CONFIG.C_PROBE55_WIDTH {2} \
                        CONFIG.C_PROBE56_WIDTH {64} \
                        CONFIG.C_PROBE57_WIDTH {64} \
                        CONFIG.C_PROBE58_WIDTH {1} \
                        CONFIG.C_DATA_DEPTH {1024} \
                        CONFIG.C_NUM_OF_PROBES {59} \
                        CONFIG.C_ADV_TRIGGER {false} \
                        CONFIG.C_TRIGOUT_EN {false} \
                        CONFIG.C_TRIGIN_EN {false} \
                        CONFIG.C_INPUT_PIPE_STAGES {0}] [get_ips $ipName]

generate_target {instantiation_template} [get_files $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
