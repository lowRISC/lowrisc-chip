.SUFFIXES:

include sources.inc

REMOTE=lowrisc5.sm
LINUX=linux-5.1.3-lowrisc
MD5=$(shell md5sum riscv-pk/build/bbl | cut -d\  -f1)
KERNEL=riscv-pk/build/bbl
export RISCV=/opt/riscv

default: nexys4_ddr_ariane

all: nexys4_ddr_ariane nexys4_ddr_rocket genesys2_ariane genesys2_rocket

tftp: $(KERNEL)
	md5sum $<
	echo -e bin \\n put $< $(MD5) \\n | tftp $(REMOTE)

linux: lowrisc-quickstart/boot.bin
visual: lowrisc-quickstart/visual.bin
rescue: lowrisc-quickstart/rescue.bin
install: lowrisc-quickstart/install.bin

lowrisc-quickstart/boot.bin: $(LINUX)/arch/riscv/configs/defconfig
	sed -e 's/\(CONFIG_BLK_DEV_INITRD\)=y/\1=n/' < $(LINUX)/arch/riscv/configs/defconfig > $(LINUX)/$@.cfg
	make -C $(LINUX) ARCH=riscv KCONFIG_CONFIG=$@.cfg CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf- -j 4
	make -C riscv-pk/build PATH=$(RISCV)/bin:/usr/bin:/bin
	cp -p riscv-pk/build/bbl $@

lowrisc-quickstart/visual.bin: $(LINUX)/arch/riscv/configs/defconfig
	sed -e 's/\(CONFIG_BLK_DEV_INITRD\)=y/\1=n/' -e 's/# \(CONFIG_VT_CONSOLE\) is not set/\1=y/' < $(LINUX)/arch/riscv/configs/defconfig > $(LINUX)/$@.cfg
	make -C $(LINUX) ARCH=riscv KCONFIG_CONFIG=$@.cfg CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf- CONFIG_VT_CONSOLE=y -j 4
	make -C riscv-pk/build PATH=$(RISCV)/bin:/usr/bin:/bin
	cp -p riscv-pk/build/bbl lowrisc-quickstart/$@.bin

lowrisc-quickstart/rescue.bin: $(LINUX)/arch/riscv/configs/defconfig $(LINUX)/initramfs.cpio
	sed -e 's/\(CONFIG_INITRAMFS_SOURCE\)=""/\1="initramfs.cpio"/' < $(LINUX)/arch/riscv/configs/defconfig > $(LINUX)/$@.cfg
	make -C $(LINUX) ARCH=riscv KCONFIG_CONFIG=$@.cfg CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf- -j 4
	make -C riscv-pk/build PATH=$(RISCV)/bin:/usr/bin:/bin
	cp -p riscv-pk/build/bbl $@

lowrisc-quickstart/install.bin: $(LINUX)/arch/riscv/configs/defconfig $(LINUX)/debian.cpio
	sed -e 's/\(CONFIG_INITRAMFS_SOURCE\)=""/\1="debian.cpio"/' < $(LINUX)/arch/riscv/configs/defconfig > $(LINUX)/$@.cfg
	make -C $(LINUX) ARCH=riscv KCONFIG_CONFIG=$@.cfg CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf- -j 4
	make -C riscv-pk/build PATH=$(RISCV)/bin:/usr/bin:/bin
	cp -p riscv-pk/build/bbl $@

$(LINUX)/debian.cpio:
	curl http://cdn-fastly.deb.debian.org/debian-ports/pool-riscv64/main/d/debian-installer/debian-installer-images_20190410_riscv64.tar.gz | tar xzf -
	gzip -d < installer-riscv64/20190410/images/netboot/initrd.gz > $(LINUX)/debian.cpio
	rm -rf installer-riscv64

$(LINUX)/initramfs.cpio:
	make -C debian-riscv64 ../linux-5.1.3-lowrisc/initramfs.cpio

riscv-pk/build/bbl: $(LINUX)/drivers/net/ethernet/Makefile $(LINUX)/vmlinux riscv-pk/build/Makefile
	make -C riscv-pk/build PATH=$(RISCV)/bin:/usr/bin:/bin

riscv-pk/build/Makefile:
	mkdir -p riscv-pk/build
	cd riscv-pk/build; env PATH=$(RISCV)/bin:/usr/bin:/bin ../configure --host=riscv64-unknown-elf --enable-print-device-tree --with-payload=../../$(LINUX)/vmlinux

$(LINUX)/vmlinux: $(LINUX)/.config
	make -C $(LINUX) ARCH=riscv CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf- -j 4

$(LINUX)/.config:
	make -C $(LINUX) defconfig ARCH=riscv CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf-

