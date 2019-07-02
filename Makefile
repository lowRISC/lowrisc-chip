.SUFFIXES:
.PHONY: riscv-pk/vt/vmlinux-vt riscv-pk/serial/vmlinux-serial

include sources.inc

REMOTE=lowrisc5.sm
LINUX=linux-5.1.3-lowrisc
MD5SERIAL=$(shell md5sum riscv-pk/serial/bbl | cut -d\  -f1)
MD5VT=$(shell md5sum riscv-pk/vt/bbl | cut -d\  -f1)
export RISCV=/opt/riscv

default: nexys4_ddr_ariane

all: nexys4_ddr_ariane nexys4_ddr_rocket genesys2_ariane genesys2_rocket

tftp_serial: riscv-pk/serial/bbl
	md5sum $<
	echo -e bin \\n put $< $(MD5SERIAL) \\n | tftp $(REMOTE)

tftp_vt: riscv-pk/vt/bbl
	md5sum $<
	echo -e bin \\n put $< $(MD5VT) \\n | tftp $(REMOTE)

linux_serial: riscv-pk/serial/bbl

riscv-pk/serial/bbl: $(LINUX)/drivers/net/ethernet/Makefile $(LINUX)/initramfs.cpio riscv-pk/serial/vmlinux-serial riscv-pk/serial/Makefile
	make -C riscv-pk/serial PATH=$(RISCV)/bin:/usr/bin:/bin

riscv-pk/serial/Makefile:
	mkdir -p riscv-pk/serial
	cd riscv-pk/serial; env PATH=$(RISCV)/bin:/usr/bin:/bin ../configure --host=riscv64-unknown-elf --enable-print-device-tree --with-payload=vmlinux-serial

riscv-pk/vt/Makefile:
	mkdir -p riscv-pk/vt
	cd riscv-pk/vt; env PATH=$(RISCV)/bin:/usr/bin:/bin ../configure --host=riscv64-unknown-elf --enable-print-device-tree --with-payload=vmlinux-vt

linux_vt: riscv-pk/vt/bbl

riscv-pk/vt/bbl: $(LINUX)/drivers/net/ethernet/Makefile $(LINUX)/initramfs.cpio riscv-pk/vt/vmlinux-vt 
	make -C riscv-pk/vt PATH=$(RISCV)/bin:/usr/bin:/bin

riscv-pk/vt/vmlinux-vt: riscv-pk/vt/Makefile $(LINUX)/.config
	make -C $(LINUX) ARCH=riscv CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf- CONFIG_SERIAL_8250_CONSOLE=n CONFIG_VT_CONSOLE=y CONFIG_LOWRISC_VGA_CONSOLE=y -j 4
	mv $(LINUX)/vmlinux $@

riscv-pk/serial/vmlinux-serial: riscv-pk/serial/Makefile $(LINUX)/.config
	make -C $(LINUX) ARCH=riscv CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf- CONFIG_SERIAL_8250_CONSOLE=y CONFIG_VT_CONSOLE=n CONFIG_LOWRISC_VGA_CONSOLE=n -j 4
	mv $(LINUX)/vmlinux $@

$(LINUX)/.config: $(LINUX)/arch/riscv/configs/defconfig
	make -C $(LINUX) defconfig ARCH=riscv CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf-

$(LINUX)/initramfs.cpio:
	make -C debian-riscv64 cpio

#We don't want to download the entire revision history of Linux, but we do want to track any changes we make
#So we do it this way ...

$(LINUX)/drivers/net/ethernet/Makefile: linux-5.1.3.patch
	rm -rf linux-5.1.3
	curl https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.1.3.tar.xz|tar xJf -
	(cd linux-5.1.3; git init; git add .; git commit -a -m linux-5.1.3; git status)
	patch -d linux-5.1.3 -p1 < linux-5.1.3.patch
	mkdir -p $(LINUX)
	mv -f $(LINUX) $(LINUX).`date -I`
	mv linux-5.1.3 $(LINUX)
	(cd $(LINUX); git checkout -b $(LINUX); git add .; git commit -a -m $(LINUX); git status)

fpga/src/etherboot/$(BOARD)_$(CPU).sv: fpga/src/$(BOARD).dts
	make -C fpga/src/etherboot BOARD=$(BOARD) CPU=$(CPU) PATH=$(RISCV)/bin:/usr/local/bin:/usr/bin:/bin

fpga/work-fpga/$(BOARD)_ariane/ariane_xilinx.bit: $(ariane_pkg) $(util) $(src) $(fpga_src) \
        fpga/src/etherboot/$(BOARD)_$(CPU).sv
	@echo "[FPGA] Generate source list"
	@echo read_verilog -sv { $(ariane_pkg) $(filter-out $(fpga_filter), $(util) $(src)) $(fpga_src) $(open_src) $(addprefix $(root-dir)/,fpga/src/etherboot/$(BOARD)_$(CPU).sv) } > fpga/scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	make -C fpga BOARD=$(BOARD) BITSIZE=$(BITSIZE) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CPU=$(CPU) CLK_PERIOD_NS="20"

