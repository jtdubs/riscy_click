#include "framebuffer.h"

#define FB_BASE 0x20000000

#define FB_DATA ((volatile char * const)(FB_BASE))


//
// Initialization
//

void fb_init(void) {
    fb_clear(' ');
}


//
// Read & Write
//

void fb_clear(char c) {
    for (uint8_t y = 0; y < FrameBufferHeight; y++)
        for (uint8_t x = 0; x < FrameBufferWidth; x++)
            fb_write(x, y, c);
}

char fb_read(uint8_t x, uint8_t y) {
    return FB_DATA[y << 7 | x];
}

void fb_write(uint8_t x, uint8_t y, char c) {
    FB_DATA[y << 7 | x] = c;
}
