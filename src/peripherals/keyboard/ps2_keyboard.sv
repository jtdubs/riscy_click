`timescale 1ns / 1ps
`default_nettype none

///
/// Keyboard Controller
///

module ps2_keyboard
    // Import Constants
    import common::*;
    import keyboard_common::*;
    (
        input  wire logic           clk_i,

        // PS2 Input
        input  wire byte_t          data_i,
        input  wire logic           valid_i,

        // Keyboard Output
        output wire ps2_kbd_event_t event_o,
        output wire logic           valid_o
    );

logic           extended_r = '0;
logic           is_break_r = '0;
ps2_kbd_event_t event_r    = '{ default: '0 };
logic           valid_r    = '0;

always_ff @(posedge clk_i) begin
    valid_r <= 1'b0;

    if (valid_i) begin
        unique if (data_i == 8'hF0)
            is_break_r <= 1'b1;
        else if (data_i == 8'hE0)
            extended_r <= 1'b1;
        else begin
            extended_r <= 1'b0;
            is_break_r <= 1'b0;
            event_r    <= '{ is_break_r, extended_r, data_i };
            valid_r    <= 1'b1;
        end
    end
end

assign event_o = event_r;
assign valid_o = valid_r;

endmodule
