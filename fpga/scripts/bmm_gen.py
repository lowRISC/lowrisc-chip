# See LICENSE.Cambridge for license details.
# script to search for block RAMs to update

import sys
import re

# check arguments
if len(sys.argv) != 5:
    print("Wrong arguments\nbmm_gen in out bus-width mem-size")
    exit()

# read the ramb search result
f = open(sys.argv[1], "r")
lines = f.readlines()
f.close()

rams = []

for i, line in enumerate(lines):
    ram_match = re.match(r"i_ariane_peripherals/i_bootram/ram_reg_(\d+)", line)
    if ram_match:
        loc_match = re.match(r"LOC[\w\s]+RAMB(\d+)_X(\d+)Y(\d+)", lines[i+2])
	if loc_match:
            rams.append((int(ram_match.group(1)), loc_match.group(2), loc_match.group(3)))

# get the bit-width of each
if int(sys.argv[3]) % len(rams) != 0:
    print("Cannot divide memory bus evenly into BRAMs!")
    exit()

DW = int(sys.argv[3]) / len(rams)
MS = "%#010x"%(int(sys.argv[4]) - 1)

rams = sorted(rams, key=lambda r: r[0], reverse=True)

f = open(sys.argv[2], "w")
f.write('ADDRESS_SPACE BOOTRAM RAMB32 [0x00000000:{0}]\n'.format(MS))
f.write("  BUS_BLOCK\n")
for r in rams:
    f.write('    ram_reg_{0} [{1}:{2}] LOC = X{3}Y{4};\n'.format(r[0], r[0]*DW+DW-1, r[0]*DW, r[1], r[2]))
f.write("  END_BUS_BLOCK;\n")
f.write("END_ADDRESS_SPACE;\n")
f.close()
