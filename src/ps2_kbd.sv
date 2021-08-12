`timescale 1ns / 1ps
`default_nettype none

///
/// Keyboard Controller
///

module ps2_rx
    // Import Constants
    import common::*;
    (
        input  wire logic       clk_i,
        input  wire logic       reset_i,

        // PS2 Input
        input  wire byte_t      data_i,
        input  wire logic       valid_i,

        // Keyboard Output
        output      kbd_event_l event_o,
        output      logic       valid_o
    );

typedef struct packed {
    byte_t scancode;
    logic  extended;
    logic  is_break;
} kbd_event_t;

logic extended_r;
logic is_break_r;

always_ff @(posedge clk_i) begin
    valid_o <= 1'b0;

    if (valid_i) begin
        unique if (data_i == 8'hF0)
            is_break_r <= 1'b1;
        else if (data_i == 8'hE0)
            extended_r <= 1'b1;
        else begin
            extended_r <= 1'b0;
            is_break_r <= 1'b0;
            event_o    <= '{ data_i, extended_r, is_break_r };
            valid_o    <= 1'b1;
        end
    end

    if (reset_i) begin
        event_r <= '{ default: '0 };
    end
end

endmodule
