#pragma once

#include <stdint.h>
#include "mmap.h"

#define DSP_HEIGHT 30
#define DSP_WIDTH  80

       void dsp_clear (char c);
inline char dsp_read  (uint8_t x, uint8_t y);
inline void dsp_write (uint8_t x, uint8_t y, char c);

inline char dsp_read(uint8_t x, uint8_t y) {
    return (char)PTR_FRAMEBUFFER[y << 7 | x];
}

inline void dsp_write(uint8_t x, uint8_t y, char c) {
    PTR_FRAMEBUFFER[y << 7 | x] = c;
}