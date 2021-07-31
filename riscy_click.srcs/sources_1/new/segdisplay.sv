`timescale 1ns / 1ps
`default_nettype none

///
/// Seven Segment Display
///

module segdisplay
    // Import Constants
    import common::*;
    #(
        parameter int unsigned CLK_DIVISOR = 10000 // Clock ratio
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

localparam int unsigned COUNTER_ROLLOVER = CLK_DIVISOR - 1;

// Registers
word_t       bus_value_r;
word_t       dsp_value_r;
word_t       dsp_value_w;
logic [15:0] counter_r;
logic [15:0] counter_w;
logic [ 3:0] index_r;
logic [ 3:0] index_w;
logic [ 3:0] nibble_w;
logic [ 7:0] dsp_anode_w;
logic [ 7:0] dsp_cathode_w;

// Read Port
always_comb read_data_o = bus_value_r;

// Next display value
always_comb begin
    // Promote value to display if between digits
    if (counter_r == COUNTER_ROLLOVER)
        dsp_value_w = bus_value_r;
    else
        dsp_value_w = dsp_value_r;
end

// Next counter & index
always_comb begin
    // If rollover 
    if (counter_r == COUNTER_ROLLOVER) begin
        // Start over and bump index
        counter_w = 16'b0;
        index_w   = index_r + 1;
    end else begin
        // Otherwise, keep counting
        counter_w = counter_r + 1;
        index_w   = index_r;
    end
end

// Next nibble to display
always_comb begin
    unique case (index_w[3:1])
    0: nibble_w = dsp_value_w[ 3: 0];
    1: nibble_w = dsp_value_w[ 7: 4];
    2: nibble_w = dsp_value_w[11: 8];
    3: nibble_w = dsp_value_w[15:12];
    4: nibble_w = dsp_value_w[19:16];
    5: nibble_w = dsp_value_w[23:20];
    6: nibble_w = dsp_value_w[27:24];
    7: nibble_w = dsp_value_w[31:28];
    endcase
end

// Next anode values
always_comb begin
    if (index_w[0]) begin
        // on odd indexes, output nothing
        dsp_anode_w = 8'b11111111;
    end else begin
        // on even indexes, light up the appropriate segment
        unique case (index_w[3:1])
        0: dsp_anode_w = 8'b11111110;
        1: dsp_anode_w = 8'b11111101;
        2: dsp_anode_w = 8'b11111011;
        3: dsp_anode_w = 8'b11110111;
        4: dsp_anode_w = 8'b11101111;
        5: dsp_anode_w = 8'b11011111;
        6: dsp_anode_w = 8'b10111111;
        7: dsp_anode_w = 8'b01111111;
        endcase
    end
end

// Next cathode values
always_comb begin
    if (index_w[0]) begin
        // on odd indexes, output nothing
        dsp_cathode_w = 8'b11111111;
    end else begin
        // on even indexes, output the appropriate nibble
        unique case (nibble_w)
        0:  dsp_cathode_w = 8'b11000000;
        1:  dsp_cathode_w = 8'b11111001;
        2:  dsp_cathode_w = 8'b10100100;
        3:  dsp_cathode_w = 8'b10110000;
        4:  dsp_cathode_w = 8'b10011001;
        5:  dsp_cathode_w = 8'b10010010;
        6:  dsp_cathode_w = 8'b10000010;
        7:  dsp_cathode_w = 8'b11111000;
        8:  dsp_cathode_w = 8'b10000000;
        9:  dsp_cathode_w = 8'b10011000;
        10: dsp_cathode_w = 8'b10001000;
        11: dsp_cathode_w = 8'b10000011;
        12: dsp_cathode_w = 8'b11000110;
        13: dsp_cathode_w = 8'b10100001;
        14: dsp_cathode_w = 8'b10000110;
        15: dsp_cathode_w = 8'b10001110;
        endcase
    end
end

// Clocked updates
always_ff @(posedge clk_i) begin
    // update registers
    dsp_value_r   <= dsp_value_w;
    counter_r     <= counter_w;
    index_r       <= index_w;
    dsp_cathode_o <= dsp_cathode_w;
    dsp_anode_o   <= dsp_anode_w;

    // Only write bytes where mask is set
    if (write_mask_i[3]) bus_value_r[31:24] <= write_data_i[31:24];
    if (write_mask_i[2]) bus_value_r[23:16] <= write_data_i[23:16];
    if (write_mask_i[1]) bus_value_r[15: 8] <= write_data_i[15: 8];
    if (write_mask_i[0]) bus_value_r[ 7: 0] <= write_data_i[ 7: 0];
    
    if (reset_i) begin
        bus_value_r   <= 32'b0;
        dsp_value_r   <= 32'b0;
        counter_r     <= COUNTER_ROLLOVER;
        index_r       <= 4'b1111;
        dsp_cathode_o <= 8'b11111111;
        dsp_anode_o   <= 8'b11111111;
    end 
end

endmodule