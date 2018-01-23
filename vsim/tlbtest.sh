riscv64-unknown-elf-gcc -g -nostdlib -T lowrisc.lds tlbtest.S -o tlbtest
riscv64-unknown-elf-objdump -d tlbtest > tlbtest.dis
riscv64-unknown-elf-objcopy -I elf64-little -O binary tlbtest tlbtest.bin
riscv64-unknown-elf-objcopy -I binary -O verilog tlbtest.bin cnvmem.mem 
riscv64-unknown-elf-objcopy -I elf64-little -O verilog tlbtest cnvmem.old
