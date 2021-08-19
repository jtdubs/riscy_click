#include "imgui.h"
#include "imgui_internal.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include <GL/gl3w.h>
#include <GLFW/glfw3.h>

#include "sim_vga.h"

struct sim_vga {
    GLuint    texture;
    uint16_t* buffer;
};

static const int VGA_ACTIVE_WIDTH  = 726;
static const int VGA_ACTIVE_HEIGHT = 404;

static const int VGA_H_BACK_PORCH = 51;
static const int VGA_V_BACK_PORCH = 32;

sim_vga_t *vga_create(void)
{
    unsigned short *image_data = new unsigned short[VGA_ACTIVE_WIDTH * VGA_ACTIVE_HEIGHT] { 0 };
    for (int i=0; i<VGA_ACTIVE_WIDTH*VGA_ACTIVE_HEIGHT; i++)
        image_data[i] = 0xFFFF;

    GLuint texture_id;
    glGenTextures(1, &texture_id);
    glBindTexture(GL_TEXTURE_2D, texture_id);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, VGA_ACTIVE_WIDTH, VGA_ACTIVE_HEIGHT, 0, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, image_data);

    delete [] image_data;

    sim_vga *vga = new sim_vga;
    vga->texture = texture_id;
    vga->buffer  = new uint16_t[VGA_ACTIVE_WIDTH * VGA_ACTIVE_HEIGHT];

    return vga;
}

void vga_draw(sim_vga_t *vga) {
    glBindTexture(GL_TEXTURE_2D, vga->texture);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, VGA_ACTIVE_WIDTH, VGA_ACTIVE_HEIGHT, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, vga->buffer);
    ImGui::Image((void*)(intptr_t)vga->texture, ImVec2(VGA_ACTIVE_WIDTH*2, VGA_ACTIVE_HEIGHT*2));
}

void vga_tick(sim_vga_t *vga, bool hsync, bool vsync, uint8_t red, uint8_t green, uint8_t blue) {
    static size_t x=0, y=0;
    static bool last_vsync = false, last_hsync = false;

    x = (hsync) ? x+1 : -VGA_H_BACK_PORCH;
    y = (vsync) ? y : -VGA_V_BACK_PORCH;
    if (last_hsync && !hsync) y++;

    last_vsync = vsync;
    last_hsync = hsync;

    // printf("SIM (%i, %i) H:%i,%i V:%i,%i (%i, %i, %i)\n", (int)x, (int)y, last_hsync, hsync, last_vsync, vsync, red, green, blue);

    if (x >= 0 && x < VGA_ACTIVE_WIDTH && y >= 0 && y < VGA_ACTIVE_HEIGHT)
        vga->buffer[y*VGA_ACTIVE_WIDTH+x] = (red << 12) | (green << 8) | (blue << 4) | (0x0F << 0);
}
