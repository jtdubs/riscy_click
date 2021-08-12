`timescale 1ns / 1ps
`default_nettype none

// Was:
// - 54 cells
// - 63 nets

///
/// Keyboard Controller
///

module ps2_rx
    // Import Constants
    import common::*;
    (
        input  wire logic  clk_i,
        input  wire logic  reset_i,

        // PS2 Input
        input  wire logic  ps2_clk_async_i,
        input  wire logic  ps2_data_async_i,

        // PS2 Output
        output      byte_t data_o,
        output      logic  valid_o
    );


//
// Clock in PS2 signals
//

logic [1:0] ps2_clk_r;
logic ps2_data_r;

always_ff @(posedge clk_i) begin
    ps2_clk_r  <= { ps2_clk_r[0], ps2_clk_async_i };
    ps2_data_r <= ps2_data_async_i;
end


//
// Falling edge detection
//

logic falling_edge_w;

// falling edge detection
always_comb begin
    falling_edge_w = ps2_clk_r[1] && !ps2_clk_r[0];
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

typedef enum logic [1:0] {
    IDLE   = 2'b00,
    DATA   = 2'b01,
    PARITY = 2'b10,
    STOP   = 2'b11
} ps2_state_t;

// state
ps2_state_t ps2_state_r, ps2_state_w;
logic [3:0] bits_r;
byte_t      data_r;
logic       parity_r, parity_w;

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
    idle_w  = falling_edge_w && (ps2_state_r == IDLE)   && (ps2_data_r == 1'b1);
    start_w = falling_edge_w && (ps2_state_r == IDLE)   && (ps2_data_r == 1'b0);
    recv_w  = falling_edge_w && (ps2_state_r == DATA)   && (bits_r <  4'd7);
    check_w = falling_edge_w && (ps2_state_r == DATA)   && (bits_r == 4'd7);
    pass_w  = falling_edge_w && (ps2_state_r == PARITY) &&  parity_w;
    fail_w  = falling_edge_w && (ps2_state_r == PARITY) && !parity_w;
    key_w   = falling_edge_w && (ps2_state_r == STOP)   &&  ps2_data_r;
    abort_w = falling_edge_w && (ps2_state_r == STOP)   && !ps2_data_r;
end

// keep track of parity
always_comb parity_w = (parity_r + ps2_data_r);

// determine next state
always_comb begin
    if (idle_w || fail_w || key_w || abort_w)
        ps2_state_w = IDLE;
    else if (start_w || recv_w)
        ps2_state_w = DATA;
    else if (check_w)
        ps2_state_w = PARITY;
    else if (pass_w)
        ps2_state_w = STOP;
    else
        ps2_state_w = ps2_state_r;
end

// advance to next state
always_ff @(posedge clk_i) begin
    ps2_state_r <= ps2_state_w;

    if (reset_i)
        ps2_state_r <= IDLE;
end

// take transition actions
always_ff @(posedge clk_i) begin
    data_o   <= data_r;
    valid_o  <= key_w;

    priority if (start_w) begin
        bits_r   <= 1'b0;
        parity_r <= 1'b0;
    end else if (falling_edge_w) begin
        bits_r   <= bits_r + 1;
        parity_r <= parity_w;
    end

    if (recv_w || check_w) begin
        data_r   <= { ps2_data_r, data_r[7:1] };
    end

    if (reset_i) begin
        bits_r   <= 4'b0;
        data_r   <= 8'b0;
        parity_r <= 1'b0;
        data_o   <= 8'b0;
        valid_o  <= 1'b0;
    end
end

endmodule
