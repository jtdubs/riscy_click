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
        input  wire logic clk,
        input  wire logic ic_rst,

        // display interface
        output      logic [7:0] oc_dsp_a, // common anodes
        output      logic [7:0] oc_dsp_c, // cathodes

         // read port
        output wire word_t      oc_rd_data,
        
        // write port
        input  wire word_t      ic_wr_data,
        input  wire logic [3:0] ic_wr_mask
    );

// Counter rolls over at half the divisor so that a full cycle of the derived clock occurs at the divided frequency
localparam int unsigned COUNTER_ROLLOVER = (CLK_DIVISOR / 2) - 1;

// Registers
word_t       c_value;
word_t       c_display_value;
logic [15:0] c_counter;
logic [ 3:0] c_index;
logic [ 3:0] a_nibble;

// Read Port
assign oc_rd_data = c_value;

// Combination logic for current nibble
always_comb begin
    unique case (c_index[3:1])
    0: a_nibble <= c_display_value[ 3: 0];
    1: a_nibble <= c_display_value[ 7: 4];
    2: a_nibble <= c_display_value[11: 8];
    3: a_nibble <= c_display_value[15:12];
    4: a_nibble <= c_display_value[19:16];
    5: a_nibble <= c_display_value[23:20];
    6: a_nibble <= c_display_value[27:24];
    7: a_nibble <= c_display_value[31:28];
    endcase
end

// Clocked annode update
always_ff @(posedge clk) begin
    if (c_index[0]) begin
        // on odd indexes, output nothing
        oc_dsp_a <= 8'b11111111;
    end else begin
        // on even indexes, output to the appropriate segment
        unique case (c_index[3:1])
        0: oc_dsp_a <= 8'b11111110;
        1: oc_dsp_a <= 8'b11111101;
        2: oc_dsp_a <= 8'b11111011;
        3: oc_dsp_a <= 8'b11110111;
        4: oc_dsp_a <= 8'b11101111;
        5: oc_dsp_a <= 8'b11011111;
        6: oc_dsp_a <= 8'b10111111;
        7: oc_dsp_a <= 8'b01111111;
        endcase
    end
end

// Clocked cathode update
always_ff @(posedge clk) begin
    if (c_index[0]) begin
        // on odd indexes, output nothing
        oc_dsp_c <= 8'b11111111;
    end else begin
        // on even indexes, output current nibble
        // TODO: debug this.  i think because dsp_c depends on nibble depends on lc_dsp_value... it will be delayed a cycle?
        unique case (a_nibble)
        0:  oc_dsp_c <= 8'b11000000;
        1:  oc_dsp_c <= 8'b11111001;
        2:  oc_dsp_c <= 8'b10100100;
        3:  oc_dsp_c <= 8'b10110000;
        4:  oc_dsp_c <= 8'b10011001;
        5:  oc_dsp_c <= 8'b10010010;
        6:  oc_dsp_c <= 8'b10000010;
        7:  oc_dsp_c <= 8'b11111000;
        8:  oc_dsp_c <= 8'b10000000;
        9:  oc_dsp_c <= 8'b10011000;
        10: oc_dsp_c <= 8'b10001000;
        11: oc_dsp_c <= 8'b10000011;
        12: oc_dsp_c <= 8'b11000110;
        13: oc_dsp_c <= 8'b10100001;
        14: oc_dsp_c <= 8'b10000110;
        15: oc_dsp_c <= 8'b10001110;
        endcase
    end
end

// Clocked value updates
always_ff @(posedge clk) begin
    // Only write bytes where mask is set
    if (ic_wr_mask[3]) c_value[31:24] <= ic_wr_data[31:24];
    if (ic_wr_mask[2]) c_value[23:16] <= ic_wr_data[23:16];
    if (ic_wr_mask[1]) c_value[15: 8] <= ic_wr_data[15: 8];
    if (ic_wr_mask[0]) c_value[ 7: 0] <= ic_wr_data[ 7: 0];
        
    if (ic_rst) c_value <= 32'h00000000;
end

// Clocked update of display value on digit transitions
always_ff @(posedge clk) begin
    if (c_counter == COUNTER_ROLLOVER)
        c_display_value <= c_value;
    else
        c_display_value <= c_display_value;
        
    if (ic_rst)
        c_display_value <= 32'h00000000;
end

// Clocked counter
always_ff @(posedge clk)
begin
    if (c_counter == COUNTER_ROLLOVER) begin
        c_counter <= 0;
        c_index   <= c_index + 1;
    end else begin
        c_counter <= c_counter + 1;
        c_index   <= c_index;
    end
     
    if (ic_rst) begin
        c_counter <= 0;
        c_index   <= 0;
    end
end

endmodule
