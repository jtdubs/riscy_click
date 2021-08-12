#ifndef __SIM_KEYBOARD_H
#define __SIM_KEYBOARD_H

#include <cstdint>

typedef struct sim_keyboard sim_keyboard_t;

sim_keyboard_t *key_create();
void key_destroy(sim_keyboard_t* keyboard);

void key_make(sim_keyboard_t* keyboard, int key);
void key_break(sim_keyboard_t* keyboard, int key);
void key_tick(sim_keyboard_t* keyboard, unsigned char* ps2_clk, unsigned char* ps2_data);

#endif
