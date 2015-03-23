#!/bin/bash
# source this file
echo "Setting up RISC-V environment..."
# Variables for RISC-V
if [ "$TOP" == "" ]; then
    echo "\$TOP is not available. So set it to the current directory $PWD."
    export TOP=$PWD
fi
export RISCV=$TOP/riscv
export PATH=$PATH:$RISCV/bin
