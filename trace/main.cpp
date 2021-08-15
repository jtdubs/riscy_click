#include <verilated.h>
#include <GLFW/glfw3.h>
#include "verilator/Vchipset.h"
#include "sim_keyboard.h"

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);

    sim_keyboard_t *kbd = key_create();
    key_make (kbd, GLFW_KEY_LEFT_SHIFT);
    key_make (kbd, GLFW_KEY_H);
    key_break(kbd, GLFW_KEY_H);
    key_break(kbd, GLFW_KEY_LEFT_SHIFT);

    Vchipset *dut = new Vchipset;
    dut->switch_async_i = 0x1234;
    dut->reset_async_i = 1;

    uint64_t ncycles = 0;

    while (ncycles < 10000 && !Verilated::gotFinish() && (dut->reset_async_i || !dut->halt_o)) {
        dut->eval();

        ncycles++;

        // update clocks
        dut->cpu_clk_i ^= 1;
        if (ncycles % 2 == 0) { dut->pxl_clk_i ^= 1; }

        // lower reset after 10 half-cycles
        if (ncycles == 10) dut->reset_async_i = 0;

        // run ps2 at an absurd rate
        if (ncycles % 16 == 0) key_tick(kbd, &dut->ps2_clk_async_i, &dut->ps2_data_async_i);
    }

    dut->final();
    delete dut;

    return 0;
}
