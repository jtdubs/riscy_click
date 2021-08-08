#!/bin/sh

verilator --cc --build --exe \
    ./riscy_click.srcs/board_sim/new/board_tb.sv \
    ./riscy_click.srcs/sources_1/new/common.sv \
    ./riscy_click.srcs/sources_1/new/logging.sv \
    ./riscy_click.srcs/sources_1/new/cpu_clk_gen.sv \
    ./riscy_click.srcs/sources_1/new/pixel_clk_gen.sv \
    ./riscy_click.srcs/sources_1/new/system_ram.sv \
    ./riscy_click.srcs/sources_1/new/character_rom.sv \
    ./riscy_click.srcs/sources_1/new/bios_rom.sv \
    ./riscy_click.srcs/sources_1/new/video_ram.sv \
    ./riscy_click.srcs/sources_1/new/vga_controller.sv \
    ./riscy_click.srcs/sources_1/new/alu.sv \
    ./riscy_click.srcs/sources_1/new/segdisplay.sv \
    ./riscy_click.srcs/sources_1/new/regfile.sv \
    ./riscy_click.srcs/sources_1/new/cpu_csr.sv \
    ./riscy_click.srcs/sources_1/new/cpu_if.sv \
    ./riscy_click.srcs/sources_1/new/cpu_wb.sv \
    ./riscy_click.srcs/sources_1/new/cpu_ex.sv \
    ./riscy_click.srcs/sources_1/new/cpu_id.sv \
    ./riscy_click.srcs/sources_1/new/cpu_ma.sv \
    ./riscy_click.srcs/sources_1/new/cpu.sv \
    ./riscy_click.srcs/sources_1/new/board.sv \
    sim_main.cpp
