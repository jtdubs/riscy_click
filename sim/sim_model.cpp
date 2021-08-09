#include "imgui.h"
#include "imgui_internal.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include <stdio.h>
#include <verilated.h>
#include <GL/gl3w.h>
#include <GLFW/glfw3.h>
#include <cstdint>

#include "verilator/Vchipset.h"
#include "sim_vga.h"
#include "sim_segdisplay.h"
#include "sim_switch.h"
#include "sim_model.h"

struct sim_model {
    Vchipset* chipset;
    bool      reset;
    bool      switches[16];
    uint8_t   segments[8];
    GLuint    vga_texture;
    uint64_t  ncycles;
};

sim_model_t* sim_create(int argc, char **argv) {
    // Init Verilator
    Verilated::commandArgs(argc, argv);

    sim_model_t *model = new sim_model_t();
    model->reset = true;

    // Create Chipset
    model->chipset = new Vchipset;
    model->chipset->reset_async_i = model->reset?1:0;
    model->chipset->switch_async_i = 0x0000;
    model->chipset->clk_cpu_i = 1;
    model->chipset->clk_pxl_i = 1;

    // Create VGA Texture
    model->vga_texture = vga_create(640, 480);

    return model;
}

void sim_destroy(sim_model_t* model) {
    // Cleanup DUT
    model->chipset->final();
    delete model->chipset;
    delete model;
}

void sim_tick(sim_model_t* model) {
    for (int i=0; i<100000; i++)
    {
        Vchipset *dut = model->chipset;

        // update chipset
        dut->eval();

        // next cycle
        model->ncycles++;

        // update clocks
        dut->clk_cpu_i ^= 1;
        if (model->ncycles % 2 == 0) { dut->clk_pxl_i ^= 1; }

        // lower reset after 10 half-cycles
        if (model->ncycles == 10) model->reset = 0; 
        dut->reset_async_i = model->reset;

        // update switches
        uint16_t switch_async_i = 0;
        for (int i=0; i<16; i++)
            switch_async_i |= model->switches[15-i] << i;
        dut->switch_async_i = switch_async_i;

        // update seven segment display
        seg_tick(model->segments, dut->dsp_anode_o, dut->dsp_cathode_o);

        // update VGA every pixel clock cycle
        if (model->ncycles % 4 == 0)
            vga_tick(model->vga_texture, dut->vga_hsync_o, dut->vga_vsync_o, dut->vga_red_o, dut->vga_green_o, dut->vga_blue_o);
    }
}

void sim_draw(sim_model_t* model) {
    vga_draw("vga", 640, 480, model->vga_texture);

    for (int i=7; i>=0; i--)
    {
        ImGui::PushID(i);
        seg_draw_digit("segment", model->segments[i]);
        ImGui::PopID();
        if (i != 0)
            ImGui::SameLine();
    }

    for (int i=0; i<16; i++)
    {
        ImGui::PushID(i);
        sw_draw("switch", &model->switches[i]);
        ImGui::PopID();
        if (i < 15)
            ImGui::SameLine();
    }

    ImGui::Checkbox("Reset", &model->reset);
}