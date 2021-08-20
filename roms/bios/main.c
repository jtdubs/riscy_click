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

    _global_enable_interrupts();

    // main loop
    uint8_t x = 0;
    uint8_t y = 0;

    for (y=0; y<8; y++)
        for (x=0; x<32; x++)
            fb_write(x << 1, y, (y<<5)+x);

    x = 0;
    y = 0;
    for (;;) {
        char c = con_getch();

        switch (c) {
        case '\n':
            x = 0;
            if (++y == FrameBufferHeight) y = 0;
            break;
        case '\x1B':
            x = 0;
            y = 0;
            fb_set_blink(false);
            fb_set_underline(false);
            fb_clear(' ');
            break;
        case '\x08':
            if (x == 0) {
                x = (FrameBufferWidth-1);
                if (y == 0)
                    y = (FrameBufferHeight-1);
                else y--;
            } else x--;
            fb_write(x, y, ' ');
            break;
        default:
            {
                fb_write(x, y, c);
                if (++x == FrameBufferWidth) x = 0;
                if (x == 0)
                    if (++y == (FrameBufferHeight-1)) y = 0;
            }
            break;
        }
    }
}
