.PHONY: all clean update_bios update_crom

all: bios.mem bios.dis

clean:
	rm -f bios.o bios bios.dis bios.img bios.mem

bios.o: bios.c
	clang -O2 -c --target=riscv32 -march=rv32im bios.c -o bios.o

bios: bios.o
	ld.lld bios.o -o bios --entry=_start --section-start=.text=0 --section-start=.sdata=300 --nostdlib

bios.dis: bios
	llvm-objdump --disassemble-all bios -M no-aliases,numeric > bios.dis

bios.img: bios
	llvm-objcopy bios -O binary bios.img

bios.mem: bios.img
	echo "@0000" > bios.mem
	hexdump -v -e '/4 "%08X" "\n"' bios.img >> bios.mem