#We don't want to download the entire revision history of Linux, but we do want to track any changes we make
#So we do it this way ...

$(LINUX)/arch/riscv/configs/defconfig: linux-5.1.3.patch
	rm -rf linux-5.1.3
	curl https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.1.3.tar.xz|tar xJf -
	(cd linux-5.1.3; git init; git checkout -b linux-5.1.3; git add .; git commit -a -m linux-5.1.3; git status)
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

nexys4_ddr_ariane: $(KERNEL)
	make fpga/work-fpga/nexys4_ddr_ariane/ariane_xilinx.bit BOARD=nexys4_ddr CPU="ariane" BITSIZE=0x400000 XILINX_PART=xc7a100tcsg324-1 XILINX_BOARD="digilentinc.com:nexys4_ddr:part0:1.1" COMPATIBLE="ethz, ariane" BBL=$(root-dir)$< |& tee nexys4_ddr_ariane.log

nexys4_ddr_rocket: $(KERNEL)
	make fpga/work-fpga/nexys4_ddr_rocket/rocket_xilinx.bit BOARD="nexys4_ddr" CPU="rocket" BITSIZE=0x400000 XILINX_PART="xc7a100tcsg324-1" XILINX_BOARD="digilentinc.com:nexys4_ddr:part0:1.1" COMPATIBLE="sifive,rocket0" BBL=$(root-dir)$< |& tee nexys4_ddr_rocket.log

nexys_video_ariane: $(KERNEL)
	make fpga/work-fpga/nexys4_video_ariane/ariane_xilinx.bit BOARD="nexys_video" CPU="ariane" BITSIZE=0x800000 XILINX_PART="xc7a200tsbg484-1" XILINX_BOARD="digilentinc.com:nexys_video:part0:1.1" COMPATIBLE="ethz, ariane" BBL=$(root-dir)$< |& tee nexys_video_ariane.log

nexys_video_rocket: $(KERNEL)
	make fpga/work-fpga/nexys4_video_rocket/rocket_xilinx.bit BOARD="nexys_video" CPU="rocket" BITSIZE=0x800000 XILINX_PART="xc7a200tsbg484-1" XILINX_BOARD="digilentinc.com:nexys_video:part0:1.1" COMPATIBLE="sifive,rocket0" BBL=$(root-dir)$< |& tee nexys_video_rocket.log

genesys2_ariane: $(KERNEL)
	make fpga/work-fpga/genesys2_ariane/ariane_xilinx.bit BOARD="genesys2" CPU="ariane" BITSIZE=0xB00000 XILINX_PART="xc7k325tffg900-2" XILINX_BOARD="digilentinc.com:genesys2:part0:1.1" COMPATIBLE="ethz, ariane" BBL=$(root-dir)$< |& tee genesys2_ariane.log

genesys2_rocket: $(KERNEL)
	make fpga/work-fpga/genesys2_rocket/rocket_xilinx.bit BOARD="genesys2" CPU="rocket" BITSIZE=0xB00000 XILINX_PART="xc7k325tffg900-2" XILINX_BOARD="digilentinc.com:genesys2:part0:1.1" COMPATIBLE="sifive,rocket0" BBL=$(root-dir)$< |& tee genesys2_rocket.log

$(rocket_src): rocket-chip/vsim/Makefile
	make -C rocket-chip/vsim verilog

rocket-chip/vsim/Makefile:
	git submodule update --init --recursive rocket-chip

genesys2_ariane_new: $(KERNEL)
	make -C fpga BOARD=genesys2 BITSIZE=0xB00000 CPU=ariane COMPATIBLE="ethz, ariane" BBL=$(root-dir)$< new newmcs

genesys2_rocket_new: $(KERNEL)
	make -C fpga BOARD=genesys2 BITSIZE=0xB00000 CPU=rocket COMPATIBLE="sifive,rocket0" BBL=$(root-dir)$< new newmcs

nexys4_ddr_ariane_new: $(KERNEL)
	make -C fpga BOARD=nexys4_ddr BITSIZE=0x400000 CPU=ariane COMPATIBLE="ethz, ariane" BBL=$(root-dir)$< new newmcs

nexys4_ddr_rocket_new: $(KERNEL)
	make -C fpga BOARD=nexys4_ddr BITSIZE=0x400000 CPU=rocket COMPATIBLE="sifive,rocket0" BBL=$(root-dir)$< new newmcs

sdcard-install: $(KERNEL) lowrisc-quickstart/rootfs.tar.xz
	cp $< lowrisc-quickstart/boot.bin
	make -C lowrisc-quickstart/ install USB=$(USB)

lowrisc-quickstart/rootfs.tar.xz:
	make -C debian-riscv64 image
