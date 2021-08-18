`timescale 1ns / 1ps
`default_nettype none

package kbd_common;

import common::*;

typedef struct packed {
    logic  is_break;
    logic  extended;
    byte_t scancode;
} ps2_kbd_event_t;

typedef struct packed {
    logic  is_break;
    byte_t vk_code;
} kbd_event_t;

endpackage
