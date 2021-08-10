CXX_SOURCES =
CXX_SOURCES += $(wildcard *.cpp)
CXX_SOURCES += $(wildcard imgui/*.cpp)
CXX_SOURCES += $(wildcard imgui/*.c)

SV_SOURCES =
SV_SOURCES += ../src/library/logging.sv
SV_SOURCES += ../src/library/common.sv
SV_SOURCES += ../src/library/system_ram.sv
SV_SOURCES += ../src/library/video_ram.sv
SV_SOURCES += ../src/library/character_rom.sv
SV_SOURCES += ../src/library/bios_rom.sv
SV_SOURCES += ../src/library/segdisplay.sv
SV_SOURCES += ../src/library/vga_controller.sv
SV_SOURCES += ../src/library/regfile.sv
SV_SOURCES += ../src/library/alu.sv
SV_SOURCES += ../src/library/cpu_csr.sv
SV_SOURCES += ../src/library/cpu_if.sv
SV_SOURCES += ../src/library/cpu_wb.sv
SV_SOURCES += ../src/library/cpu_ex.sv
SV_SOURCES += ../src/library/cpu_id.sv
SV_SOURCES += ../src/library/cpu_ma.sv
SV_SOURCES += ../src/library/cpu.sv
SV_SOURCES += ../src/library/board.sv
SV_SOURCES += ../src/library/cpu_clk_gen.sv
SV_SOURCES += ../src/library/pixel_clk_gen.sv
SV_SOURCES += ../src/library/chipset.sv

VLT_SOURCES =
VLT_SOURCES = ./config.vlt

CXXFLAGS =
CXXFLAGS += -I../imgui -I../imgui/GL
CXXFLAGS += -g -Wall -Wformat
CXXFLAGS += -std=c++20
CXXFLAGS += -DIMGUI_IMPL_OPENGL_LOADER_GL3W
CXXFLAGS += `pkg-config --cflags glfw3`

LIBS =
LIBS += -lGL
LIBS += -lpthread
LIBS += `pkg-config --static --libs glfw3`

VERILATOR = verilator
VERILATOR_DIR = verilator
VERILATOR_TOP = chipset
VERILATOR_FLAGS =
VERILATOR_FLAGS += --autoflush
VERILATOR_FLAGS += -O2 --cc --exe
VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += --trace
VERILATOR_FLAGS += --clk clk_sys_i
VERILATOR_FLAGS += --top $(VERILATOR_TOP)
VERILATOR_FLAGS += --Mdir $(VERILATOR_DIR)
VERILATOR_FLAGS += -o chipset
VERILATOR_FLAGS += --CFLAGS "$(CXXFLAGS)"
VERILATOR_FLAGS += --LDFLAGS "$(LIBS)"
VERILATOR_LIB = $(VERILATOR_DIR)/V$(VERILATOR_TOP)__ALL.a

EXE = $(VERILATOR_TOP)

OBJS = $(addsuffix .o, $(basename $(notdir $(SOURCES))))

$(EXE): $(SV_SOURCES) $(VLT_SOURCES) $(CXX_SOURCES)
	rm -Rf $(VERILATOR_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) $(VLT_SOURCES) $(SV_SOURCES) $(CXX_SOURCES)
	$(MAKE) -C $(VERILATOR_DIR) -f V$(VERILATOR_TOP).mk
	cp $(VERILATOR)/$(EXE) $(EXE)

all: $(EXE)

clean:
	rm -f $(EXE) $(OBJS) $(VERILATOR_DIR)
	rm -Rf verilator
