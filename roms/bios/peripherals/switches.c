#include "switches.h"

#define SW_BASE   0xFFFF0300

#define PORT_DATA ((volatile uint16_t * const)(SW_BASE+0x00))

//
// Interrupt Handler
//

void on_switch_interrupt(void) {
}


//
// Initialization
//

void sw_init(void) {
}


//
// Read
//

uint16_t sw_read(void) {
    return *PORT_DATA;
}
