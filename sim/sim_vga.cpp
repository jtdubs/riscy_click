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

void vga_write(size_t width, size_t height, GLuint texture, size_t x, size_t y, uint16_t value)
{
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, 1, 1, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, &value);
}

void vga_draw(const char *str_id, size_t width, size_t height, GLuint texture) {
    ImGui::Image((void*)(intptr_t)texture, ImVec2(width*2, height*2));
}

void vga_tick(GLuint texture, bool hsync, bool vsync, uint8_t red, uint8_t green, uint8_t blue) {
    static size_t x=0, y=0;
    static bool last_vsync = false, last_hsync = false;

    x = (hsync) ? x+1 : -48;
    y = (vsync) ? y : -32;
    if (last_hsync && !hsync) y++;

    last_vsync = vsync;
    last_hsync = hsync;

    if (x < 640 && y < 480)
        vga_write(640, 480, texture, x, y, (red << 12) | (green << 8) | (blue << 4) | (0x0F << 0));
}
