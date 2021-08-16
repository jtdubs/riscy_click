`timescale 1ns / 1ps
`default_nettype none

///
/// UART Receiver
///

module uart_rx
    // Import Constants
    import common::*;
    (
        input  wire logic         clk_i,
        input  wire uart_config_t config_i,
        input  wire logic         rxd_i,
        output wire logic [7:0]   data_o,
        output wire logic         data_valid_o
    );


//
// Register UART input
//

logic [2:0] bits_r = 3'b000;

always_ff @(posedge clk_i) begin
    bits_r <= { rxd_i, bits_r[2:1] };
end


//
// Centering
//

logic [23:0] cycles_to_center = '0;

always_ff @(posedge clk_i) begin
    priority if (bits_r[0] != bits_r[1])
        // if edge found, wait a half-period to center
        cycles_to_center <= { 1'b0, config_i.samples_per_bit[23:1] };
    else if (cycles_to_center == 24'b0)
        // if center reached, next center is one period away
        cycles_to_center <= config_i.samples_per_bit;
    else
        // otherwise, we are approaching the center
        cycles_to_center <= cycles_to_center - 1;
end


//
// Shift Register
//

logic [11:0] packet_r      = 12'hFFF;
logic        packet_good_w = 1'b0;

always_ff @(posedge clk_i) begin
    if (cycles_to_center == 24'b0)
        packet_r <= { bits_r[0], packet_r[11:1] };

    if (packet_good_w)
        packet_r <= 12'hFFF;
end


//
// Start Bit
//

logic start_good_w;
always_comb start_good_w = !packet_r[0];


//
// Parity
//

logic packet_parity_w;
logic odd_parity_w;
logic parity_good_w;

always_comb begin
    packet_parity_w = (config_i.data_bits == DATA_SEVEN) ? packet_r[7] : packet_r[8];

    odd_parity_w =
        packet_r[1] ^
        packet_r[2] ^
        packet_r[3] ^
        packet_r[4] ^
        packet_r[5] ^
        packet_r[6] ^
        packet_r[7];

    if (config_i.data_bits == DATA_EIGHT)
        odd_parity_w = odd_parity_w ^ packet_r[8];

    unique case (config_i.parity)
    PARITY_NONE:  parity_good_w = 1'b1;
    PARITY_EVEN:  parity_good_w = (packet_parity_w != odd_parity_w);
    PARITY_ODD:   parity_good_w = (packet_parity_w == odd_parity_w);
    PARITY_MARK:  parity_good_w = (packet_parity_w == 1'b1);
    PARITY_SPACE: parity_good_w = (packet_parity_w == 1'b0);
    endcase
end


//
// Stop Bits
//

logic [1:0] stop_bits_w;
logic       stop_bits_good_w;

always_comb begin
    unique case (config_i.data_bits)
        DATA_SEVEN: stop_bits_w = (config_i.parity == PARITY_NONE) ? packet_r[ 9:8] : packet_r[10: 9];
        DATA_EIGHT: stop_bits_w = (config_i.parity == PARITY_NONE) ? packet_r[10:9] : packet_r[11:10];
    endcase

    stop_bits_good_w = (config_i.stop_bits == STOP_ONE) ? stop_bits_w[0] : (stop_bits_w[0] && stop_bits_w[1]);
end


//
// Packet Good
//

always_comb packet_good_w = start_good_w && parity_good_w && stop_bits_good_w;


//
// Output
//

logic [7:0] data_r = '0;
logic       data_valid_r = '0;

always_ff @(posedge clk_i) begin
    data_valid_r <= packet_good_w;

    if (packet_good_w) begin
        data_r <= packet_r[8:1];
    end
end

assign data_o       = data_r;
assign data_valid_o = data_valid_r;

endmodule
