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
        input  wire logic       clk,
        input  wire logic       ic_rst,

        // display interface
        output      logic [7:0] oc_dsp_a,   // common anodes
        output      logic [7:0] oc_dsp_c,   // cathodes

        // read port
        output      word_t      oc_rd_data,
        
        // write port
        input  wire word_t      ic_wr_data,
        input  wire logic [3:0] ic_wr_mask
    );

localparam int unsigned COUNTER_ROLLOVER = CLK_DIVISOR - 1;

// Registers
word_t c_value;
word_t c_display_value, a_display_value_next;
logic [15:0] c_counter, a_counter_next;
logic [ 3:0] c_index, a_index_next;
logic [ 3:0] a_nibble_next;
logic [7:0] a_dsp_a_next;
logic [7:0] a_dsp_c_next;

// Read Port
always_comb oc_rd_data = c_value;

// Next display value
always_comb begin
    // Promote value to display if between digits
    if (c_counter == COUNTER_ROLLOVER)
        a_display_value_next = c_value;
    else
        a_display_value_next = c_display_value;
        
    if (ic_rst)
        a_display_value_next = 32'h00000000;
end

// Next counter & index
always_comb begin
    // If rollover 
    if (c_counter == COUNTER_ROLLOVER) begin
        // Start over and bump index
        a_counter_next = 16'b0;
        a_index_next   = c_index + 1;
    end else begin
        // Otherwise, keep counting
        a_counter_next = c_counter + 1;
        a_index_next   = c_index;
    end
     
    if (ic_rst) begin
        a_counter_next = 16'b0;
        a_index_next   = 4'b0;
    end
end

// Next nibble to display
always_comb begin
    unique case (a_index_next[3:1])
    0: a_nibble_next = a_display_value_next[ 3: 0];
    1: a_nibble_next = a_display_value_next[ 7: 4];
    2: a_nibble_next = a_display_value_next[11: 8];
    3: a_nibble_next = a_display_value_next[15:12];
    4: a_nibble_next = a_display_value_next[19:16];
    5: a_nibble_next = a_display_value_next[23:20];
    6: a_nibble_next = a_display_value_next[27:24];
    7: a_nibble_next = a_display_value_next[31:28];
    endcase
    
    if (ic_rst) a_nibble_next = 4'b0;
end

// Next annode values
always_comb begin
    if (a_index_next[0]) begin
        // on odd indexes, output nothing
        a_dsp_a_next = 8'b11111111;
    end else begin
        // on even indexes, light up the appropriate segment
        unique case (a_index_next[3:1])
        0: a_dsp_a_next = 8'b11111110;
        1: a_dsp_a_next = 8'b11111101;
        2: a_dsp_a_next = 8'b11111011;
        3: a_dsp_a_next = 8'b11110111;
        4: a_dsp_a_next = 8'b11101111;
        5: a_dsp_a_next = 8'b11011111;
        6: a_dsp_a_next = 8'b10111111;
        7: a_dsp_a_next = 8'b01111111;
        endcase
    end
    
    if (ic_rst) a_dsp_a_next = 8'b11111111;
end

// Next cathode values
always_comb begin
    if (a_index_next[0]) begin
        // on odd indexes, output nothing
        a_dsp_c_next <= 8'b11111111;
    end else begin
        // on even indexes, output the appropriate nibble
        unique case (a_nibble_next)
        0:  a_dsp_c_next <= 8'b11000000;
        1:  a_dsp_c_next <= 8'b11111001;
        2:  a_dsp_c_next <= 8'b10100100;
        3:  a_dsp_c_next <= 8'b10110000;
        4:  a_dsp_c_next <= 8'b10011001;
        5:  a_dsp_c_next <= 8'b10010010;
        6:  a_dsp_c_next <= 8'b10000010;
        7:  a_dsp_c_next <= 8'b11111000;
        8:  a_dsp_c_next <= 8'b10000000;
        9:  a_dsp_c_next <= 8'b10011000;
        10: a_dsp_c_next <= 8'b10001000;
        11: a_dsp_c_next <= 8'b10000011;
        12: a_dsp_c_next <= 8'b11000110;
        13: a_dsp_c_next <= 8'b10100001;
        14: a_dsp_c_next <= 8'b10000110;
        15: a_dsp_c_next <= 8'b10001110;
        endcase
    end
    
    if (ic_rst) a_dsp_c_next = 8'b11111111;
end

// Clocked updates
always_ff @(posedge clk) begin
    c_display_value <= a_display_value_next;
    c_counter       <= a_counter_next;
    c_index         <= a_index_next;
    oc_dsp_c        <= a_dsp_c_next;
    oc_dsp_a        <= a_dsp_a_next;

    // Only write bytes where mask is set
    if (ic_wr_mask[3]) c_value[31:24] <= ic_wr_data[31:24];
    if (ic_wr_mask[2]) c_value[23:16] <= ic_wr_data[23:16];
    if (ic_wr_mask[1]) c_value[15: 8] <= ic_wr_data[15: 8];
    if (ic_wr_mask[0]) c_value[ 7: 0] <= ic_wr_data[ 7: 0];
       
    if (ic_rst) c_value <= 32'h00000000;
end

endmodule
