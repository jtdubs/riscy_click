#include "keyboard.h"
#include "framebuffer.h"
#include "interrupt.h"

#include <stdint.h>
#include <stdbool.h>

#define KBD_BASE (0xFFFF0400)

#define PORT_STATUS  ((volatile uint32_t * const)KBD_BASE+0x00)
#define PORT_CONTROL ((volatile uint32_t * const)KBD_BASE+0x04)


//
// Interrupt Handling
//

static volatile kbd_event_t next_key        = 0;
static volatile int         interrupt_count = 0;

void on_keyboard_interrupt(void) {
    interrupt_count++;
    next_key = kbd_read();
}


//
// Initialization
//

void kbd_init(void) {
}


//
// Reading
//

kbd_event_t kbd_read(void) {
    return (kbd_event_t)*PORT_STATUS;
}

kbd_event_t kbd_wait(void) {
    irq_enable(IRQ_KEYBOARD);
    while (interrupt_count == 0) {
        irq_wait();
    }
    irq_disable(IRQ_KEYBOARD);

    char c = fb_read(10+interrupt_count, FrameBufferHeight-1);
    c = (c == ' ') ? 'A' : (c+1);
    fb_write(10+interrupt_count, FrameBufferHeight-1, c);
    interrupt_count = 0;

    return next_key;
}


//
// Decoding
//

bool kbd_is_valid(kbd_event_t e) {
    return (e & 0x10000) == 0x10000;
}

bool kbd_is_make(kbd_event_t e) {
    return (e & 0x100) == 0;
}

bool kbd_is_break(kbd_event_t e) {
    return (e & 0x100) == 0x100;
}

key_t kbd_to_key(kbd_event_t e) {
    return (key_t)(e & 0xFF);
}
