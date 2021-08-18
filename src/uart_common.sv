`timescale 1ns / 1ps
`default_nettype none

package uart_common;

import common::*;

typedef enum logic {
    DATA_SEVEN = 1'b0,
    DATA_EIGHT = 1'b1
} data_bits_t;

typedef enum logic [2:0] {
    PARITY_NONE   = 3'b000,
    PARITY_EVEN   = 3'b100,
    PARITY_ODD    = 3'b101,
    PARITY_MARK   = 3'b110,
    PARITY_SPACE  = 3'b111
} parity_t;

typedef enum logic {
    STOP_ONE = 1'b0,
    STOP_TWO = 1'b1
} stop_bits_t;

typedef enum logic [1:0] {
    FLOW_NONE     = 2'b00,
    FLOW_RTS_CTS  = 2'b01,
    FLOW_DSR_DTR  = 2'b10,
    FLOW_XON_XOFF = 2'b11
} flow_control_t;

typedef struct packed {
    data_bits_t    data_bits;
    parity_t       parity;
    stop_bits_t    stop_bits;
    flow_control_t flow_control;
    logic          reserved;
    logic [23:0]   samples_per_bit;
} uart_config_t;

endpackage