fpga/work-fpga/$(BOARD)_rocket/rocket_xilinx.bit: $(ariane_pkg) $(util) $(src) $(fpga_src) \
	$(rocket_src) fpga/src/etherboot/$(BOARD)_$(CPU).sv
	@echo "[FPGA] Generate source list"
	@echo read_verilog -sv { $(ariane_pkg) $(filter-out $(fpga_filter), $(util) $(src)) $(fpga_src) $(open_src) $(rocket_src) $(addprefix $(root-dir)/,fpga/src/etherboot/$(BOARD)_$(CPU).sv) } > fpga/scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	make -C fpga BOARD=$(BOARD) BITSIZE=$(BITSIZE) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CPU=$(CPU) CLK_PERIOD_NS="20"

nexys4_ddr_ariane: riscv-pk/serial/bbl
	make fpga/work-fpga/nexys4_ddr_ariane/ariane_xilinx.bit BOARD=nexys4_ddr CPU="ariane" BITSIZE=0x400000 XILINX_PART=xc7a100tcsg324-1 XILINX_BOARD="digilentinc.com:nexys4_ddr:part0:1.1" COMPATIBLE="ethz, ariane" BBL=$(root-dir)$< |& tee nexys4_ddr_ariane.log

nexys4_ddr_rocket: riscv-pk/serial/bbl
	make fpga/work-fpga/nexys4_ddr_rocket/rocket_xilinx.bit BOARD="nexys4_ddr" CPU="rocket" BITSIZE=0x400000 XILINX_PART="xc7a100tcsg324-1" XILINX_BOARD="digilentinc.com:nexys4_ddr:part0:1.1" COMPATIBLE="sifive,rocket0" BBL=$(root-dir)$< |& tee nexys4_ddr_rocket.log

nexys_video_ariane: riscv-pk/serial/bbl
	make fpga/work-fpga/nexys4_video_ariane/ariane_xilinx.bit BOARD="nexys_video" CPU="ariane" BITSIZE=0x800000 XILINX_PART="xc7a200tsbg484-1" XILINX_BOARD="digilentinc.com:nexys_video:part0:1.1" COMPATIBLE="ethz, ariane" BBL=$(root-dir)$< |& tee nexys_video_ariane.log

nexys_video_rocket: riscv-pk/serial/bbl
	make fpga/work-fpga/nexys4_video_rocket/rocket_xilinx.bit BOARD="nexys_video" CPU="rocket" BITSIZE=0x800000 XILINX_PART="xc7a200tsbg484-1" XILINX_BOARD="digilentinc.com:nexys_video:part0:1.1" COMPATIBLE="sifive,rocket0" BBL=$(root-dir)$< |& tee nexys_video_rocket.log

genesys2_ariane: riscv-pk/serial/bbl
	make fpga/work-fpga/genesys2_ariane/ariane_xilinx.bit BOARD="genesys2" CPU="ariane" BITSIZE=0xB00000 XILINX_PART="xc7k325tffg900-2" XILINX_BOARD="digilentinc.com:genesys2:part0:1.1" COMPATIBLE="ethz, ariane" BBL=$(root-dir)$< |& tee genesys2_ariane.log

genesys2_rocket: riscv-pk/serial/bbl
	make fpga/work-fpga/genesys2_rocket/rocket_xilinx.bit BOARD="genesys2" CPU="rocket" BITSIZE=0xB00000 XILINX_PART="xc7k325tffg900-2" XILINX_BOARD="digilentinc.com:genesys2:part0:1.1" COMPATIBLE="sifive,rocket0" BBL=$(root-dir)$< |& tee genesys2_rocket.log

$(rocket_src): rocket-chip/vsim/Makefile
	make -C rocket-chip/vsim verilog

rocket-chip/vsim/Makefile:
	git submodule update --init --recursive rocket-chip

genesys2_ariane_new: riscv-pk/serial/bbl
	make -C fpga BOARD=genesys2 BITSIZE=0xB00000 CPU=ariane COMPATIBLE="ethz, ariane" BBL=$(root-dir)$< new newmcs

genesys2_rocket_new: riscv-pk/serial/bbl
	make -C fpga BOARD=genesys2 BITSIZE=0xB00000 CPU=rocket COMPATIBLE="sifive,rocket0" BBL=$(root-dir)$< new newmcs

nexys4_ddr_ariane_new: riscv-pk/serial/bbl
	make -C fpga BOARD=nexys4_ddr BITSIZE=0x400000 CPU=ariane COMPATIBLE="ethz, ariane" BBL=$(root-dir)$< new newmcs

nexys4_ddr_rocket_new: riscv-pk/serial/bbl
	make -C fpga BOARD=nexys4_ddr BITSIZE=0x400000 CPU=rocket COMPATIBLE="sifive,rocket0" BBL=$(root-dir)$< new newmcs
