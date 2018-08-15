export TOP=$PWD
export RISCV=$TOP/riscv
export PATH=/opt/Xilinx/SDK/2018.1/bin:/opt/Xilinx/Vivado/2018.1/bin:/opt/Xilinx/DocNav:/usr/local/bin:/usr/bin:/bin:$RISCV/bin
export FPGA_BOARD=nexys4_ddr
export XILINX_VIVADO=/opt/Xilinx/Vivado/2018.1
export JAVA_HOME=/usr/lib/jvm/java-8-oracle

Checkout:
	git submodule update --init --recursive

Build:
	cd rocket-chip/riscv-tools; bash ./build.sh
	make -C fpga/board/nexys4_ddr bitstream

Test:
	echo Test

Deploy:
	echo Deploy
