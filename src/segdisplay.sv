`timescale 1ns / 1ps
`default_nettype none

///
/// Seven Segment Display
///

// Was: 273 nets, 211 cells

module segdisplay
    // Import Constants
    import common::*;
    #(
        parameter shortint unsigned CLK_DIVISOR = 32768 // Clock ratio
    )
    (
        // system clock domain
        input  wire logic       clk_i,
        input  wire logic       reset_i,

        // display interface
        output      logic [7:0] dsp_anode_o,
        output      logic [7:0] dsp_cathode_o,

        // read port
        output      word_t      read_data_o,

        // write port
        input  wire word_t      write_data_i,
        input  wire logic [3:0] write_mask_i
    );


// Counter
localparam int unsigned COUNTER_WIDTH = $clog2(CLK_DIVISOR) + 4;

logic [(COUNTER_WIDTH-1):0] counter_r;
logic       enable_w;
logic [2:0] digit_w;

always_comb begin
    { digit_w, enable_w } = counter_r[(COUNTER_WIDTH-1):(COUNTER_WIDTH-4)];
end

always_ff @(posedge clk_i) begin
    counter_r <= reset_i ? '0 : counter_r + 1;
end


// Value
word_t value_r;

always_comb read_data_o = value_r;

always @(posedge clk_i) begin
    if (write_mask_i[3]) value_r[31:24] <= write_data_i[31:24];
    if (write_mask_i[2]) value_r[23:16] <= write_data_i[23:16];
    if (write_mask_i[1]) value_r[15: 8] <= write_data_i[15: 8];
    if (write_mask_i[0]) value_r[ 7: 0] <= write_data_i[ 7: 0];

    if (reset_i)
        value_r <= 32'b0;
end


// Nibble
logic [3:0] nibble_w;
always_comb begin
    unique case (digit_w)
    0: nibble_w = value_r[ 3: 0];
    1: nibble_w = value_r[ 7: 4];
    2: nibble_w = value_r[11: 8];
    3: nibble_w = value_r[15:12];
    4: nibble_w = value_r[19:16];
    5: nibble_w = value_r[23:20];
    6: nibble_w = value_r[27:24];
    7: nibble_w = value_r[31:28];
    endcase
end


// Anode
always_ff @(posedge clk_i) begin
    dsp_anode_o <= 8'hFF;

    if (enable_w)
        dsp_anode_o[digit_w] <= 1'b0;
end


// Cathode
always_ff @(posedge clk_i) begin
    dsp_cathode_o <= 8'hFF;

    if (enable_w) begin
        unique case (nibble_w)
        0:  dsp_cathode_o <= 8'b11000000;
        1:  dsp_cathode_o <= 8'b11111001;
        2:  dsp_cathode_o <= 8'b10100100;
        3:  dsp_cathode_o <= 8'b10110000;
        4:  dsp_cathode_o <= 8'b10011001;
        5:  dsp_cathode_o <= 8'b10010010;
        6:  dsp_cathode_o <= 8'b10000010;
        7:  dsp_cathode_o <= 8'b11111000;
        8:  dsp_cathode_o <= 8'b10000000;
        9:  dsp_cathode_o <= 8'b10011000;
        10: dsp_cathode_o <= 8'b10001000;
        11: dsp_cathode_o <= 8'b10000011;
        12: dsp_cathode_o <= 8'b11000110;
        13: dsp_cathode_o <= 8'b10100001;
        14: dsp_cathode_o <= 8'b10000110;
        15: dsp_cathode_o <= 8'b10001110;
        endcase
    end
end

endmodule
