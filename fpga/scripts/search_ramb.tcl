# See LICENSE.Cambridge for license details.
# script to search for Block RAMs to be updated with new bare metal software

set origin_dir "."
set project_name [lindex $argv 0]

# open checkpoint
open_checkpoint $project_name.dcp

# search for all RAMB blocks
foreach m [get_cells i_ariane_peripherals/i_bootram/ram_reg_*] { put $m; report_property $m {LOC} }
