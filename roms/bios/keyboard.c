#include "keyboard.h"
#include "mmap.h"

kbd_event_t kbd_read(void) {
    return (kbd_event_t)*PTR_KEYBOARD;
}

bool kbd_is_valid(kbd_event_t e) {
    return (e & 0x10000) == 0x10000;
}

bool kbd_is_make(kbd_event_t e) {
    return (e & 0x100) == 0;
}

bool kbd_is_break(kbd_event_t e) {
    return (e & 0x100) == 0x100;
}

uint8_t kbd_to_key(kbd_event_t e) {
    return (uint8_t)(e & 0xFF);
}
