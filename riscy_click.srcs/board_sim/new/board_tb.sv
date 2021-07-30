`timescale 1ns / 1ps
`default_nettype none

module board_tb ();

logic clk_sys;
logic ia_rst;
wire logic oa_halt;
wire logic [ 7:0] oc_segment_a;
wire logic [ 7:0] oc_segment_c;
logic [15:0] ia_switch;

board board (.*);

// clock generator
initial begin
    clk_sys = 1;
    forever begin
        #5 clk_sys <= ~clk_sys;
    end
end

// reset pulse
initial begin
    ia_rst = 1;
    #25 ia_rst = 0;
end

// switches
initial begin
    ia_switch = 16'h9999;
end

endmodule
