#include "imgui.h"
#include "imgui_internal.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include <GL/gl3w.h>
#include <GLFW/glfw3.h>

#include "sim_vga.h"

GLuint vga_create(int width, int height)
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

void vga_write(int width, int height, GLuint texture, int x, int y, unsigned short value)
{
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, 1, 1, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, &value);
}

void vga_draw(const char *str_id, int width, int height, GLuint texture) {
    ImGui::Image((void*)(intptr_t)texture, ImVec2(width*2, height*2));
}

void vga_tick(GLuint texture, bool hsync, bool vsync, int red, int green, int blue) {
    static int x=0, y=0;
    static bool last_vsync = false, last_hsync = false;

    x = (hsync) ? x+1 : -48;
    y = (vsync) ? y : -32;
    if (last_hsync && !hsync) y++;

    last_vsync = vsync;
    last_hsync = hsync;

    // printf("VGA Tick: (h=%i, v=%i) -> (x=%i, y=%i)\n", hsync, vsync, x, y);
    if (x < 640 && y < 480)
        vga_write(640, 480, texture, x, y, (red << 12) | (green << 8) | (blue << 4) | (0x0F << 0));
}
