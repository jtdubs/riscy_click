#include "mmap.h"
#include "keyboard.h"
#include "display.h"
#include "segment.h"

#include <stdint.h>

int main() {
    dsp_clear('.');

    // main loop
    uint8_t x = 0;
    uint8_t y = 0;

    for (;;) {
        dsp_write(x, y, '*');

        kbd_event_t ev = kbd_read();

        if (! kbd_is_valid(ev))
            continue;

        seg_write(ev);

        if (kbd_is_break(ev))
            continue;

        switch (kbd_to_key(ev)) {
        case KEY_UP:    y--; break;
        case KEY_DOWN:  y++; break;
        case KEY_LEFT:  x--; break;
        case KEY_RIGHT: x++; break;
        case KEY_ESC:
            dsp_clear('.');
            x=0;
            y=0;
            break;
        }
    }
}
