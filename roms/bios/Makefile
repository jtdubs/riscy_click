.PHONY: all clean

SOURCES = bios.s
TARGETS = bios.mem bios.dis

CC = riscv32-unknown-elf-gcc
LD = riscv32-unknown-elf-ld
OBJDUMP = riscv32-unknown-elf-objdump
OBJCOPY = riscv32-unknown-elf-objcopy

CFLAGS =
CFLAGS += -mabi=ilp32
CFLAGS += -march=rv32i
CFLAGS += -O2
CFLAGS += -c

LDFLAGS =
LDFLAGS += -e _start
LDFLAGS += -nostdlib
LDFLAGS += -section-start=.text=0
LDFLAGS += -section-start=.sdata=300

all: $(TARGETS)

clean:
	rm -f *.o *.elf *.dis *.img *.mem

%.o: %.s
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $^

%.elf: %.o
	$(LD) $(LDFLAGS) -o $@ $^

%.dis: %.elf
	$(OBJDUMP) --disassemble-all $^ -M no-aliases,numeric > $@

%.img: %.elf
	$(OBJCOPY) $^ -O binary $@

%.mem: %.img
	echo "@0000" > $@
	hexdump -v -e '/4 "%08X" "\n"' $^ >> $@
