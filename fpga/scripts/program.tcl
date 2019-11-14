# Copyright 2018 ETH Zurich and University of Bologna.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
# Description: Program Genesys II

open_hw

connect_hw_server -url localhost:3121
set board ""
set device $::env(JTAG_PART)
puts $device
set bit $::env(JTAG_BITFILE)
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
set_property PROGRAM.FILE $bit [current_hw_device]
program_hw_devices [current_hw_device]
disconnect_hw_server
