#!/bin/sh

verilator --cc --build --exe \
    ./src/library/*.sv \
    ./src/sim/*.sv \
    ./src/tb/board_tb.sv \
    sim_main.cpp
