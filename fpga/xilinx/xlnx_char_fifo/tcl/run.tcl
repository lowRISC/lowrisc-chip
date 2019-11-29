set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

set ipName xlnx_char_fifo

create_project $ipName $::env(BOARD) -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name $ipName

set_property -dict [list CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
                        CONFIG.Performance_Options {Standard_FIFO} \
                        CONFIG.Input_Data_Width {9} \
                        CONFIG.Input_Depth {16} \
                        CONFIG.Output_Data_Width {9} \
                        CONFIG.Output_Depth {16} \
                        CONFIG.Reset_Type {Synchronous_Reset} \
                        CONFIG.Full_Flags_Reset_Value {0} \
                        CONFIG.Use_Extra_Logic {false} \
                        CONFIG.Data_Count_Width {4} \
                        CONFIG.Write_Data_Count_Width {4} \
                        CONFIG.Read_Data_Count_Width {4} \
                        CONFIG.Full_Threshold_Assert_Value {14} \
                        CONFIG.Full_Threshold_Negate_Value {13} \
                        CONFIG.Empty_Threshold_Assert_Value {2} \
                        CONFIG.Empty_Threshold_Negate_Value {3} \
                        CONFIG.Enable_Safety_Circuit {false}] [get_ips $ipName]

generate_target {instantiation_template} [get_files $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] $::env(BOARD)/$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
