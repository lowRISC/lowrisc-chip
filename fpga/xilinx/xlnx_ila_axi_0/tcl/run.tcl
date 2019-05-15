set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

set ipName xlnx_ila_axi_0

create_project $ipName $::env(BOARD) -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name ila -vendor xilinx.com -library ip -module_name $ipName
set_property -dict [list CONFIG.C_NUM_OF_PROBES {44} \
                        CONFIG.C_EN_STRG_QUAL {1} \
                        CONFIG.C_INPUT_PIPE_STAGES {1} \
                        CONFIG.C_ADV_TRIGGER {false} \
                        CONFIG.C_DATA_DEPTH {1024} \
                        CONFIG.C_TRIGOUT_EN {true} \
                        CONFIG.C_TRIGIN_EN {true} \
                        CONFIG.C_SLOT_0_AXI_ID_WIDTH {5} \
                        CONFIG.C_SLOT_0_AXI_DATA_WIDTH {64} \
                        CONFIG.C_SLOT_0_AXI_ADDR_WIDTH {64} \
                        CONFIG.C_ENABLE_ILA_AXI_MON {true} \
                        CONFIG.C_MONITOR_TYPE {AXI}] [get_ips $ipName]

generate_target {instantiation_template} [get_files $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
