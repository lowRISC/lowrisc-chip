# See LICENSE.Cambridge for license details.
# script to burn configuration memory into the quad-SPI memory

# Xilinx Vivado script
# Version: Vivado 2018.1
# Function:
#   Download bitstream to QSPI

open_hw

connect_hw_server -url localhost:3121
set board ""
set device $::env(JTAG_PART)
set mcs $::env(JTAG_MCSFILE)
set memory $::env(JTAG_MEMORY)
puts "CFGMEM: $mcs"
puts "DEVICE: $device"
puts "MEMORY: $memory"

foreach { target } [get_hw_targets] {
    current_hw_target $target
    open_hw_target
    set devices [get_hw_devices]
    puts $device
    if { $devices == $device } {
        set board [current_hw_target]
        break
    } else {
        puts [format "%s %s" ignoring $devices]
    }
    close_hw_target
}
if { $board == "" } {
    puts "Did not find board"
    exit 1
}
current_hw_device $device

refresh_hw_device -update_hw_probes false $device
create_hw_cfgmem -hw_device $device -mem_dev  [lindex [get_cfgmem_parts $memory] 0]
set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
refresh_hw_device $device
set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.FILES [list $mcs] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
startgroup 
if {![string equal [get_property PROGRAM.HW_CFGMEM_TYPE  [lindex [get_hw_devices] 0 ]] [get_property MEM_TYPE [get_property CFGMEM_PART [get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]]]] }  { create_hw_bitstream -hw_device [lindex [get_hw_devices] 0 ] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices] 0]]; program_hw_devices [lindex [get_hw_devices] 0 ]; }; 
program_hw_cfgmem -hw_cfgmem [get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0 ]]
endgroup
