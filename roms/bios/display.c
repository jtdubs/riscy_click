#include "display.h"

inline void dsp_clear(char c) {
    for (uint8_t y = 0; y < DSP_HEIGHT; y++)
        for (uint8_t x = 0; x < DSP_WIDTH; x++)
            dsp_write(x, y, c);
}
