#include "sim_keyboard.h"
#include <GLFW/glfw3.h>
#include <queue>
#include <stdio.h>

uint16_t key_to_scancode(int key);

struct sim_keyboard {
    std::queue<uint8_t> keys;
    uint16_t current_word;
    uint8_t current_bit;
};

sim_keyboard_t *key_create() {
    sim_keyboard_t *keyboard = new sim_keyboard_t;
    keyboard->current_bit = 0xFF;
    return keyboard;
}

void key_destroy(sim_keyboard_t* keyboard) {
    delete keyboard;
}

void key_make(sim_keyboard_t* keyboard, int key) {
    uint16_t scancode = key_to_scancode(key);
    if (scancode >> 8)
        keyboard->keys.push(scancode >> 8);
    keyboard->keys.push(scancode & 0xFF);
}

void key_break(sim_keyboard_t* keyboard, int key) {
    uint16_t scancode = key_to_scancode(key);
    if (scancode >> 8)
        keyboard->keys.push(scancode >> 8);
    keyboard->keys.push(0xF0);
    keyboard->keys.push(scancode & 0xFF);
}

void key_tick(sim_keyboard_t* keyboard, unsigned char *ps2_clk, unsigned char *ps2_data) {
    if (keyboard->current_bit == 0xFF && !keyboard->keys.empty()) {
        uint8_t data = keyboard->keys.front();
        keyboard->keys.pop();
        uint8_t parity = 1;
        for (int i=0; i<8; i++)
            parity ^= (data >> i) & 1;
        keyboard->current_word = (data << 1) | (parity << 9) | (1 << 10);
        keyboard->current_bit = 0;
        // printf("START: data=%i, parity=%i, word=%i\n", data, parity, keyboard->current_word);
    }


    if (keyboard->current_bit < 11) {
        *ps2_clk = *ps2_clk ? 0 : 1;
        if (! *ps2_clk) {
            *ps2_data = (keyboard->current_word >> keyboard->current_bit) & 1;
            // printf("Clocking out: %i\n", *ps2_data);
            keyboard->current_bit++;
        }
    } else if (keyboard->current_bit == 11) {
        *ps2_clk  = 1;
        *ps2_data = 0;
        keyboard->current_bit = 0xFF;
    } else {
        *ps2_clk  = 1;
        *ps2_data = 0;
    }
}

