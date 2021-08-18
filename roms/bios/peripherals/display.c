#include "display.h"

#define DSP_BASE     0xFFFF0200

#define PORT_CONTROL ((volatile uint32_t * const)(DSP_BASE+0x00))
#define PORT_DATA    ((volatile uint32_t * const)(DSP_BASE+0x04))

//
// Initialization
//

void dsp_init(void) {
}


//
// Enable & Disable
//

void dsp_enable(void) {
    dsp_set_enabled(true);
}

void dsp_disable(void) {
    dsp_set_enabled(false);
}

void dsp_set_enabled(bool enabled) {
    *PORT_CONTROL = enabled ? 1 : 0;
}


//
// Read & Write
//

uint32_t dsp_read(void) {
    return *PORT_DATA;
}

void dsp_write(uint32_t value) {
    *PORT_DATA = value;
}
