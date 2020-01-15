export CROSSCOMPILE=riscv64-buildroot-linux-gnu-
CC = ${CROSSCOMPILE}gcc
PYTHON=python
MODEL=medany
#MODEL=medlow

CFLAGS = -Os -ggdb -march=rv64imafdc -mabi=lp64d -Wall -mcmodel=$(MODEL) -fno-builtin-printf -fno-builtin-memcpy -fno-builtin -ffreestanding -fshort-wchar -DBITSIZE=$(BITSIZE) # -mexplicit-relocs
CCASFLAGS = -mcmodel=$(MODEL) # -mexplicit-relocs
LDFLAGS = -nostdlib -nodefaultlibs -nostartfiles -Wl,-Map=mapfile

INCLUDES = -I./ -I./src

SRCS_C = src/dhcp-client.c src/elf.c src/ethlib.c src/ff.c src/hash-md5.c src/mini-printf.c src/random.c src/string.c src/tftp_c.c src/uart.c src/boot.c src/dram.c src/cachetest.c src/hid.c src/logo.c src/queryTimeServer.c src/bt.c

SRCS_ASM = startup.S $(BOARD)_$(CPU).S 
OBJS_C = $(SRCS_C:.c=.o)
OBJS_S = $(SRCS_ASM:.S=.o)

MAIN = $(BOARD)_$(CPU).elf
MAIN_BIN = $(MAIN:.elf=.bin)
MAIN_DIS = $(MAIN:.elf=.dis)
MAIN_IMG = $(MAIN:.elf=.img)
MAIN_SV = $(MAIN:.elf=.sv)
MAIN_MEM = $(MAIN:.elf=.mem)
MAIN_VLOG = $(MAIN:.elf=.vlog)
BOOTRAM = 

#.PHONY: clean

all: $(MAIN) $(MAIN_BIN) $(MAIN_IMG) $(MAIN_DIS) $(MAIN_SV) $(MAIN_MEM)
	@echo "zero stage etherboot loader has been compiled!"

$(MAIN): $(OBJS_C) src/main.c $(OBJS_S) $(BOARD)_$(CPU).o linker.lds
	$(CC) $(CFLAGS) $(LDFLAGS) $(INCLUDES) -Tlinker.lds $(OBJS_S) $(OBJS_C) src/main.c -o $@
	@echo "LD    >= $(MAIN)"

$(BOARD)_$(CPU).dtb: ../generic.dts
	sed -e "s/VENDOR/$(VENDOR)/" -e "s/CPU/$(CPU)/" -e "s/MEMSIZE/$(MEMSIZE)/" -e "s/BOARD/$(BOARD)/" $< | dtc -I dts -O dtb -o $@

$(BOARD)_$(CPU).o: $(BOARD)_$(CPU).dtb
	echo -e .section .dtb \; .align 4,0 \; .globl _dtb \; _dtb: \; .incbin \"$(BOARD)_$(CPU).dtb\" | $(CC) $(CFLAGS) -c -xassembler - -o $@

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

clean:
	$(RM) $(OBJS_C) $(OBJS_S) $(MAIN) $(MAIN_BIN) $(MAIN_IMG)

dram.elf: $(OBJS_C) src/dram.o $(OBJS_S) linker.lds
	$(CC) $(CFLAGS) $(LDFLAGS) $(INCLUDES) -Tlinker.lds $(OBJS_S) $(OBJS_C) src/dram.o -o $@

$(MAIN_MEM) $(MAIN_SV): ./cnvmem $(MAIN_VLOG)
	./cnvmem +VLOG=$(MAIN_VLOG) +MEM=$(MAIN_MEM) +SV=$(MAIN_SV)

./cnvmem: ../../scripts/cnvmem.v
	iverilog $< -o $@

$(MAIN_VLOG): $(MAIN)
	$(CROSSCOMPILE)objcopy -O verilog $< $@

# DO NOT DELETE THIS LINE -- make depend needs it
