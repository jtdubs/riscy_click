#include <verilated.h>
#include <GLFW/glfw3.h>
#include "verilator/Vtop.h"
#include "sim_keyboard.h"

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);

    sim_keyboard_t *kbd = key_create();
    key_make (kbd, GLFW_KEY_LEFT_SHIFT);
    key_make (kbd, GLFW_KEY_H);
    key_break(kbd, GLFW_KEY_H);
    key_break(kbd, GLFW_KEY_LEFT_SHIFT);
    key_make (kbd, GLFW_KEY_E);
    key_break(kbd, GLFW_KEY_E);
    key_make (kbd, GLFW_KEY_L);
    key_break(kbd, GLFW_KEY_L);
    key_make (kbd, GLFW_KEY_L);
    key_break(kbd, GLFW_KEY_L);
    key_make (kbd, GLFW_KEY_O);
    key_break(kbd, GLFW_KEY_O);

    Vtop *dut = new Vtop;
    dut->switch_i = 0x1234;

    uint64_t ncycles = 0;

    while (ncycles < 100000 && !Verilated::gotFinish() && !dut->halt_o) {
        dut->eval();

        ncycles++;

        // update clocks
        dut->cpu_clk_i ^= 1;
        if (ncycles % 2 == 0) { dut->pxl_clk_i ^= 1; }

        // run ps2 at an absurd rate
        if (ncycles % 32 == 0) key_tick(kbd, &dut->ps2_clk_i, &dut->ps2_data_i);
    }

    dut->final();
    delete dut;

    return 0;
}
