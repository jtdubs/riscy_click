`timescale 1ns / 1ps
`default_nettype none

package common;

//
// CPU Architecture
//

// PC Word Sizes
typedef logic [ 7:0] byte_t;
typedef logic [31:0] word_t;
typedef logic [63:0] dword_t;

// Data Bus Chip Select
typedef struct packed {
    logic bios;
    logic ram;
    logic vram;
    logic keyboard;
    logic display;
    logic switches;
    logic uart;
    logic irq;
    logic vga;
} chip_select_t;

endpackage
