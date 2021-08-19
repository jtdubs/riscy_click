#ifndef __SIM_VGA_H
#define __SIM_VGA_H

#include <GL/gl3w.h>
#include <cstdint>

GLuint vga_create(size_t width, size_t height);
void vga_write(GLuint texture, uint16_t *buffer);
void vga_tick(uint16_t* buffer, bool hsync, bool vsync, uint8_t red, uint8_t green, uint8_t blue);
void vga_draw(const char *str_id, GLuint texture);

#endif
