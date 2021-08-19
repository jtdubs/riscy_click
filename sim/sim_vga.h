#ifndef __SIM_VGA_H
#define __SIM_VGA_H

#include <GL/gl3w.h>
#include <cstdint>

typedef struct sim_vga sim_vga_t;

sim_vga_t* vga_create();
void vga_tick(sim_vga_t* vga, bool hsync, bool vsync, uint8_t red, uint8_t green, uint8_t blue);
void vga_draw(sim_vga_t* vga);

#endif
