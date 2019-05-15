set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

set ipName xlnx_ila_plic

create_project $ipName $::env(BOARD) -force -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name ila -vendor xilinx.com -library ip -module_name $ipName
set_property -dict [list  CONFIG.C_NUM_OF_PROBES {23} \
                          CONFIG.C_PROBE0_WIDTH {2} \
                          CONFIG.C_PROBE1_WIDTH {3} \
                          CONFIG.C_PROBE2_WIDTH {3} \
                          CONFIG.C_PROBE3_WIDTH {3} \
                          CONFIG.C_PROBE4_WIDTH {3} \
                          CONFIG.C_PROBE5_WIDTH {3} \
                          CONFIG.C_PROBE6_WIDTH {1} \
                          CONFIG.C_PROBE7_WIDTH {3} \
                          CONFIG.C_PROBE8_WIDTH {3} \
                          CONFIG.C_PROBE9_WIDTH {3} \
                          CONFIG.C_PROBE10_WIDTH {3} \
                          CONFIG.C_PROBE11_WIDTH {3} \
                          CONFIG.C_PROBE12_WIDTH {2} \
                          CONFIG.C_PROBE13_WIDTH {2} \
                          CONFIG.C_PROBE14_WIDTH {2} \
                          CONFIG.C_PROBE15_WIDTH {3} \
                          CONFIG.C_PROBE21_WIDTH {3} \
                          CONFIG.C_PROBE22_WIDTH {3} \
                          CONFIG.C_DATA_DEPTH {1024}  \
                          CONFIG.C_INPUT_PIPE_STAGES {1} \
                    ] [get_ips $ipName]


generate_target {instantiation_template} [get_files $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
