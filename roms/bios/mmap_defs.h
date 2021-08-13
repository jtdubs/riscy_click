#pragma once

#define REGION_BIOS        0x00000000
#define REGION_RAM         0x10000000
#define REGION_FRAMEBUFFER 0x20000000
#define REGION_DISPLAY     0xFF000000
#define REGION_SWITCH      0xFF000004
#define REGION_KEYBOARD    0xFF000008

unsigned long *PTR_BIOS        = (unsigned long *)REGION_BIOS;
unsigned long *PTR_RAM         = (unsigned long *)REGION_RAM;
unsigned long *PTR_FRAMEBUFFER = (unsigned long *)REGION_FRAMEBUFFER;
unsigned long *PTR_DISPLAY     = (unsigned long *)REGION_DISPLAY;
unsigned long *PTR_SWITCH      = (unsigned long *)REGION_SWITCH;
unsigned long *PTR_KEYBOARD    = (unsigned long *)REGION_KEYBOARD;
