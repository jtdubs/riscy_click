#include "mmap_defs.h"
#include "type_defs.h"
#include "vk_defs.h"

// static uint8_t x, y;

int main() {
    // zero out the framebuffer
    for (uint8_t y=0; y<30; y++)
        for (uint8_t x=0; x<80; x++)
            PTR_FRAMEBUFFER[y << 7 | x] = 'X';

    // main loop
    uint8_t x = 0;
    uint8_t y = 0;
    for (;;) {
        PTR_FRAMEBUFFER[(y << 7) | x] = '*';

        uint32_t c = *PTR_KEYBOARD;

        // skip invalid data
        if ((c & 0x10000) == 0)
            continue;

        // update seven segment display
        *PTR_DISPLAY = c;

        // skip breaks
        if ((c & 0x100) == 0x100)
            continue;

        switch (c & 0xFF) {
        case KEY_UP:    y--; break;
        case KEY_DOWN:  y++; break;
        case KEY_LEFT:  x--; break;
        case KEY_RIGHT: x++; break;
        }
    }
}
