riscv-pk/build/bbl: linux/vmlinux
	mkdir riscv-pk/build
	(cd riscv-pk/build; ../configure --host=riscv64-unknown-elf --enable-print-device-tree --with-payload=../../linux/vmlinux 'CC=riscv64-unknown-elf-gcc -g'; make)

linux/vmlinux: linux/.config linux/initramfs.cpio
	make -C linux ARCH=riscv CROSS_COMPILE=riscv64-unknown-elf-

linux/.config:
	make -C linux ARCH=riscv CROSS_COMPILE=riscv64-unknown-elf- defconfig

linux/initramfs.cpio:
	make -C debian-riscv64 cpio
