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

logic [1:0] clk_kbd_r;
logic kbd_data_r;

always_ff @(posedge clk_i) begin
    clk_kbd_r  <= { clk_kbd_r[0], clk_kbd_async_i };
    kbd_data_r <= kbd_data_async_i;
end


//
// Falling edge detection
//

logic falling_edge_w;

// falling edge detection
always_comb begin
    falling_edge_w = clk_kbd_r[1] && !clk_kbd_r[0];
end


//
// State Machine
//

//  reject          recv
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
logic       parity_r, parity_w;
logic       stop_valid_w;

// transitions
logic idle_w;
logic start_w;
logic recv_w;
logic check_w;
logic pass_w;
logic fail_w;
logic key_w;
logic abort_w;

always_comb begin
    idle_w  = falling_edge_w && (kbd_state_r == IDLE)   && (kbd_data_r == 1'b1);
    start_w = falling_edge_w && (kbd_state_r == IDLE)   && (kbd_data_r == 1'b0);
    recv_w  = falling_edge_w && (kbd_state_r == DATA)   && (bits_r <  4'd7);
    check_w = falling_edge_w && (kbd_state_r == DATA)   && (bits_r == 4'd7);
    pass_w  = falling_edge_w && (kbd_state_r == PARITY) &&  parity_w;
    fail_w  = falling_edge_w && (kbd_state_r == PARITY) && !parity_w;
    key_w   = falling_edge_w && (kbd_state_r == STOP)   &&  stop_valid_w;
    abort_w = falling_edge_w && (kbd_state_r == STOP)   && !stop_valid_w;
end

// stop bit
always_comb stop_valid_w = (kbd_data_r == 1'b1);
always_comb parity_w     = (parity_r + kbd_data_r);

// determine next state
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

// advance to next state
always_ff @(posedge clk_i) begin
    kbd_state_r <= kbd_state_w;

    if (reset_i)
        kbd_state_r <= IDLE;
end

// take transition actions
always_ff @(posedge clk_i) begin
    if (recv_w || check_w) begin
        bits_r     <= bits_r + 1;
        scancode_r <= { scancode_r[6:0], kbd_data_r };
        parity_r   <= parity_w;
    end else if (fail_w || abort_w) begin
        bits_r     <= 4'b0;
        scancode_r <= 8'b0;
        parity_r   <= 1'b0;
    end else if (key_w) begin
        bits_r     <= 4'b0;
        scancode_r <= 8'b0;
        parity_r   <= 1'b0;
        ready_o    <= 1'b1;
        scancode_o <= scancode_r;
    end

    if (reset_i) begin
        bits_r      <= 4'b0;
        scancode_r  <= 8'b0;
        parity_r   <= 1'b0;
        ready_o     <= 1'b0;
        scancode_o  <= 8'b0;
    end
end

endmodule
