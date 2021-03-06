.PHONY: all clean

ASM_SOURCES = $(wildcard *.s)
CXX_SOURCES = $(wildcard *.c) $(wildcard peripherals/*.c)
LINK_SCRIPT = bios.ld

TARGET = bios
ELF_TARGET = $(TARGET).elf
DIS_TARGET = $(TARGET).dis
MEM_TARGET = $(TARGET).mem

OBJECTS = $(ASM_SOURCES:.s=.o) $(CXX_SOURCES:.c=.o)

CC = riscv32-unknown-elf-gcc
LD = riscv32-unknown-elf-ld
OBJDUMP = riscv32-unknown-elf-objdump
OBJCOPY = riscv32-unknown-elf-objcopy

CFLAGS =
CFLAGS += -mabi=ilp32
# CFLAGS += -march=rv32i
CFLAGS += -march=rv32ic
CFLAGS += -std=c18
CFLAGS += -nostartfiles
CFLAGS += -nodefaultlibs
CFLAGS += -ffreestanding
CFLAGS += -Os
CFLAGS += -mstrict-align
# CFLAGS += -g
CFLAGS += -Wall
CFLAGS += -Wpedantic
CFLAGS += -pedantic
CFLAGS += -c

LDFLAGS =
LDFLAGS += -e _start
LDFLAGS += -nostdlib

all: $(ELF_TARGET) $(DIS_TARGET) $(MEM_TARGET)

$(ELF_TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -T $(LINK_SCRIPT) -o $@ $^

clean:
	rm -f $(OBJECTS) $(ELF_TARGET) $(DIS_TARGET) $(MEM_TARGET)

%.o: %.s
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $^

%.dis: %.elf
	$(OBJDUMP) --disassemble-all $^ > $@

%.img: %.elf
	$(OBJCOPY) $^ -O binary $@

%.mem: %.img
	echo "@0000" > $@
	hexdump -v -e '/4 "%08X" "\n"' $^ >> $@
