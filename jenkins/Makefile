#This should be customized per site
export XILINXD_LICENSE_FILE=27020@lmserv-xilinx.cl.cam.ac.uk
export XILINX_PATH=/opt/Xilinx
export XILINX_VER=2018.1
export XILINX_VIVADO=$(XILINX_PATH)/Vivado/$(XILINX_VER)
#This should be customised per branch
export BRANCH=kc705_mii
export FPGA_BOARD=kc705
#This should be OK as is
export TOP=$(PWD)
export RISCV=$(TOP)/riscv
export PATH=$(XILINX_PATH)/SDK/$(XILINX_VER)/bin:$(XILINX_VIVADO)/bin:$(XILINX_PATH)/DocNav:/usr/local/bin:/usr/bin:/bin:$(RISCV)/bin
export JAVA_HOME=/usr/lib/jvm/java-8-oracle

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
