`timescale 1ns / 1ps
`default_nettype none

///
/// Keyboard Controller
///

module keyboard
    // Import Constants
    import common::*;
    (
        input  wire logic        clk_i,
        input  wire logic        reset_i,

        // Keyboard Input
        input  wire logic        clk_kbd_async_i,
        input  wire logic        kbd_data_async_i,

        // Keyboard Output
        output      logic        ready_o,
        output      logic [7:0]  scancode_o
    );


//
// Clock in keyboard signals
//

logic clk_kbd_r;
logic kbd_data_r;

always_ff @(posedge clk_i) begin
    clk_kbd_r  <= clk_kbd_async_i;
    kbd_data_r <= kbd_data_async_i;
end


//
// Falling edge detection
//

logic falling_edge_w;

// falling edge detection
always_comb begin
    falling_edge_w = clk_kbd_r && !clk_kbd_async_i;
end


//
// State Machine
//

//   idle           recv
//   v  |           v  |
//   IDLE --start-> DATA --check-> PARITY --pass-> STOP
//   ^  ^                            |              |
//   |  |-----------fail-------------|              |
//   |                                              |
//   |-----------------key,abort--------------------|

typedef enum {
    IDLE   = 2'b00,
    DATA   = 2'b01,
    PARITY = 2'b10,
    STOP   = 2'b11
} kbd_state_t;

// state
kbd_state_t kbd_state_r, kbd_state_w;
logic [3:0] bits_r;
logic [7:0] scancode_r;
logic       parity_valid_w;
logic       stop_valid_w;

// transitions
logic idle_w  = falling_edge_w && (kbd_state_r == IDLE)   && (kbd_data_r == 1'b1);
logic start_w = falling_edge_w && (kbd_state_r == IDLE)   && (kbd_data_r == 1'b0);
logic recv_w  = falling_edge_w && (kbd_state_r == DATA)   && (bits_r <  4'd8);
logic check_w = falling_edge_w && (kbd_state_r == DATA)   && (bits_r == 4'd8);
logic pass_w  = falling_edge_w && (kbd_state_r == PARITY) &&  parity_valid_w;
logic fail_w  = falling_edge_w && (kbd_state_r == PARITY) && !parity_valid_w;
logic key_w   = falling_edge_w && (kbd_state_r == STOP)   &&  stop_valid_w;
logic abort_w = falling_edge_w && (kbd_state_r == STOP)   && !stop_valid_w;

// stop bit
always_comb stop_valid_w   = (kbd_data_r == 1'b1);
always_comb parity_valid_w = 1'b1;

// next state
always_comb begin
    unique if (idle_w || fail_w || key_w || abort_w)
        kbd_state_w = IDLE;
    else if (start_w || recv_w)
        kbd_state_w = DATA;
    else if (check_w)
        kbd_state_w = PARITY;
    else if (pass_w)
        kbd_state_w = STOP;
    else
        kbd_state_w = kbd_state_r;
end

// advance
always_ff @(posedge clk_i) begin
    if (recv_w || check_w) begin
        bits_r     <= bits_r + 1;
        scancode_r <= { scancode_r[7:1] | kbd_data_r };
    end else if (fail_w || abort_w) begin
        bits_r     <= 4'b0;
        scancode_r <= 8'b0;
    end else if (key_w) begin
        bits_r     <= 4'b0;
        scancode_r <= 8'b0;
        ready_o    <= 1'b1;
        scancode_o <= bits_r;
    end

    if (reset_i) begin
        kbd_state_r <= IDLE;
        bits_r      <= 4'b0;
        scancode_r  <= 8'b0;
        ready_o     <= 1'b0;
        scancode_o  <= 8'b0;
    end
end

endmodule
