#pragma once

#include <stdint.h>

extern void * const __rom_start;
extern void * const __ram_start;
extern void * const __text_start;
extern void * const __text_end;
extern void * const __copy_start;
extern void * const __copy_end;
extern void * const __copy_source;
extern void * const __zero_start;
extern void * const __zero_end;
extern void * const __stack_start;
extern void * const __stack_end;
extern void * const __heap_start;
extern void * const __heap_end;

#define MMAP_BIOS        __rom_start
#define MMAP_RAM         __ram_start
#define MMAP_FRAMEBUFFER 0x20000000
#define MMAP_DISPLAY     0xFFFF0204
#define MMAP_SWITCH      0xFFFF0300
#define MMAP_KEYBOARD    0xFFFF0400

#define PTR_BIOS         ((volatile uint32_t * const)MMAP_BIOS)
#define PTR_RAM          ((volatile uint32_t * const)MMAP_RAM)
#define PTR_FRAMEBUFFER  ((volatile uint8_t  * const)MMAP_FRAMEBUFFER)
#define PTR_DISPLAY      ((volatile uint32_t * const)MMAP_DISPLAY)
#define PTR_SWITCH       ((volatile uint32_t * const)MMAP_SWITCH)
#define PTR_KEYBOARD     ((volatile uint32_t * const)MMAP_KEYBOARD)
