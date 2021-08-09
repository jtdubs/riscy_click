#ifndef __SIM_SEGDISPLAY_H
#define __SIM_SEGDISPLAY_H

void seg_draw_digit(const char* str_id, unsigned char s);
void seg_tick(unsigned char* state, int anode, int cathode);

#endif
