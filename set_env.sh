#!/bin/bash
# source this file
echo "Setting up lowRISC/RISC-V and SoC Debug SoC environment..."
echo "Make sure you source this script at the top of lowrisc-chip."
echo

# Variables for lowRISC/RISC-V
if [ -z $TOP ] || [ ! -d $TOP ]; then
    echo "\$TOP is not defined or does not point to a directory. Set \$TOP to the top of lowrisc-chip which is the current directory."
    export TOP=$PWD
fi

if [ -z $RISCV ]; then
    echo "\$RISCV is not defined. Set \$TOP/riscv to the RISC-V toolchain installation target (\$RISCV)."
    export RISCV=$TOP/riscv
fi

export PATH=$PATH:$RISCV/bin

# Variables for Open SoC Debug
if [ -z $OSD_ROOT ]; then
    echo "\$OSD_ROOT is not defined."
    echo "Set \$TOP/tools to the Open SoC Debug installation target (\$OSD_ROOT)."
    export OSD_ROOT=$TOP/tools
fi

echo "Add opensocdebug to \$PYTHONPATH"
export PYTHONPATH=$OSD_ROOT/lib/python2.7/site-packages:$PYTHONPATH

if [ -z $LD_LIBRARY_PATH ]; then
  export LD_LIBRARY_PATH=$OSD_ROOT/lib
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOP/riscv/lib
else
  export LD_LIBRARY_PATH=$OSD_ROOT/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOP/riscv/lib
fi

export PATH=$OSD_ROOT/bin:$PATH

if [ -z $PKG_CONFIG_PATH ]; then
  export PKG_CONFIG_PATH=$OSD_ROOT/lib/pkgconfig
else
  export PKG_CONFIG_PATH=$OSD_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH
fi

# choose the FPGA board (Nexys4-DDR in default)
if [ -z $FPGA_BOARD ]; then
    echo "\$FPGA_BOARD is not defined. Set the target FPGA board to nexys4_ddr."
    export FPGA_BOARD=nexys4_ddr
fi

echo "============================"
echo "    export TOP=$TOP"
echo "    export RISCV=$RISCV"
echo "    export OSD_ROOT=$OSD_ROOT"
echo "    export PYTHONPATH=$PYTHONPATH"
echo "    export PATH=$PATH"
echo "    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
echo "    export FPGA_BOARD=$FPGA_BOARD"
echo "============================"
