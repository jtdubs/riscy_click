#pragma once

#include "type_defs.h"

#define REGION_BIOS        0x00000000
#define REGION_RAM         0x10000000
#define REGION_FRAMEBUFFER 0x20000000
#define REGION_DISPLAY     0xFF000000
#define REGION_SWITCH      0xFF000004
#define REGION_KEYBOARD    0xFF000008

volatile uint32_t * const PTR_BIOS        = (volatile uint32_t * const)REGION_BIOS;
volatile uint32_t * const PTR_RAM         = (volatile uint32_t * const)REGION_RAM;
volatile uint8_t  * const PTR_FRAMEBUFFER = (volatile uint8_t  * const)REGION_FRAMEBUFFER;
volatile uint32_t * const PTR_DISPLAY     = (volatile uint32_t * const)REGION_DISPLAY;
volatile uint32_t * const PTR_SWITCH      = (volatile uint32_t * const)REGION_SWITCH;
volatile uint32_t * const PTR_KEYBOARD    = (volatile uint32_t * const)REGION_KEYBOARD;
