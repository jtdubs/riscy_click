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
        input       word        addr,
        output wire word        read_data,
        input       word        write_data,
        input       logic       write_enable,
        input       logic [3:0] write_mask
    );

// Counter rolls over at half the divisor so that a full cycle of the derived clock occurs at the divided frequency
localparam COUNTER_ROLLOVER = (CLK_DIVISOR / 2) - 1;

// Registers
word         value;
word         display_value;
logic [15:0] counter;
logic [ 3:0] nibble;
logic [ 3:0] index;

// Reading Logic
assign read_data = value;

// Combination logic for current nibble
always_comb begin
    case (index[3:1])
    0: nibble <= display_value[ 3: 0];
    1: nibble <= display_value[ 7: 4];
    2: nibble <= display_value[11: 8];
    3: nibble <= display_value[15:12];
    4: nibble <= display_value[19:16];
    5: nibble <= display_value[23:20];
    6: nibble <= display_value[27:24];
    default: /* 7 */ nibble <= display_value[31:28];
    endcase
end

// Clocked annode update
always_ff @(posedge clk) begin
    if (index[0]) begin
        a <= 8'b11111111;
    end else begin
        case (index[3:1])
        0: a <= 8'b11111110;
        1: a <= 8'b11111101;
        2: a <= 8'b11111011;
        3: a <= 8'b11110111;
        4: a <= 8'b11101111;
        5: a <= 8'b11011111;
        6: a <= 8'b10111111;
        default: /* 7 */ a <= 8'b01111111;
        endcase
    end
end

// Clocked cathode update
always_ff @(posedge clk) begin
    if (index[0]) begin
        c <= 8'b11111111;
    end else begin
        case (nibble)
        0:  c <= 8'b11000000;
        1:  c <= 8'b11111001;
        2:  c <= 8'b10100100;
        3:  c <= 8'b10110000;
        4:  c <= 8'b10011001;
        5:  c <= 8'b10010010;
        6:  c <= 8'b10000010;
        7:  c <= 8'b11111000;
        8:  c <= 8'b10000000;
        9:  c <= 8'b10011000;
        10: c <= 8'b10001000;
        11: c <= 8'b10000011;
        12: c <= 8'b11000110;
        13: c <= 8'b10100001;
        14: c <= 8'b10000110;
        default: /* 15 */ c <= 8'b10001110;
        endcase
    end
end

// Clocked value updates
always_ff @(posedge clk) begin
    if (reset) begin
        value <= 32'h00000000;
    end else begin
        if (write_enable)
        begin
            // Only write bytes where mask is set
            if (write_mask[3]) value[31:24] <= write_data[31:24];
            if (write_mask[2]) value[23:16] <= write_data[23:16];
            if (write_mask[1]) value[15: 8] <= write_data[15: 8];
            if (write_mask[0]) value[ 7: 0] <= write_data[ 7: 0];
        end
    end
end

// Clicked update of display value on digit transitions
always_ff @(posedge clk) begin
    if (reset) begin
        display_value <= value;
    end else begin
        if (counter == COUNTER_ROLLOVER) begin
            display_value <= value;
        end else begin
            display_value <= display_value;
        end
    end
end


// Clocked counter
always_ff @(posedge clk)
begin
    if (reset) begin
        counter <= 0;
        index <= 0;
    end else begin
        if (counter == COUNTER_ROLLOVER) begin
            counter <= 0;
            index <= index + 1;
        end else begin
            counter <= counter + 1;
            index <= index;
        end
    end
end

endmodule
