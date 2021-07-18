`timescale 1ns/1ps

///
/// Seven Segment Display
///

module segdisplay
    // Import Constants
    import consts::*;
    (
        // system clock domain
        input logic clk,
        input logic reset,
        
        // display clock domain
        input logic dsp_clk,
        input logic dsp_reset,
        
        // display interface
        output logic [7:0] a, // common anodes
        output logic [7:0] c, // cathodes
        
         // data bus interface
        input word        addr,
        output wire word  read_data,
        input word        write_data,
        input logic       write_enable,
        input logic [3:0] write_mask
    );
    
// Registers
word value;
logic[4:0] nibble;
logic [2:0] index;

// Reading Logic
assign read_data = value;

always_comb
begin
    case (index)
    0: nibble <= value[ 3: 0];
    1: nibble <= value[ 7: 4];
    2: nibble <= value[11: 8];
    3: nibble <= value[15:12];
    4: nibble <= value[19:16];
    5: nibble <= value[23:20];
    6: nibble <= value[27:24];
    7: nibble <= value[31:28];
    endcase
end

always_comb
begin
    case (index)
    0: a <= 8'b00000001;
    1: a <= 8'b00000010;
    2: a <= 8'b00000100;
    3: a <= 8'b00001000;
    4: a <= 8'b00010000;
    5: a <= 8'b00100000;
    6: a <= 8'b01000000;
    7: a <= 8'b10000000;
    endcase
end

always_comb
begin
    case (nibble)
    0:  c <= 8'b11111100;
    1:  c <= 8'b01100000;
    2:  c <= 8'b11011010;
    3:  c <= 8'b11110010;
    4:  c <= 8'b01100110;
    5:  c <= 8'b10110110;
    6:  c <= 8'b10111110;
    7:  c <= 8'b11100000;
    8:  c <= 8'b11111110;
    9:  c <= 8'b11100110;
    10: c <= 8'b11101110;
    11: c <= 8'b00111110;
    12: c <= 8'b10011100;
    13: c <= 8'b01111010;
    14: c <= 8'b10011110;
    15: c <= 8'b10001110;
    endcase
end

// Clocked Writing
always_ff @(posedge clk)
begin
    if (reset)
    begin
        value <= 0;
    end
    else
    if (write_enable)
    begin
        // Only write bytes where mask is set
        if (write_mask[3]) value[31:24] <= write_data[31:24];
        if (write_mask[2]) value[23:16] <= write_data[23:16];
        if (write_mask[1]) value[15: 8] <= write_data[15: 8];
        if (write_mask[0]) value[ 7: 0] <= write_data[ 7: 0];
    end
end

// Clocked Display Updating
always_ff @(posedge dsp_clk)
begin
    if (dsp_reset)
    begin
        index <= 0;
    end 
    else
    begin
        index <= index + 1;
    end
end

endmodule