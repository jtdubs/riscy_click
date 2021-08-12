#include <verilated.h>
#include "verilator/Vchipset.h"

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);

    Vchipset *dut = new Vchipset;
    dut->switch_async_i = 0x1234;
    dut->reset_async_i = 1;

    uint64_t ncycles = 0;

    while (ncycles < 100000 && !Verilated::gotFinish() && (dut->reset_async_i || !dut->halt_o)) {
        dut->eval();

        ncycles++;

        // update clocks
        dut->cpu_clk_i ^= 1;
        if (ncycles % 2 == 0) { dut->pxl_clk_i ^= 1; }

        // lower reset after 10 half-cycles
        if (ncycles == 10) dut->reset_async_i = 0;
    }

    dut->final();
    delete dut;

    return 0;
}
