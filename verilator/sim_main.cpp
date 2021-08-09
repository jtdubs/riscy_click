#include <verilated.h>
#include "obj_dir/Vchipset.h"

unsigned long ncycles = 0;

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);

    Vchipset *dut = new Vchipset;
    dut->reset_async_i = 1;
    dut->switch_async_i = 0x1234;
    dut->clk_sys_i = 1;
    dut->clk_cpu_i = 1;
    dut->clk_pxl_i = 1;

    while (ncycles < 2000) {
        dut->eval();

        ncycles++;

        dut->clk_sys_i ^= 1;
        if (ncycles % 2 == 0) dut->clk_cpu_i ^= 1;
        if (ncycles % 4 == 0) dut->clk_pxl_i ^= 1;
        if (ncycles == 10) dut->reset_async_i = 0;
    }

    dut->final();
    delete dut;

    exit(EXIT_SUCCESS);
}
