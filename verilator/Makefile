.PHONE: all clean

all: obj_dir/chipset

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

CPP_SOURCES =
CPP_SOURCES += ./vgasim.cpp
CPP_SOURCES += ./sim_main.cpp

VLT_SOURCES =
VLT_SOURCES = ./config.vlt

CFLAGS =
CFLAGS += `pkg-config gtkmm-3.0 --cflags`

LDFLAGS =
LDFLAGS += `pkg-config gtkmm-3.0 --libs`

VERILATOR = verilator
VERILATOR_FLAGS =
VERILATOR_FLAGS += --autoflush
VERILATOR_FLAGS += -O2 --cc --exe
VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += --trace
VERILATOR_FLAGS += --clk clk_sys_i
VERILATOR_FLAGS += --top chipset -o chipset
VERILATOR_FLAGS += -CFLAGS "$(CFLAGS)"
VERILATOR_FLAGS += -LDFLAGS "$(LDFLAGS)"

obj_dir/chipset: $(SV_SOURCES) $(CPP_SOURCES)
	rm -Rf obj_dir
	verilator $(VERILATOR_FLAGS) $(VLT_SOURCES) $(SV_SOURCES) $(CPP_SOURCES)
	make -C obj_dir -f Vchipset.mk

run: obj_dir/chipset
	./obj_dir/chipset

clean:
	rm -Rf obj_dir
