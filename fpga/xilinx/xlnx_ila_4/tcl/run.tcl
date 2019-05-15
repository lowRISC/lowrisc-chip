set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

set ipName xlnx_ila_4

create_project $ipName $::env(BOARD) -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name ila -vendor xilinx.com -library ip -module_name $ipName
set_property -dict [list \
                        CONFIG.C_PROBE0_WIDTH {64} \
                        CONFIG.C_PROBE1_WIDTH {64} \
                        CONFIG.C_PROBE2_WIDTH {64} \
                        CONFIG.C_PROBE3_WIDTH {3} \
                        CONFIG.C_PROBE4_WIDTH {4} \
                        CONFIG.C_PROBE5_WIDTH {3} \
                        CONFIG.C_PROBE6_WIDTH {1} \
                        CONFIG.C_PROBE7_WIDTH {3} \
                        CONFIG.C_PROBE8_WIDTH {5} \
                        CONFIG.C_PROBE9_WIDTH {64} \
                        CONFIG.C_PROBE10_WIDTH {1} \
                        CONFIG.C_PROBE11_WIDTH {5} \
                        CONFIG.C_PROBE12_WIDTH {1} \
                        CONFIG.C_PROBE13_WIDTH {7} \
                        CONFIG.C_PROBE14_WIDTH {7} \
                        CONFIG.C_PROBE15_WIDTH {3} \
                        CONFIG.C_DATA_DEPTH {1024} \
                        CONFIG.C_NUM_OF_PROBES {16} \
                        CONFIG.C_ADV_TRIGGER {true} \
                        CONFIG.C_TRIGOUT_EN {false} \
                        CONFIG.C_TRIGIN_EN {true} \
                        CONFIG.C_INPUT_PIPE_STAGES {0}] [get_ips $ipName]

generate_target {instantiation_template} [get_files $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
