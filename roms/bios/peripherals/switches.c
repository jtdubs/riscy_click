#include "switches.h"
#include "interrupt.h"
#include "framebuffer.h"

#define SW_BASE   0xFFFF0300

#define PORT_DATA ((volatile uint16_t * const)(SW_BASE+0x00))

//
// Interrupt Handler
//

void on_switch_interrupt(void) {
    uint16_t sw = sw_read();
    fb_set_font(sw >> 14);
    fb_set_blink((sw >> 13) == 1);
    fb_set_underline((sw >> 12) == 1);
    fb_set_fg_color((sw & 0xF00) >> 4, (sw & 0xF0), (sw & 0x0F) << 4);
}


//
// Initialization
//

void sw_init(void) {
    irq_enable(IRQ_SWITCHES);
}


//
// Read
//

uint16_t sw_read(void) {
    return *PORT_DATA;
}
