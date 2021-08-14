#include "mmap.h"
#include "keyboard.h"
#include "display.h"
#include "segment.h"
#include "console.h"

#include <stdint.h>

static volatile int interrupt_count = 0;

int main() {
    dsp_clear(' ');

    // main loop
    uint8_t x = 0;
    uint8_t y = 0;

    for (;;) {
        char c = con_getch();

        if (interrupt_count) {
            char c = dsp_read(10+interrupt_count, 10);
            c = (c == ' ') ? 'A' : (c+1);
            dsp_write(10+interrupt_count, 10, c);
            interrupt_count = 0;
        }

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

void on_key() {
    interrupt_count++;
}
