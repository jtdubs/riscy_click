.PHONY: all clean

all: bios.mem bios.coe

clean:
	rm -f bios.bin bios.hex bios.mem bios.coe

bios.bin: bios.s
	clang -O -c --target=riscv32 -march=rv32im bios.s -o bios.bin

bios.hex: bios.bin
	readelf -x .text bios.bin | awk '/0x/ { print substr($$_, 14, 35); }' > bios.hex

bios.mem: bios.hex
	srec_cat bios.hex --hex_dump --byte-swap 4 --output - -vmem 32 -data_only > bios.mem

bios.coe: bios.hex
	# srec_cat bios.hex --hex_dump --byte-swap 4 --output - -coe 32 -data_only | tr -d ',;' > bios.coe
	srec_cat bios.hex --hex_dump --byte-swap 4 --output - -coe 32 > bios.coe
