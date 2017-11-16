bootrom_img = bootrom.img

CC=riscv64-unknown-elf-gcc
CFLAGS=-Wno-multichar -O3 -fno-caller-saves -fomit-frame-pointer
OBJCOPY=riscv64-unknown-elf-objcopy

all: $(bootrom_img)

%.img: %.bin
	dd if=$< of=$@ bs=128 count=1

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.elf: %.S linker.ld hostdetect.o
	$(CC) -Tlinker.ld $< hostdetect.o -nostdlib -static -Wl,--no-gc-sections -o $@
	riscv64-unknown-elf-readelf -S $@ > $@.sections
	riscv64-unknown-elf-objdump -d $@ > $@.dis
