`timescale 1ns/1ps

///
/// Seven Segment Display
///

module segdisplay
    // Import Constants
    import consts::*;
    #(
        parameter CLK_DIVISOR = 10000 // Clock ratio
    )
    (
        // system clock domain
        input logic clk,
        input logic reset,

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

// Counter rolls over at half the divisor so that a full cycle of the derived clock occurs at the divided frequency
localparam COUNTER_ROLLOVER = (CLK_DIVISOR / 2) - 1;

// Registers
(* mark_debug = "true" *) word value;
(* mark_debug = "true" *) logic[3:0] nibble;
(* mark_debug = "true" *) logic [15:0] counter;
(* mark_debug = "true" *) logic [3:0] index;

// Reading Logic
assign read_data = value;

always_comb
begin
    case (index[3:1])
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

logic [7:0] next_a;
always_comb
begin
    if (index[0])
    begin
        next_a <= 8'b11111111;
    end
    else
    begin
        case (index[3:1])
        0: next_a <= 8'b11111110;
        1: next_a <= 8'b11111101;
        2: next_a <= 8'b11111011;
        3: next_a <= 8'b11110111;
        4: next_a <= 8'b11101111;
        5: next_a <= 8'b11011111;
        6: next_a <= 8'b10111111;
        7: next_a <= 8'b01111111;
        endcase
    end
end

logic [7:0] next_c;
always_comb
begin
    if (index[0])
    begin
        next_c <= 8'b11111111;
    end
    else
    begin
        case (nibble)
        0:  next_c <= 8'b11000000;
        1:  next_c <= 8'b11111001;
        2:  next_c <= 8'b10100100;
        3:  next_c <= 8'b10110000;
        4:  next_c <= 8'b10011001;
        5:  next_c <= 8'b10010010;
        6:  next_c <= 8'b10000010;
        7:  next_c <= 8'b11111000;
        8:  next_c <= 8'b10000000;
        9:  next_c <= 8'b10011000;
        10: next_c <= 8'b10001000;
        11: next_c <= 8'b10000011;
        12: next_c <= 8'b11000110;
        13: next_c <= 8'b10100001;
        14: next_c <= 8'b10000110;
        15: next_c <= 8'b10001110;
        endcase
    end
end

// Clocked Writing
always_ff @(posedge clk)
begin
    a <= next_a;
    c <= next_c;

    if (reset)
    begin
        value <= 32'h12345678;
        counter <= 0;
        index <= 0;
    end
    else
    begin
        if (counter == COUNTER_ROLLOVER)
        begin
            counter <= 0;
            index <= index + 1;
        end
        else
        begin
            counter <= counter + 1;
            index <= index;
        end

        if (write_enable)
        begin
            value <= write_data;
            // Only write bytes where mask is set
//            if (write_mask[3]) value[31:24] <= write_data[31:24];
//            if (write_mask[2]) value[23:16] <= write_data[23:16];
//            if (write_mask[1]) value[15: 8] <= write_data[15: 8];
//            if (write_mask[0]) value[ 7: 0] <= write_data[ 7: 0];
        end
        else
        begin
            value <= value;
        end
    end
end

endmodule
