.PHONY: all clean update_bios update_crom

all: bios.mem bios.dis

clean:
	rm -f bios.o bios bios.dis bios.img bios.mem

bios.o: bios.c
	riscv32-unknown-elf-gcc -mabi=ilp32 -march=rv32i -O2 -c bios.c -o bios.o

bios: bios.o
	riscv32-unknown-elf-ld -e _start -nostdlib --section-start=.text=0 --section-start=.sdata=300 -o bios bios.o

bios.dis: bios
	riscv32-unknown-elf-objdump --disassemble-all bios -M no-aliases,numeric > bios.dis

bios.img: bios
	riscv32-unknown-elf-objcopy bios -O binary bios.img

bios.mem: bios.img
	echo "@0000" > bios.mem
	hexdump -v -e '/4 "%08X" "\n"' bios.img >> bios.mem
