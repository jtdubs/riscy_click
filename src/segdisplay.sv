`timescale 1ns / 1ps
`default_nettype none

///
/// Seven Segment Display
///

module segdisplay
    // Import Constants
    import common::*;
    #(
        parameter shortint unsigned CLK_DIVISOR = 32768 // Clock ratio
    )
    (
        // Clock
        input  wire logic       clk_i,

        // Display Interface
        output wire logic [7:0] dsp_anode_o,
        output wire logic [7:0] dsp_cathode_o,

        // Bus Interface
        input  wire logic       chip_select_i,
        input  wire logic [3:0] addr_i,
        input  wire logic       read_enable_i,
        output wire word_t      read_data_o,
        input  wire word_t      write_data_i,
        input  wire logic [3:0] write_mask_i
    );

//
// Bus Interface
//

logic  enabled_r = '0;
word_t value_r   = '0;

typedef enum logic [3:0] {
    PORT_CONTROL = 4'b0000,
    PORT_DATA    = 4'b0001
} port_t;


word_t read_data_r = '0;
assign read_data_o = read_data_r;
always_ff @(posedge clk_i) begin
    if (chip_select_i && read_enable_i) begin
        case (addr_i)
        PORT_CONTROL: read_data_r <= { 31'b0, enabled_r };
        PORT_DATA:    read_data_r <= value_r;
        default:      read_data_r <= '0;
        endcase
    end
end

always_ff @(posedge clk_i) begin
    if (chip_select_i) begin
        case (addr_i)
        PORT_CONTROL:
            begin
                if (write_mask_i[0]) enabled_r <= write_data_i[0];
            end
        PORT_DATA:
            begin
                if (write_mask_i[0]) value_r[ 7: 0] <= write_data_i[ 7: 0];
                if (write_mask_i[1]) value_r[15: 8] <= write_data_i[15: 8];
                if (write_mask_i[2]) value_r[23:16] <= write_data_i[23:16];
                if (write_mask_i[3]) value_r[31:24] <= write_data_i[31:24];
            end
        default: ;
        endcase
    end
end


//
// Display Driving
//

// Counter
localparam int unsigned COUNTER_WIDTH = $clog2(CLK_DIVISOR) + 4;

logic [(COUNTER_WIDTH-1):0] counter_r = '0;
logic                       enable;
logic [2:0]                 digit;

always_comb begin
    { digit, enable } = counter_r[(COUNTER_WIDTH-1):(COUNTER_WIDTH-4)];
end

always_ff @(posedge clk_i) begin
    if (enabled_r)
        counter_r <= counter_r + 1;
    else
        counter_r <= '0;
end


// Nibble
logic [3:0] nibble;

always_comb begin
    unique case (digit)
    0: nibble = value_r[ 3: 0];
    1: nibble = value_r[ 7: 4];
    2: nibble = value_r[11: 8];
    3: nibble = value_r[15:12];
    4: nibble = value_r[19:16];
    5: nibble = value_r[23:20];
    6: nibble = value_r[27:24];
    7: nibble = value_r[31:28];
    endcase
end


// Anode
logic [7:0] dsp_anode_r = 8'hFF;
assign      dsp_anode_o = dsp_anode_r;

always_ff @(posedge clk_i) begin
    dsp_anode_r <= 8'hFF;

    if (enable)
        dsp_anode_r[digit] <= 1'b0;
end


// Cathode
logic [7:0] dsp_cathode_r = 8'hFF;
assign      dsp_cathode_o = dsp_cathode_r;

always_ff @(posedge clk_i) begin
    dsp_cathode_r <= 8'hFF;

    if (enable) begin
        unique case (nibble)
        0:  dsp_cathode_r <= 8'b11000000;
        1:  dsp_cathode_r <= 8'b11111001;
        2:  dsp_cathode_r <= 8'b10100100;
        3:  dsp_cathode_r <= 8'b10110000;
        4:  dsp_cathode_r <= 8'b10011001;
        5:  dsp_cathode_r <= 8'b10010010;
        6:  dsp_cathode_r <= 8'b10000010;
        7:  dsp_cathode_r <= 8'b11111000;
        8:  dsp_cathode_r <= 8'b10000000;
        9:  dsp_cathode_r <= 8'b10011000;
        10: dsp_cathode_r <= 8'b10001000;
        11: dsp_cathode_r <= 8'b10000011;
        12: dsp_cathode_r <= 8'b11000110;
        13: dsp_cathode_r <= 8'b10100001;
        14: dsp_cathode_r <= 8'b10000110;
        15: dsp_cathode_r <= 8'b10001110;
        endcase
    end
end

endmodule
