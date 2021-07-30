`timescale 1ns / 1ps
`default_nettype none

module segdisplay_tb
    import common::*;
    ();

logic clk, ic_rst;
wire logic [7:0] oc_dsp_a, oc_dsp_c;
wire word_t oc_rd_data;
word_t ic_wr_data;
logic [3:0] ic_wr_mask;

segdisplay #(.CLK_DIVISOR(4)) segdisplay (.*);
    
// clock generator
initial begin
    clk = 1;
    forever begin
        #5 clk <= ~clk;
    end
end

// reset pulse (2 cycle)
initial begin
    ic_rst = 1;
    #20 ic_rst = 0;
end

// write signals
initial begin
    ic_wr_data = 32'h12345678;
    ic_wr_mask = 4'b1111;
end

endmodule
