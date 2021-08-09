#include <verilated.h>
#include "obj_dir/Vchipset.h"
#include "vgasim.h"

class Testbench {
public:
    unsigned long ncycles;
    VGAWIN vgawin;
    Vchipset *dut;

public:
    Testbench() : ncycles(0), vgawin(640, 480) {
        dut = new Vchipset;
        init();
    }

    ~Testbench() {
        dut->final();
        delete dut;
    }

private:
    void init() {
        Glib::signal_idle().connect(sigc::mem_fun((*this), &Testbench::on_idle));

        dut->reset_async_i = 1;
        dut->switch_async_i = 0x1234;
        dut->clk_cpu_i = 1;
        dut->clk_pxl_i = 1;
    }

    bool on_idle() {
        dut->eval();

        ncycles++;

        dut->clk_cpu_i ^= 1;

        if (ncycles % 2 == 0) {
            dut->clk_pxl_i ^= 1;
        }

        if (ncycles % 4 == 0) {
            vgawin(dut->vga_vsync_o?1:0, dut->vga_hsync_o?1:0, dut->vga_red_o, dut->vga_green_o, dut->vga_blue_o);
        }

        if (ncycles == 10) dut->reset_async_i = 0;


        return true;
    }
};

unsigned long ncycles = 0;

int main(int argc, char** argv, char** env) {
    Gtk::Main main(argc, argv);
    Verilated::commandArgs(argc, argv);

    Testbench tb;

    main.run(tb.vgawin);

    exit(EXIT_SUCCESS);
}
