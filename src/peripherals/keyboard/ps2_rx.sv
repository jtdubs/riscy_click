`timescale 1ns / 1ps
`default_nettype none

///
/// PS/2 Receiver
///

module ps2_rx
    // Import Constants
    import common::*;
    (
        input  wire logic  clk_i,

        // PS2 Input
        input  wire logic  ps2_clk_i,
        input  wire logic  ps2_data_i,

        // PS2 Output
        output wire byte_t data_o,
        output wire logic  valid_o
    );


//
// Clock in PS2 signals
//

logic [1:0] ps2_clk_r  = '0;
logic       ps2_data_r = '0;

always_ff @(posedge clk_i) begin
    ps2_clk_r  <= { ps2_clk_r[0], ps2_clk_i };
    ps2_data_r <= ps2_data_i;
end


//
// Falling edge detection
//

logic falling_edge;

// falling edge detection
always_comb begin
    falling_edge = ps2_clk_r[1] && !ps2_clk_r[0];
end


//
// Packet Validity
//

logic [10:0] packet_r = 11'b11111111111;
logic        parity_good;
logic        start_good;
logic        stop_good;
logic        packet_good;

always_comb begin
    start_good = !packet_r[0];
    stop_good  =  packet_r[10];

    parity_good =
        packet_r[1] ^
        packet_r[2] ^
        packet_r[3] ^
        packet_r[4] ^
        packet_r[5] ^
        packet_r[6] ^
        packet_r[7] ^
        packet_r[8] ^
        packet_r[9];

    packet_good = start_good && stop_good && parity_good;
end


//
// Shift in new bits, resetting on good packet
//

always_ff @(posedge clk_i) begin
    if (falling_edge)
        packet_r <= { ps2_data_r, packet_r[10:1] };
    else if (packet_good)
        packet_r <= 11'b11111111111;
end


//
// Emit good packets
//

byte_t data_r  = '0;
assign data_o  = data_r;

logic  valid_r = '0;
assign valid_o = valid_r;

always_ff @(posedge clk_i) begin
    data_r  <= packet_r[8:1];
    valid_r <= packet_good;
end

endmodule
