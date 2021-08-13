#pragma once

#include <stdint.h>
#include <stdbool.h>
#include "keys.h"
#include "mmap.h"

typedef uint32_t kbd_event_t;

inline kbd_event_t kbd_read(void);
inline bool        kbd_is_valid (kbd_event_t);
inline bool        kbd_is_make  (kbd_event_t);
inline bool        kbd_is_break (kbd_event_t);
inline uint8_t     kbd_to_key   (kbd_event_t);

inline kbd_event_t kbd_read(void) {
    return (kbd_event_t)*PTR_KEYBOARD;
}

inline bool kbd_is_valid(kbd_event_t e) {
    return (e & 0x10000) == 0x10000;
}

inline bool kbd_is_make(kbd_event_t e) {
    return (e & 0x100) == 0;
}

inline bool kbd_is_break(kbd_event_t e) {
    return (e & 0x100) == 0x100;
}

inline uint8_t kbd_to_key(kbd_event_t e) {
    return (uint8_t)(e & 0xFF);
}
