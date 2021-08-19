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
            if (++y == (FrameBufferHeight-1)) y = 0;
            break;
        case '\x1B':
            x = 0;
            y = 0;
            fb_set_blink(false);
            fb_set_underline(false);
            fb_clear(' ');
            break;
        default:
            {
                uint16_t sw = sw_read();
                fb_set_blink((sw >> 15) == 1);
                fb_set_underline((sw >> 14) == 1);
                fb_set_fg_color((sw & 0xF00) >> 4, (sw & 0xF0), (sw & 0x0F) << 4);
                fb_write(x, y, c);
                if (++x == FrameBufferWidth) x = 0;
                if (x == 0)
                    if (++y == (FrameBufferHeight-1)) y = 0;
            }
            break;
        }
    }
}
