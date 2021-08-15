#include <stdint.h>
#include <stdbool.h>
#include "keyboard.h"
#include "display.h"
#include "keys.h"
#include "mmap.h"

extern void _global_enable_interrupts(void);
extern void _global_disable_interrupts(void);

static volatile kbd_event_t next_key        = 0;
static volatile int         interrupt_count = 0;

kbd_event_t kbd_read(void) {
    return (kbd_event_t)*PTR_KEYBOARD;
}

kbd_event_t kbd_wait(void) {
    _global_enable_interrupts();
    while (interrupt_count == 0) {
        __asm__ volatile ("wfi");
    }
    _global_disable_interrupts();

    if (interrupt_count) {
        char c = dsp_read(10+interrupt_count, DSP_HEIGHT-1);
        c = (c == ' ') ? 'A' : (c+1);
        dsp_write(10+interrupt_count, DSP_HEIGHT-1, c);
        interrupt_count = 0;
    }

    interrupt_count = 0;
    return next_key;
}


void on_kbd_interrupt() {
    interrupt_count++;
    next_key = kbd_read();
}

