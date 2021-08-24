CXX_SOURCES =
CXX_SOURCES += $(wildcard *.cpp)

SV_SOURCES =
SV_SOURCES += ../src/common.sv
SV_SOURCES += ../src/utils/logging.sv
SV_SOURCES += ../src/utils/clk_gen.sv
SV_SOURCES += ../src/utils/fifo.sv
SV_SOURCES += ../src/cpu/cpu_common.sv
SV_SOURCES += ../src/cpu/csr_common.sv
SV_SOURCES += ../src/cpu/csr.sv
SV_SOURCES += ../src/cpu/decoder.sv
SV_SOURCES += ../src/cpu/alu.sv
SV_SOURCES += ../src/cpu/regfile.sv
SV_SOURCES += ../src/cpu/decompressor.sv
SV_SOURCES += ../src/cpu/stage_fetch.sv
SV_SOURCES += ../src/cpu/stage_decode.sv
SV_SOURCES += ../src/cpu/stage_execute.sv
SV_SOURCES += ../src/cpu/stage_memory.sv
SV_SOURCES += ../src/cpu/stage_writeback.sv
SV_SOURCES += ../src/cpu/cpu.sv
SV_SOURCES += ../src/cpu/chipset.sv
SV_SOURCES += ../src/memory/system_ram.sv
SV_SOURCES += ../src/memory/video_ram.sv
SV_SOURCES += ../src/memory/bios_rom.sv
SV_SOURCES += ../src/peripherals/vga/character_rom.sv
SV_SOURCES += ../src/peripherals/vga/vga_controller.sv
SV_SOURCES += ../src/peripherals/interrupt_controller.sv
SV_SOURCES += ../src/peripherals/segment_display.sv
SV_SOURCES += ../src/peripherals/switches.sv
SV_SOURCES += ../src/peripherals/keyboard/keyboard_common.sv
SV_SOURCES += ../src/peripherals/keyboard/ps2_rx.sv
SV_SOURCES += ../src/peripherals/keyboard/ps2_keyboard.sv
SV_SOURCES += ../src/peripherals/keyboard/keycode_rom.sv
SV_SOURCES += ../src/peripherals/keyboard/keyboard_controller.sv
SV_SOURCES += ../src/peripherals/uart/uart_common.sv
SV_SOURCES += ../src/peripherals/uart/uart_rx.sv
SV_SOURCES += ../src/peripherals/uart/uart_tx.sv
SV_SOURCES += ../src/peripherals/uart/uart.sv
SV_SOURCES += ../src/top.sv

VLT_SOURCES =
VLT_SOURCES = ./config.vlt

CXXFLAGS =
CXXFLAGS += -g -Wall -Wformat

VERILATOR = verilator
VERILATOR_DIR = verilator
VERILATOR_TOP = top
VERILATOR_FLAGS =
VERILATOR_FLAGS += --autoflush
VERILATOR_FLAGS += -O2 --cc --exe
VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += --trace
VERILATOR_FLAGS += --clk sys_clk_i
VERILATOR_FLAGS += --top $(VERILATOR_TOP)
VERILATOR_FLAGS += --Mdir $(VERILATOR_DIR)
VERILATOR_FLAGS += -o top
VERILATOR_FLAGS += --CFLAGS "$(CXXFLAGS)"
VERILATOR_FLAGS += -DENABLE_LOGGING=1
VERILATOR_FLAGS += -DUSE_EXTERNAL_CLOCKS=1
VERILATOR_LIB = $(VERILATOR_DIR)/V$(VERILATOR_TOP)__ALL.a

ROMS =
ROMS += bios.mem
ROMS += crom1.mem crom2.mem crom3.mem crom4.mem
ROMS += krom.mem

EXE = $(VERILATOR_TOP)

OBJS = $(addsuffix .o, $(basename $(notdir $(SOURCES))))

all: $(EXE)

clean:
	rm -f $(EXE) $(OBJS)
	rm -Rf $(VERILATOR_DIR)

analyze: log.json
	../utils/log_analysis/analyze.py log.json

log.json: $(EXE)
	./$(EXE)

bios.mem: ../roms/bios/bios.mem
	ln -sf $^ $@

crom1.mem: ../roms/character_rom/crom1.mem
	ln -sf $^ $@

crom2.mem: ../roms/character_rom/crom2.mem
	ln -sf $^ $@

crom3.mem: ../roms/character_rom/crom3.mem
	ln -sf $^ $@

crom4.mem: ../roms/character_rom/crom4.mem
	ln -sf $^ $@

krom.mem: ../roms/keycode/krom.mem
	ln -sf $^ $@

$(EXE): $(SV_SOURCES) $(VLT_SOURCES) $(CXX_SOURCES) $(ROMS)
	rm -Rf $(VERILATOR_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) $(VLT_SOURCES) $(SV_SOURCES) $(CXX_SOURCES)
	$(MAKE) -C $(VERILATOR_DIR) -f V$(VERILATOR_TOP).mk
	cp $(VERILATOR)/$(EXE) $(EXE)
