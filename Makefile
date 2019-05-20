include sources.inc

REMOTE=lowrisc5.sm
LINUX=linux-5.1.3-lowrisc

default: nexys4_ddr_ariane

all: nexys4_ddr_ariane nexys4_ddr_rocket genesys2_ariane genesys2_rocket

tftp: riscv-pk/build/bbl
	(cd riscv-pk/build; echo -e bin \\n put $< \\n | tftp $(REMOTE))

riscv-pk/build/bbl: $(LINUX)/vmlinux
	mkdir -p riscv-pk/build
	(cd riscv-pk/build; ../configure --host=riscv64-unknown-elf --enable-print-device-tree --with-payload=../../$(LINUX)/vmlinux 'CC=riscv64-unknown-elf-gcc -g'; make)

$(LINUX)/vmlinux: $(LINUX)/.config $(LINUX)/initramfs.cpio
	make -C $(LINUX) ARCH=riscv CROSS_COMPILE=riscv64-unknown-elf- -j 4 # V=1 KBUILD_CFLAGS=-v

$(LINUX)/.config: $(LINUX)/drivers/net/ethernet/Makefile
	make -C $(LINUX) ARCH=riscv CROSS_COMPILE=riscv64-unknown-elf- defconfig

$(LINUX)/initramfs.cpio:
	make -C debian-riscv64 cpio

$(LINUX)/drivers/net/ethernet/Makefile: linux-5.1.3.patch
	curl https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.1.3.tar.xz|tar xJf -
	patch -d linux-5.1.3 -p1 < linux-5.1.3.patch
	mv linux-5.1.3 $(LINUX)

fpga/src/etherboot/$(BOARD).sv: fpga/src/$(BOARD).dts
	make -C fpga/src/etherboot BOARD=$(BOARD)

fpga/work-fpga/$(BOARD)_ariane/ariane_xilinx.bit: $(ariane_pkg) $(util) $(src) $(fpga_src) \
        fpga/src/etherboot/$(BOARD).sv
	@echo "[FPGA] Generate source list"
	@echo read_verilog -sv { $(ariane_pkg) $(filter-out $(fpga_filter), $(util) $(src)) $(fpga_src) $(open_src) $(addprefix $(root-dir)/,fpga/src/etherboot/$(BOARD).sv) } > fpga/scripts/add_sources.tcl
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

genesys2_ariane_new:
	make -C fpga BOARD=genesys2 CPU=ariane new

nexys4_ddr_rocket_new:
	make -C fpga BOARD=nexys4_ddr CPU=rocket new
