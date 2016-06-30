#!/bin/bash
# source this file
echo "Setting up lowRISC/RISC-V and SoC Debug SoC environment..."
echo "Make sure you source this script at the top of lowrisc-chip."

# Variables for lowRISC/RISC-V
if [ -d $TOP ]; then
    echo "\$TOP is not defined."
    echo "Set \$TOP to the top of lowrisc-chip which is the current directory."
    export TOP=$PWD
fi

if [ -z $RISCV ]; then
    echo "\$RISCV is not defined."
    echo "Set \$TOP/riscv to the RISC-V toolchain installation target (\$RISCV)."
    export RISCV=$TOP/riscv
fi

export PATH=$PATH:$RISCV/bin

# Variables for Open SoC Debug
if [ -z $OSD_ROOT ]; then
    echo "\$OSD_ROOT is not defined."
    echo "Set \$TOP/tools to the Open SoC Debug installation target (\$OSD_ROOT)."
    export OSD_ROOT=$TOP/tools
fi

if [ -z $LD_LIBRARY_PATH ]; then export LD_LIBRARY_PATH=$OSD_ROOT/lib
else export LD_LIBRARY_PATH=$OSD_ROOT/lib:$LD_LIBRARY_PATH; fi

export PATH=$OSD_ROOT/bin:$PATH

if [ -z $PKG_CONFIG_PATH ]; then export PKG_CONFIG_PATH=$OSD_ROOT/lib/pkgconfig
else export PKG_CONFIG_PATH=$OSD_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH; fi

# choose the FPGA board (Nexys4-DDR in default)
if [ -z $FPGA_BOARD ]; then
    echo "\$FPGA_BOARD is not defined."
    echo "Set the target FPGA board to nexys4_ddr."
    export FPGA_BOARD=nexys4_ddr
fi

