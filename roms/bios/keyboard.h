#pragma once

#include <stdint.h>
#include <stdbool.h>
#include "keys.h"

typedef uint32_t kbd_event_t;

kbd_event_t kbd_read(void);

bool        kbd_is_valid (kbd_event_t);
bool        kbd_is_make  (kbd_event_t);
bool        kbd_is_break (kbd_event_t);
uint8_t     kbd_to_key   (kbd_event_t);
