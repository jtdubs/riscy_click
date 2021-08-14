#pragma once

#include <stdint.h>
#include <stdbool.h>
#include "keys.h"
#include "mmap.h"

typedef uint32_t kbd_event_t;

static inline kbd_event_t kbd_read       (void);
static inline kbd_event_t kbd_read_valid (void);
static inline bool        kbd_is_valid   (kbd_event_t);
static inline bool        kbd_is_make    (kbd_event_t);
static inline bool        kbd_is_break   (kbd_event_t);
static inline uint8_t     kbd_to_key     (kbd_event_t);

static inline kbd_event_t kbd_read(void) {
    return (kbd_event_t)*PTR_KEYBOARD;
}

static inline kbd_event_t kbd_read_valid(void) {
    kbd_event_t e = kbd_read();
    while (! kbd_is_valid(e))
        e = kbd_read();
    return e;
}

static inline bool kbd_is_valid(kbd_event_t e) {
    return (e & 0x10000) == 0x10000;
}

static inline bool kbd_is_make(kbd_event_t e) {
    return (e & 0x100) == 0;
}

static inline bool kbd_is_break(kbd_event_t e) {
    return (e & 0x100) == 0x100;
}

static inline uint8_t kbd_to_key(kbd_event_t e) {
    return (uint8_t)(e & 0xFF);
}
