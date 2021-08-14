#include "mmap.h"
#include "keyboard.h"
#include "display.h"
#include "segment.h"
#include "console.h"

#include <stdint.h>

int main() {
    dsp_clear(' ');

    // main loop
    uint8_t x = 0;
    uint8_t y = 0;

    for (;;) {
        char c = con_getch();

        switch (c) {
        case '\n':
            x = 0;
            if (++y == DSP_HEIGHT) y = 0;
            break;
        case '\x1B':
            x = 0;
            y = 0;
            dsp_clear(' ');
            break;
        default:
            dsp_write(x, y, c);
            if (++x == DSP_WIDTH) x = 0;
            if (x == 0)
                if (++y == DSP_HEIGHT) y = 0;
            break;
        }
    }
}
