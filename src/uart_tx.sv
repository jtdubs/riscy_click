`timescale 1ns / 1ps
`default_nettype none

///
/// UART Transmitter
///

module uart_tx
    // Import Constants
    import common::*;
    (
        input  wire logic         clk_i,
        input  wire uart_config_t config_i,
        output wire logic         txd_o,
        output      logic         read_enable_o,
        input  wire logic [7:0]   read_data_i,
        input  wire logic         read_valid_i
    );

//
// Counter
//

logic [23:0] cycles_r = 24'b0;

always_ff @(posedge clk_i) begin
    if (cycles_r == 24'b0)
        cycles_r <= config_i.samples_per_bit;
    else
        cycles_r <= cycles_r - 1;
end


//
// Shift Register
//

logic [11:0] packet_r = '0;
logic        txd_w = '1;

always_ff @(posedge clk_i) begin
    if (cycles_r == 24'b0) begin
        packet_r <= { 1'b0, packet_r[11:1] };
        txd_w    <= (packet_r == '0) ? 1'b1 : packet_r[0];
    end
end

assign txd_o = txd_w;


//
// Parity Calculation
//

logic odd_parity_w;
logic parity_w;

always_comb begin
    odd_parity_w =
        read_data_i[0] ^
        read_data_i[1] ^
        read_data_i[2] ^
        read_data_i[3] ^
        read_data_i[4] ^
        read_data_i[5] ^
        read_data_i[6];

    if (config_i.data_bits == DATA_EIGHT)
        odd_parity_w = odd_parity_w ^ read_data_i[7];
end

always_comb begin
    unique case (config_i.parity)
    PARITY_NONE:  parity_w = 1'b0;
    PARITY_EVEN:  parity_w = !odd_parity_w;
    PARITY_ODD:   parity_w =  odd_parity_w;
    PARITY_MARK:  parity_w = 1'b1;
    PARITY_SPACE: parity_w = 1'b0;
    endcase
end


//
// Packet Creation
//

logic [11:0] packet_w;

always_comb begin
    packet_w[   0] = 1'b0;
    packet_w[ 7:1] = read_data_i[6:0];
    packet_w[11:8] = 4'hF;

    if (config_i.data_bits == DATA_EIGHT)
        packet_w[8] = read_data_i[7];

    if (config_i.parity != PARITY_NONE) begin
        unique case (config_i.data_bits)
        DATA_SEVEN: packet_w[8] = parity_w;
        DATA_EIGHT: packet_w[9] = parity_w;
        endcase
    end
end


//
// Repopulate Shift Register
//

always_comb read_enable_o = (packet_r == 3'h000);

always_ff @(posedge clk_i) begin
    if (read_valid_i) begin
        packet_r <= packet_w;
    end
end

endmodule
