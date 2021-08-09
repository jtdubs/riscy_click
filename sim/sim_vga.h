#ifndef __SIM_VGA_H
#define __SIM_VGA_H

#include <GL/gl3w.h>
#include <cstdint>

GLuint vga_create(size_t width, size_t height);
void vga_write(size_t width, size_t height, GLuint texture, size_t x, size_t y, uint16_t value);
void vga_tick(GLuint texture, bool hsync, bool vsync, uint8_t red, uint8_t green, uint8_t blue);
void vga_draw(const char *str_id, size_t width, size_t height, GLuint texture);

#endif
