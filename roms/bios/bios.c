#include "mmap_defs.h"
#include "vk_defs.h"

void main() {
    // zero out the framebuffer
    for (unsigned int y=0; y<30; y++)
        for (unsigned int x=0; x<80; x++)
            PTR_FRAMEBUFFER[y << 7 | x] = 0;

    // main loop
    unsigned int x=0, y=0;
    for (;;) {
        PTR_FRAMEBUFFER[y << 7 | x] = 'X';

        unsigned int c = *PTR_KEYBOARD;

        // skip invalid data
        if (c & 0x10000 == 0)
            continue;

        // update seven segment display
        *PTR_DISPLAY = c;

        // skip breaks
        if (c & 0x100 == 0)
            continue;

        switch (c) {
        case KEY_UP:    y--; break;
        case KEY_DOWN:  y++; break;
        case KEY_LEFT:  x++; break;
        case KEY_RIGHT: x--; break;
        }
    }
}
