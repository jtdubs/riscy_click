#ifndef __SIM_SEGDISPLAY_H
#define __SIM_SEGDISPLAY_H

#include <cstdint>

void seg_draw_digit(const char* str_id, uint8_t s);
void seg_tick(uint8_t* state, uint8_t anode, uint8_t cathode);

#endif
