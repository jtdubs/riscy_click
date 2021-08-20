#include "peripherals/keyboard.h"
#include "peripherals/display.h"
#include "peripherals/framebuffer.h"
#include "console.h"

#include <stdint.h>
#include <stdbool.h>

typedef struct {
    int shift  : 1;
    int ctrl   : 1;
    int alt    : 1;
    int meta   : 1;
    int caps   : 1;
    int num    : 1;
    int scroll : 1;
} control_key_t;

control_key_t CONTROL_STATE = { 0 };

const char TRANSLATION_TABLE[256] = {
    // UNSHIFTED
    '\x00' , '\x1B' ,  '1'   ,  '2'   ,  '3'   ,  '4'   ,  '5'   ,  '6'   ,
     '7'   ,  '8'   ,  '9'   ,  '0'   ,  '-'   ,  '='   , '\x08' , '\x09' ,
     'q'   ,  'w'   ,  'e'   ,  'r'   ,  't'   ,  'y'   ,  'u'   ,  'i'   ,
     'o'   ,  'p'   ,  '['   ,  ']'   , '\x0A' , '\x00' ,  'a'   ,  's'   ,
     'd'   ,  'f'   ,  'g'   ,  'h'   ,  'j'   ,  'k'   ,  'l'   ,  ';'   ,
     '\''  ,  '`'   , '\x00' ,  '\\'  ,  'z'   ,  'x'   ,  'c'   ,  'v'   ,
     'b'   ,  'n'   ,  'm'   ,  ','   ,  '.'   ,  '/'   , '\x00' ,  '*'   ,
    '\x00' ,  ' '   , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,
    '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,  '7'   ,
     '8'   ,  '9'   ,  '-'   ,  '4'   ,  '5'   ,  '6'   ,  '+'   ,  '1'   ,
     '2'   ,  '3'   ,  '0'   ,  '.'   , '\x00' , '\x00' , '\x00' , '\x00' ,
    '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,
    '\x0A' , '\x00' ,  '/'   , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,
    '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x7F' ,
    '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,
    '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,
    // SHIFTED
    '\x00' , '\x1B' ,  '!'   ,  '@'   ,  '#'   ,  '$'   ,  '%'   ,  '^'   ,
     '&'   ,  '*'   ,  '('   ,  ')'   ,  '_'   ,  '+'   , '\x08' , '\x09' ,
     'Q'   ,  'W'   ,  'E'   ,  'R'   ,  'T'   ,  'Y'   ,  'U'   ,  'I'   ,
     'O'   ,  'P'   ,  '{'   ,  '}'   , '\x0A' , '\x00' ,  'A'   ,  'S'   ,
     'D'   ,  'F'   ,  'G'   ,  'H'   ,  'J'   ,  'K'   ,  'L'   ,  ':'   ,
     '"'   ,  '~'   , '\x00' ,  '|'   ,  'Z'   ,  'X'   ,  'C'   ,  'V'   ,
     'B'   ,  'N'   ,  'M'   ,  '<'   ,  '>'   ,  '?'   , '\x00' ,  '*'   ,
    '\x00' ,  ' '   , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,
    '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,  '7'   ,
     '8'   ,  '9'   ,  '-'   ,  '4'   ,  '5'   ,  '6'   ,  '+'   ,  '1'   ,
     '2'   ,  '3'   ,  '0'   ,  '.'   , '\x00' , '\x00' , '\x00' , '\x00' ,
    '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,
    '\x0A' , '\x00' ,  '/'   , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,
    '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x7F' ,
    '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,
    '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' , '\x00' ,
};

char con_getch(void) {
    while (true) {
        kbd_event_t e = kbd_wait();

        uint8_t key = kbd_to_key(e);

        dsp_write(key);

        switch (key) {
            case KEY_LEFTSHIFT:
            case KEY_RIGHTSHIFT:
                CONTROL_STATE.shift  = kbd_is_make(e) ? 1 : 0;
                break;
            case KEY_LEFTCTRL:
            case KEY_RIGHTCTRL:
                CONTROL_STATE.ctrl   = kbd_is_make(e) ? 1 : 0;
                break;
            case KEY_LEFTALT:
            case KEY_RIGHTALT:
                CONTROL_STATE.alt    = kbd_is_make(e) ? 1 : 0;
                break;
            case KEY_LEFTMETA:
            case KEY_RIGHTMETA:
                CONTROL_STATE.meta   = kbd_is_make(e) ? 1 : 0;
                break;
            case KEY_CAPSLOCK:
                if (kbd_is_make(e))
                    CONTROL_STATE.caps = !CONTROL_STATE.caps;
                break;
            case KEY_NUMLOCK:
                if (kbd_is_make(e))
                    CONTROL_STATE.num = !CONTROL_STATE.num;
                break;
            case KEY_SCROLLLOCK:
                if (kbd_is_make(e))
                    CONTROL_STATE.scroll = !CONTROL_STATE.scroll;
                break;
            default:
                if (kbd_is_make(e)) {
                    char result = TRANSLATION_TABLE[(CONTROL_STATE.shift << 7) | key];
                    if (result >= 'a' && result <= 'z' && CONTROL_STATE.caps)
                        result -= 0x20;
                    else if (result >= 'A' && result <= 'Z' && CONTROL_STATE.caps)
                        result += 0x20;
                    return result;
                }
                break;
        }
    }
}
