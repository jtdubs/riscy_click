`timescale 1ns / 1ps
`default_nettype none

///
/// Keyboard Controller
///

module ps2_kbd
    // Import Constants
    import common::*;
    (
        input  wire logic           clk_i,
        input  wire logic           reset_i,

        // PS2 Input
        input  wire byte_t          data_i,
        input  wire logic           valid_i,

        // Keyboard Output
        output      ps2_kbd_event_t event_o,
        output      logic           valid_o
    );

logic extended_r = 1'b0;
logic is_break_r = 1'b0;

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
            event_o    <= '{ is_break_r, extended_r, data_i };
            valid_o    <= 1'b1;
        end
    end

    if (reset_i) begin
        extended_r <= 1'b0;
        is_break_r <= 1'b0;
        event_o <= '{ default: '0 };
    end
end

endmodule
