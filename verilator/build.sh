#!/bin/sh

verilator --autoflush --clk clk_sys_i --trace --cc --build --exe \
    ../src/tb/board_tb.sv \
    ../src/library/common.sv \
    ../src/sim/bios_rom.sv \
    ../src/sim/character_rom.sv \
    ../src/sim/cpu_clk_gen.sv \
    ../src/sim/logging.sv \
    ../src/sim/pixel_clk_gen.sv \
    ../src/sim/system_ram.sv \
    ../src/sim/video_ram.sv \
    ../src/library/cpu_if.sv \
    ../src/library/cpu_wb.sv \
    ../src/library/segdisplay.sv \
    ../src/library/cpu_csr.sv \
    ../src/library/board.sv \
    ../src/library/alu.sv \
    ../src/library/regfile.sv \
    ../src/library/cpu_ex.sv \
    ../src/library/cpu_id.sv \
    ../src/library/vga_controller.sv \
    ../src/library/cpu_ma.sv \
    ../src/library/cpu.sv \
    sim_main.cpp
