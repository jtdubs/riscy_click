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

logic [1:0] ps2_clk_r  = '0;
logic       ps2_data_r = '0;

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
// Packet Validity
//

logic parity_good_w;
logic start_good_w;
logic stop_good_w;
logic packet_good_w;

always_comb begin
    start_good_w = !packet_r[0];
    stop_good_w  =  packet_r[10];

    parity_good_w =
        packet_r[1] ^
        packet_r[2] ^
        packet_r[3] ^
        packet_r[4] ^
        packet_r[5] ^
        packet_r[6] ^
        packet_r[7] ^
        packet_r[8] ^
        packet_r[9];

    packet_good_w = start_good_w && stop_good_w && parity_good_w;
end


//
// Shift in new bits, resetting on good packet
//

logic [10:0] packet_r = 11'b11111111111;

always_ff @(posedge clk_i) begin
    if (falling_edge_w)
        packet_r <= { ps2_data_r, packet_r[10:1] };
    else if (packet_good_w)
        packet_r <= 11'b11111111111;

    if (reset_i)
        packet_r <= 11'b11111111111;
end


//
// Emit good packets
//

always_ff @(posedge clk_i) begin
    data_o   <= packet_r[8:1];
    valid_o  <= packet_good_w;

    if (reset_i) begin
        data_o   <= 8'b0;
        valid_o  <= 1'b0;
    end
end

endmodule
