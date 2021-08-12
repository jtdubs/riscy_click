CXX_SOURCES =
CXX_SOURCES += $(wildcard *.cpp)

SV_SOURCES =
SV_SOURCES += ../src/logging.sv
SV_SOURCES += ../src/common.sv
SV_SOURCES += ../src/system_ram.sv
SV_SOURCES += ../src/video_ram.sv
SV_SOURCES += ../src/character_rom.sv
SV_SOURCES += ../src/bios_rom.sv
SV_SOURCES += ../src/ps2_rx.sv
SV_SOURCES += ../src/ps2_kbd.sv
SV_SOURCES += ../src/segdisplay.sv
SV_SOURCES += ../src/vga_controller.sv
SV_SOURCES += ../src/regfile.sv
SV_SOURCES += ../src/alu.sv
SV_SOURCES += ../src/cpu_csr.sv
SV_SOURCES += ../src/cpu_if.sv
SV_SOURCES += ../src/cpu_wb.sv
SV_SOURCES += ../src/cpu_ex.sv
SV_SOURCES += ../src/cpu_id.sv
SV_SOURCES += ../src/cpu_ma.sv
SV_SOURCES += ../src/cpu.sv
SV_SOURCES += ../src/board.sv
SV_SOURCES += ../src/cpu_clk_gen.sv
SV_SOURCES += ../src/pixel_clk_gen.sv
SV_SOURCES += ../src/chipset.sv

VLT_SOURCES =
VLT_SOURCES = ./config.vlt

CXXFLAGS =
CXXFLAGS += -g -Wall -Wformat

VERILATOR = verilator
VERILATOR_DIR = verilator
VERILATOR_TOP = chipset
VERILATOR_FLAGS =
VERILATOR_FLAGS += --autoflush
VERILATOR_FLAGS += -O2 --cc --exe
VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += --trace
VERILATOR_FLAGS += --clk sys_clk_i
VERILATOR_FLAGS += --top $(VERILATOR_TOP)
VERILATOR_FLAGS += --Mdir $(VERILATOR_DIR)
VERILATOR_FLAGS += -o chipset
VERILATOR_FLAGS += --CFLAGS "$(CXXFLAGS)"
VERILATOR_FLAGS += +define+ENABLE_LOGGING=1
VERILATOR_LIB = $(VERILATOR_DIR)/V$(VERILATOR_TOP)__ALL.a

EXE = $(VERILATOR_TOP)

OBJS = $(addsuffix .o, $(basename $(notdir $(SOURCES))))

$(EXE): $(SV_SOURCES) $(VLT_SOURCES) $(CXX_SOURCES)
	rm -Rf $(VERILATOR_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) $(VLT_SOURCES) $(SV_SOURCES) $(CXX_SOURCES)
	$(MAKE) -C $(VERILATOR_DIR) -f V$(VERILATOR_TOP).mk
	cp $(VERILATOR)/$(EXE) $(EXE)

all: $(EXE)

log.json: $(EXE)
	./chipset

analyze: log.json
	../utils/log_analysis/analyze.py log.json

clean:
	rm -f $(EXE) $(OBJS)
	rm -Rf $(VERILATOR_DIR)
