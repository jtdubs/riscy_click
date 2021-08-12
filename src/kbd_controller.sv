`timescale 1ns / 1ps
`default_nettype none

///
/// Keyboard Controller
///

module kbd_controller
    // Import Constants
    import common::*;
    (
        // Clocks
        input  wire logic        clk_i,            // Clock
        input  wire logic        reset_i,          // Reset

        // Inputs
        input  wire logic        ps2_clk_async_i,  // PS2 HID clock (async)
        input  wire logic        ps2_data_async_i, // PS2 HID data (async)

        // Outputs
        input  wire logic        read_enable_i,
        output      kbd_event_t  read_data_o,
        output      logic        read_valid_o
    );


//
// Keyboard Controller
//

byte_t      ps2_data_w;
logic       ps2_valid_w;
kbd_event_t kbd_event_w;
logic       kbd_valid_w;

ps2_rx ps2_rx (
    .clk_i            (clk_i),
    .reset_i          (reset_i),
    .ps2_clk_async_i  (ps2_clk_async_i),
    .ps2_data_async_i (ps2_data_async_i),
    .data_o           (ps2_data_w),
    .valid_o          (ps2_valid_w)
);

ps2_kbd ps2_kbd (
    .clk_i            (clk_i),
    .reset_i          (reset_i),
    .data_i           (ps2_data_w),
    .valid_i          (ps2_valid_w),
    .event_o          (kbd_event_w),
    .valid_o          (kbd_valid_w)
);

fifo #(
    .WIDTH(10),
    .DEPTH(32)
) fifo (
    .clk_i               (clk_i),
    .reset_i             (reset_i),
    .write_data_i        (kbd_event_w),
    .write_enable_i      (kbd_valid_w),
    .read_enable_i       (read_enable_i),
    .read_data_o         (read_data_o),
    .read_valid_o        (read_valid_o),
    .fifo_empty_o        (),
    .fifo_almost_empty_o (),
    .fifo_almost_full_o  (),
    .fifo_full_o         ()
);

endmodule
