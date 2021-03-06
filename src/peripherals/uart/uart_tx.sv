`timescale 1ns / 1ps
`default_nettype none

///
/// UART Transmitter
///

module uart_tx
    // Import Constants
    import common::*;
    import uart_common::*;
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

logic [11:0] packet_next;
logic [11:0] packet_r = '0;
logic        txd_r = '1;
assign       txd_o = txd_r;

always_ff @(posedge clk_i) begin
    if (read_valid_i) begin
        packet_r <= packet_next;
    end else if (cycles_r == 24'b0) begin
        packet_r <= { 1'b0, packet_r[11:1] };
        txd_r    <= (packet_r == '0) ? 1'b1 : packet_r[0];
    end
end

always_comb read_enable_o = (packet_r == 12'h000);


//
// Parity Calculation
//

logic odd_parity;
logic parity;

always_comb begin
    odd_parity =
        read_data_i[0] ^
        read_data_i[1] ^
        read_data_i[2] ^
        read_data_i[3] ^
        read_data_i[4] ^
        read_data_i[5] ^
        read_data_i[6];

    if (config_i.data_bits == DATA_EIGHT)
        odd_parity = odd_parity ^ read_data_i[7];
end

always_comb begin
    unique case (config_i.parity)
    PARITY_NONE:  parity = 1'b0;
    PARITY_EVEN:  parity = !odd_parity;
    PARITY_ODD:   parity =  odd_parity;
    PARITY_MARK:  parity = 1'b1;
    PARITY_SPACE: parity = 1'b0;
    endcase
end


//
// Packet Creation
//

always_comb begin
    packet_next[   0] = 1'b0;
    packet_next[ 7:1] = read_data_i[6:0];
    packet_next[11:8] = 4'hF;

    if (config_i.data_bits == DATA_EIGHT)
        packet_next[8] = read_data_i[7];

    if (config_i.parity != PARITY_NONE) begin
        unique case (config_i.data_bits)
        DATA_SEVEN: packet_next[8] = parity;
        DATA_EIGHT: packet_next[9] = parity;
        endcase
    end
end

endmodule
