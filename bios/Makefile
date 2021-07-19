.PHONY: all clean

all: bios.coe bios.dis

clean:
	rm -f bios.o bios dios.dis bios.img bios.coe

bios.o: bios.c
	clang -O -c --target=riscv32 -march=rv32im bios.c -o bios.o

bios: bios.o
	ld.lld bios.o -o bios --entry=_start --section-start=.text=0 --section-start=.sdata=300 --nostdlib

bios.dis: bios
	llvm-objdump --disassemble-all bios -M no-aliases,numeric > bios.dis

bios.img: bios
	llvm-objcopy bios -O binary bios.img

bios.coe: bios.img
	bin2coe -i bios.img -o bios.coe -w 32
