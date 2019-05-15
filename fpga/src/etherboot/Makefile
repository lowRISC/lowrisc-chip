CROSSCOMPILE ?= riscv64-unknown-elf-
CC = ${CROSSCOMPILE}gcc
PYTHON=python

CFLAGS = -Os -ggdb -march=rv64imac -mabi=lp64 -Wall -mcmodel=medany -fno-builtin-printf -fno-builtin-memcpy -fno-builtin -ffreestanding -fshort-wchar  # -mexplicit-relocs
CCASFLAGS = -mcmodel=medany # -mexplicit-relocs
LDFLAGS = -nostdlib -nodefaultlibs -nostartfiles -Wl,-Map=mapfile

INCLUDES = -I./ -I./src

SRCS_C = src/blk_legacy.c src/ctype.c src/dhcp-client.c src/display_options.c src/div64.c src/elf.c src/ethlib.c src/ff.c src/hash-md5.c src/lowrisc_mmc.c src/mini-printf.c src/mmc.c src/mmc_legacy.c src/random.c src/string.c src/strto.c src/tftp_c.c src/time.c src/uart.c src/boot.c src/dram.c src/cachetest.c
BOOT_O = src/main.o

SRCS_ASM = startup.S
OBJS_C = $(SRCS_C:.c=.o)
OBJS_S = $(SRCS_ASM:.S=.o)

MAIN = etherboot.elf
MAIN_BIN = $(MAIN:.elf=.bin)
MAIN_DIS = $(MAIN:.elf=.dis)
MAIN_IMG = $(MAIN:.elf=.img)
MAIN_SV = $(MAIN:.elf=.sv)
BOOTRAM = ../../src/bootram.sv

#.PHONY: clean

$(MAIN): ariane.dtb $(OBJS_C) src/main.o $(OBJS_S) linker.lds
	$(CC) $(CFLAGS) $(LDFLAGS) $(INCLUDES) -Tlinker.lds $(OBJS_S) $(OBJS_C) src/main.o -o $@
	@echo "LD    >= $(MAIN)"

%.img: %.bin
	dd if=$< of=$@ bs=128

%.bin: %.elf
	$(CROSSCOMPILE)objcopy -O binary $< $@

%.dis: %.elf
	$(CROSSCOMPILE)objdump -d -l -S $< > $@
%.o: %.c
	@$(CC) $(CFLAGS) $(INCLUDES) -c $<  -o $@
	@echo "CC    <= $<"

%.o: %.S
	@$(CC) $(CFLAGS) $(CCASFLAGS) $(INCLUDES) -c $<  -o $@
	@echo "CC    <= $<"

%.dtb: %.dts
	dtc -I dts $< -O dtb -o $@

%.sv: %.img
	$(PYTHON) ./gen_rom.py $<
	@echo "PYTHON >= $(MAIN_SV)"

clean:
	$(RM) $(OBJS_C) $(OBJS_S) $(MAIN) $(MAIN_BIN) $(MAIN_IMG) *.dtb

all: $(MAIN) $(MAIN_BIN) $(MAIN_IMG) $(MAIN_DIS) $(MAIN_SV) $(BOOTRAM)
	@echo "zero stage etherboot loader has been compiled!"

dram.elf: $(OBJS_C) src/dram.o $(OBJS_S) linker.lds
	$(CC) $(CFLAGS) $(LDFLAGS) $(INCLUDES) -Tlinker.lds $(OBJS_S) $(OBJS_C) src/dram.o -o $@

$(BOOTRAM): $(MAIN)
	$(CROSSCOMPILE)objcopy -O verilog $< cnvmem.mem
	iverilog ../../scripts/cnvmem.v -o cnvmem
	./cnvmem
	mv bootram.sv $@

# DO NOT DELETE THIS LINE -- make depend needs it
