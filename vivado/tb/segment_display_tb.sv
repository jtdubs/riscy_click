`timescale 1ns / 1ps
`default_nettype none

module segment_display_tb
    import common::*;
    ();

logic clk_i, reset_i;
wire logic [7:0] dsp_anode_o, dsp_cathode_o;
wire word_t read_data_o;
word_t write_data_i;
logic [3:0] write_mask_i;

segment_display #(.CLK_DIVISOR(4)) segdisplay (.*);

// clock generator
initial begin
    clk_i = 1;
    forever begin
        #5 clk_i <= ~clk_i;
    end
end

// reset_i pulse (2 cycle)
initial begin
    reset_i = 1;
    #20
    @(posedge clk_i) reset_i = 0;
end

// write signals
initial begin
    write_data_i = 32'h12345678;
    write_mask_i = 4'b1111;
end

endmodule
