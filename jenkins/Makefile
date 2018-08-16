export TOP=$(PWD)
export RISCV=$(TOP)/riscv
export PATH=/opt/Xilinx/SDK/2018.1/bin:/opt/Xilinx/Vivado/2018.1/bin:/opt/Xilinx/DocNav:/usr/local/bin:/usr/bin:/bin:$(RISCV)/bin
export FPGA_BOARD=kc705
export XILINX_VIVADO=/opt/Xilinx/Vivado/2018.1
export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export BRANCH=kc705_mii

Checkout:
	git submodule update --init --recursive

Build: $(RISCV)/bin/spike
	make -C fpga/board/$(FPGA_BOARD) bitstream

Test:
	echo Test

Deploy:
	echo Deploy
	rsync fpga/board/$(FPGA_BOARD)/lowrisc-chip-imp/lowrisc-chip-imp.runs/impl_1/chip_top.bit brexit:(BRANCH)/lowrisc-fpga/common/script

Debug:
	echo Debug
	bash -i

$(RISCV)/bin/spike: rocket-chip/riscv-tools/build.sh
	cd rocket-chip/riscv-tools; bash ./build.sh
