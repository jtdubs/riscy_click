#include "imgui.h"
#include "imgui_internal.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include <GL/gl3w.h>
#include <GLFW/glfw3.h>

#include "sim_vga.h"

GLuint vga_create(size_t width, size_t height)
{
    unsigned short *image_data = new unsigned short[width * height] { 0 };
    for (int i=0; i<width*height; i++)
        image_data[i] = 0xFFFF;

    GLuint texture_id;
    glGenTextures(1, &texture_id);
    glBindTexture(GL_TEXTURE_2D, texture_id);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, image_data);

    delete [] image_data;

    return texture_id;
}

void vga_write(GLuint texture, uint16_t *buffer)
{
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 720, 400, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, buffer);
}

void vga_draw(const char *str_id, GLuint texture) {
    ImGui::Image((void*)(intptr_t)texture, ImVec2(720*2, 400*2));
}

void vga_tick(uint16_t *buffer, bool hsync, bool vsync, uint8_t red, uint8_t green, uint8_t blue) {
    static size_t x=0, y=0;
    static bool last_vsync = false, last_hsync = false;

    x = (hsync) ? x+1 : -108;
    y = (vsync) ? y : -42;
    if (last_hsync && !hsync) y++;

    last_vsync = vsync;
    last_hsync = hsync;

    // printf("VGA (%i, %i) H:%i,%i V:%i,%i (%i, %i, %i)\n", (int)x, (int)y, last_hsync, hsync, last_vsync, vsync, red, green, blue);

    if (x >= 0 && x < 720 && y >= 0 && y < 400)
        buffer[y*720+x] = (red << 12) | (green << 8) | (blue << 4) | (0x0F << 0);
}
