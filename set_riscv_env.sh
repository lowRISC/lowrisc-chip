#!/bin/bash
# source this file
echo "Setting up lowRISC/RISC-V environment..."
echo "Make sure you source this script at the top of lowrisc-chip."
# Variables for lowRISC/RISC-V
if [ "$TOP" == "" ]; then
    echo "\$TOP is not available."
    echo "Set \$TOP to the top of lowrisc-chip which is the current directory."
    export TOP=$PWD
fi
export RISCV=$TOP/riscv
export PATH=$PATH:$RISCV/bin
# choose the FPGA board (KC705 in default)
export FPGA_BOARD=kc705
