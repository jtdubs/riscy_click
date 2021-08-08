#include <verilated.h>
#include "obj_dir/Vboard_tb.h"

unsigned long ncycles = 0;

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);

    Vboard_tb *dut = new Vboard_tb;
    dut->reset_async_i = 1;


    while (ncycles < 1000) {
        dut->clk_sys_i ^= 1;
        dut->eval();
        ncycles++;
        if (ncycles == 10)
            dut->reset_async_i = 0;
    }

    dut->final();
    delete dut;

    exit(EXIT_SUCCESS);
}
