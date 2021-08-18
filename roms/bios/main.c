#include "peripherals/display.h"
#include "peripherals/framebuffer.h"
#include "peripherals/interrupt.h"
#include "peripherals/keyboard.h"
#include "peripherals/switches.h"
#include "console.h"

#include <stdint.h>

int main() {
    irq_init();
    dsp_init();
    kbd_init();
    sw_init();
    fb_init();

    dsp_enable();

    // main loop
    uint8_t x = 0;
    uint8_t y = 0;

    for (;;) {
        char c = con_getch();

        switch (c) {
        case '\n':
            x = 0;
            if (++y == (FrameBufferHeight-1)) y = 0;
            break;
        case '\x1B':
            x = 0;
            y = 0;
            fb_clear(' ');
            break;
        default:
            fb_write(x, y, c);
            if (++x == FrameBufferWidth) x = 0;
            if (x == 0)
                if (++y == (FrameBufferHeight-1)) y = 0;
            break;
        }
    }
}
