Checkout:
	git clone -b refresh-v0.6 --recursive https://github.com/lowrisc/lowrisc-chip.git lowrisc-chip-refresh-v0.6

Build:
	cd lowrisc-chip-refresh-v0.6/rocket-chip/riscv-tools; bash ./build.sh
	cd lowrisc-chip-refresh-v0.6; source /opt/Xilinx/Vivado/2018.1/settings64.sh; source set_env.sh; make -C fpga/board/nexys4_ddr bitstream

Test:
	echo Test

Deploy:
	echo Deploy
