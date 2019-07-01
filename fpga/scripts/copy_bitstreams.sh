#!/bin/sh
cd `dirname $0`
cd ../work-fpga
echo $PWD
cp ../../riscv-pk/serial/bbl ~/Downloads/boot.bin
cp ../../linux-5.1.3-lowrisc/initramfs.cpio ../../rootfs.tar.xz ~/Downloads
for i in `find . -name \*.bit`; do cp -p $i ~/Downloads/`echo $i|sed -e 's=./==' -e 's=/[a-z]*\(_xilinx\)=\1='`;done
for i in `find . -name \*.mcs`; do cp -p $i ~/Downloads/`echo $i|sed -e 's=./==' -e 's=/[a-z]*\(_xilinx\)=\1='`;done