uint16_t key_to_scancode(int key) {
    switch (key) {
        case GLFW_KEY_A:             return 0x001C;
        case GLFW_KEY_B:             return 0x0032;
        case GLFW_KEY_C:             return 0x0021;
        case GLFW_KEY_D:             return 0x0023;
        case GLFW_KEY_E:             return 0x0024;
        case GLFW_KEY_F:             return 0x002B;
        case GLFW_KEY_G:             return 0x0034;
        case GLFW_KEY_H:             return 0x0033;
        case GLFW_KEY_I:             return 0x0043;
        case GLFW_KEY_J:             return 0x003B;
        case GLFW_KEY_K:             return 0x0042;
        case GLFW_KEY_L:             return 0x004B;
        case GLFW_KEY_M:             return 0x003A;
        case GLFW_KEY_N:             return 0x0031;
        case GLFW_KEY_O:             return 0x0044;
        case GLFW_KEY_P:             return 0x004D;
        case GLFW_KEY_Q:             return 0x0015;
        case GLFW_KEY_R:             return 0x002D;
        case GLFW_KEY_S:             return 0x001B;
        case GLFW_KEY_T:             return 0x002C;
        case GLFW_KEY_U:             return 0x003C;
        case GLFW_KEY_V:             return 0x002A;
        case GLFW_KEY_W:             return 0x001D;
        case GLFW_KEY_X:             return 0x0022;
        case GLFW_KEY_Y:             return 0x0035;
        case GLFW_KEY_Z:             return 0x001A;
        case GLFW_KEY_0:             return 0x0045;
        case GLFW_KEY_1:             return 0x0016;
        case GLFW_KEY_2:             return 0x001E;
        case GLFW_KEY_3:             return 0x0026;
        case GLFW_KEY_4:             return 0x0025;
        case GLFW_KEY_5:             return 0x002E;
        case GLFW_KEY_6:             return 0x0036;
        case GLFW_KEY_7:             return 0x003D;
        case GLFW_KEY_8:             return 0x003E;
        case GLFW_KEY_9:             return 0x0046;
        case GLFW_KEY_F1:            return 0x0005;
        case GLFW_KEY_F2:            return 0x0006;
        case GLFW_KEY_F3:            return 0x0004;
        case GLFW_KEY_F4:            return 0x000C;
        case GLFW_KEY_F5:            return 0x0003;
        case GLFW_KEY_F6:            return 0x000B;
        case GLFW_KEY_F7:            return 0x0083;
        case GLFW_KEY_F8:            return 0x000A;
        case GLFW_KEY_F9:            return 0x0001;
        case GLFW_KEY_F10:           return 0x0009;
        case GLFW_KEY_F11:           return 0x0078;
        case GLFW_KEY_F12:           return 0x0007;
        case GLFW_KEY_KP_0:          return 0x0070;
        case GLFW_KEY_KP_1:          return 0x0069;
        case GLFW_KEY_KP_2:          return 0x0072;
        case GLFW_KEY_KP_3:          return 0x007A;
        case GLFW_KEY_KP_4:          return 0x006B;
        case GLFW_KEY_KP_5:          return 0x0073;
        case GLFW_KEY_KP_6:          return 0x0074;
        case GLFW_KEY_KP_7:          return 0x006C;
        case GLFW_KEY_KP_8:          return 0x0075;
        case GLFW_KEY_KP_9:          return 0x007D;
        case GLFW_KEY_KP_DIVIDE:     return 0xE04A;
        case GLFW_KEY_KP_MULTIPLY:   return 0x007C;
        case GLFW_KEY_KP_SUBTRACT:   return 0x007B;
        case GLFW_KEY_KP_ADD:        return 0x0079;
        case GLFW_KEY_KP_ENTER:      return 0xE05A;
        case GLFW_KEY_KP_DECIMAL:    return 0x0071;
        case GLFW_KEY_INSERT:        return 0xE070;
        case GLFW_KEY_HOME:          return 0xE06C;
        case GLFW_KEY_PAGE_UP:       return 0xE07D;
        case GLFW_KEY_PAGE_DOWN:     return 0xE07A;
        case GLFW_KEY_END:           return 0xE069;
        case GLFW_KEY_DELETE:        return 0xE071;
        case GLFW_KEY_UP:            return 0xE075;
        case GLFW_KEY_DOWN:          return 0xE072;
        case GLFW_KEY_LEFT:          return 0xE06B;
        case GLFW_KEY_RIGHT:         return 0xE074;
        case GLFW_KEY_LEFT_SHIFT:    return 0x0012;
        case GLFW_KEY_LEFT_CONTROL:  return 0x0014;
        case GLFW_KEY_LEFT_SUPER:    return 0xE01F;
        case GLFW_KEY_LEFT_ALT:      return 0x0011;
        case GLFW_KEY_RIGHT_SHIFT:   return 0x0059;
        case GLFW_KEY_RIGHT_CONTROL: return 0xE014;
        case GLFW_KEY_RIGHT_SUPER:   return 0xE027;
        case GLFW_KEY_RIGHT_ALT:     return 0xE011;
        case GLFW_KEY_MENU:          return 0xE02F;
        case GLFW_KEY_ESCAPE:        return 0x0076;
        case GLFW_KEY_GRAVE_ACCENT:  return 0x000E;
        case GLFW_KEY_MINUS:         return 0x004E;
        case GLFW_KEY_EQUAL:         return 0x0055;
        case GLFW_KEY_BACKSLASH:     return 0x005D;
        case GLFW_KEY_LEFT_BRACKET:  return 0x0054;
        case GLFW_KEY_RIGHT_BRACKET: return 0x005B;
        case GLFW_KEY_SEMICOLON:     return 0x004C;
        case GLFW_KEY_APOSTROPHE:    return 0x0052;
        case GLFW_KEY_COMMA:         return 0x0041;
        case GLFW_KEY_PERIOD:        return 0x0049;
        case GLFW_KEY_SLASH:         return 0x004A;
        case GLFW_KEY_BACKSPACE:     return 0x0066;
        case GLFW_KEY_TAB:           return 0x000D;
        case GLFW_KEY_SPACE:         return 0x0029;
        case GLFW_KEY_ENTER:         return 0x005A;
        case GLFW_KEY_CAPS_LOCK:     return 0x0058;
        case GLFW_KEY_SCROLL_LOCK:   return 0x007E;
        case GLFW_KEY_NUM_LOCK:      return 0x0077;
        default:                     return 0x0000;
    }
}
