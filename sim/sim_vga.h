#ifndef __SIM_VGA_H
#define __SIM_VGA_H

#include <GL/gl3w.h>

GLuint vga_create(int width, int height);
void vga_write(int width, int height, GLuint texture, int x, int y, unsigned short value);
void vga_tick(GLuint texture, bool hsync, bool vsync, int red, int green, int blue);
void vga_draw(const char *str_id, int width, int height, GLuint texture);

#endif
