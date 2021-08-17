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
        input  wire logic        clk_i,      // Clock

        // Inputs
        input  wire logic        ps2_clk_i,  // PS2 HID clock
        input  wire logic        ps2_data_i, // PS2 HID data

        // Outputs
        input  wire logic        read_enable_i,
        output wire kbd_event_t  read_data_o,
        output wire logic        read_valid_o,
        output      logic        interrupt_o
    );



// PS2 RX
byte_t      ps2_data_w;
logic       ps2_valid_w;

ps2_rx ps2_rx (
    .clk_i      (clk_i),
    .ps2_clk_i  (ps2_clk_i),
    .ps2_data_i (ps2_data_i),
    .data_o     (ps2_data_w),
    .valid_o    (ps2_valid_w)
);


// Keyboard
ps2_kbd_event_t ps2_kbd_event_w;
logic           ps2_kbd_valid_w;

ps2_kbd ps2_kbd (
    .clk_i      (clk_i),
    .data_i     (ps2_data_w),
    .valid_i    (ps2_valid_w),
    .event_o    (ps2_kbd_event_w),
    .valid_o    (ps2_kbd_valid_w)
);


// Keycode Translation ROM
logic           is_break_r = '0;
byte_t          vk_w;
logic           vk_valid_r = '0;

keycode_rom #(.CONTENTS("krom.mem")) krom (
    .clk_i         (clk_i),
    .read_enable_i (ps2_kbd_valid_w), // 1'b1),
    .read_addr_i   (ps2_kbd_event_w[8:0]),
    .read_data_o   (vk_w)
);

always_ff @(posedge clk_i) begin
    is_break_r  <= ps2_kbd_event_w.is_break;
    vk_valid_r  <= ps2_kbd_valid_w;
end


// Buffer
fifo #(
    .DATA_WIDTH(9),
    .ADDR_WIDTH(5)
) fifo (
    .clk_i               (clk_i),
    .write_data_i        ({ is_break_r, vk_w }),
    .write_enable_i      (vk_valid_r),
    .read_enable_i       (read_enable_i),
    .read_data_o         (read_data_o),
    .read_valid_o        (read_valid_o),
    .fifo_empty_o        (),
    .fifo_almost_empty_o (),
    .fifo_almost_full_o  (),
    .fifo_full_o         ()
);

// interrupt
always_comb interrupt_o = read_valid_o;

endmodule
