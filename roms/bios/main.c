#include "mmap.h"
#include "keyboard.h"
#include "display.h"
#include "segment.h"
#include "console.h"

#include <stdint.h>

int main() {
    dsp_clear('.');

    // main loop
    uint8_t x = 0;
    uint8_t y = 0;

    for (;;) {
        dsp_write(x++, y, con_getch());
    }
}
