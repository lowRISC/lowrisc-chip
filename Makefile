include sources.inc

REMOTE=lowrisc5.sm

tftp: riscv-pk/build/bbl
	(cd riscv-pk/build; echo -e bin \\n put $< \\n | tftp $(REMOTE))

riscv-pk/build/bbl: linux/vmlinux
	mkdir -p riscv-pk/build
	(cd riscv-pk/build; ../configure --host=riscv64-unknown-elf --enable-print-device-tree --with-payload=../../linux/vmlinux 'CC=riscv64-unknown-elf-gcc -g'; make)

linux/vmlinux: linux/.config linux/initramfs.cpio
	make -C linux ARCH=riscv CROSS_COMPILE=riscv64-unknown-elf-

linux/.config:
	make -C linux ARCH=riscv CROSS_COMPILE=riscv64-unknown-elf- defconfig

linux/initramfs.cpio:
	make -C debian-riscv64 cpio

fpga/src/etherboot/$(BOARD).sv: fpga/src/$(BOARD).dts
	make -C fpga/src/etherboot BOARD=$(BOARD)

fpga/work-fpga/$(BOARD)_ariane/ariane_xilinx.bit: $(ariane_pkg) $(util) $(src) $(fpga_src) \
        fpga/src/etherboot/$(BOARD).sv
	@echo "[FPGA] Generate source list"
	@echo read_verilog -sv { $(ariane_pkg) $(filter-out $(fpga_filter), $(util) $(src)) $(fpga_src) $(open_src) fpga/src/etherboot/$(BOARD).sv $(addprefix $(root-dir)/,fpga/src/etherboot/$(BOARD).sv) } > fpga/scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	make -C fpga BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CPU="ariane" CLK_PERIOD_NS="20"

fpga/work-fpga/$(BOARD)_rocket/ariane_xilinx.bit: $(ariane_pkg) $(util) $(src) $(fpga_src) \
	$(rocket_src) fpga/src/etherboot/$(BOARD).sv
	@echo "[FPGA] Generate source list"
	@echo read_verilog -sv { $(ariane_pkg) $(filter-out $(fpga_filter), $(util) $(src)) $(fpga_src) $(open_src) $(rocket_src) $(addprefix $(root-dir)/,fpga/src/etherboot/$(BOARD).sv) } > fpga/scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	make -C fpga BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CPU="rocket" CLK_PERIOD_NS="20"

nexys4_ddr_ariane:
	make fpga/work-fpga/nexys4_ddr_ariane/ariane_xilinx.bit BOARD="nexys4_ddr" XILINX_PART="xc7a100tcsg324-1" XILINX_BOARD="digilentinc.com:nexys4_ddr:part0:1.1"

nexys4_ddr_rocket:
	make fpga/work-fpga/nexys4_ddr_rocket/ariane_xilinx.bit BOARD="nexys4_ddr" XILINX_PART="xc7a100tcsg324-1" XILINX_BOARD="digilentinc.com:nexys4_ddr:part0:1.1"

nexys_video_ariane:
	make fpga/work-fpga/nexys4_video_ariane/ariane_xilinx.bit BOARD="nexys_video" XILINX_PART="xc7a200tsbg484-1" XILINX_BOARD="digilentinc.com:nexys_video:part0:1.1"

nexys_video_rocket:
	make fpga/work-fpga/nexys4_video_rocket/ariane_xilinx.bit BOARD="nexys_video" XILINX_PART="xc7a200tsbg484-1" XILINX_BOARD="digilentinc.com:nexys_video:part0:1.1"

genesys2_ariane:
	make fpga/work-fpga/genesys2_ariane/ariane_xilinx.bit BOARD="genesys2" XILINX_PART="xc7k325tffg900-2" XILINX_BOARD="digilentinc.com:genesys2:part0:1.1" CLK_PERIOD_NS="20"

genesys2_rocket:
	make fpga/work-fpga/genesys2_rocket/ariane_xilinx.bit BOARD="genesys2" XILINX_PART="xc7k325tffg900-2" XILINX_BOARD="digilentinc.com:genesys2:part0:1.1" CLK_PERIOD_NS="20"

$(rocket_src): rocket-chip/vsim/Makefile
	make -C rocket-chip/vsim verilog

rocket-chip/vsim/Makefile:
	git submodule update --init --recursive rocket-chip
