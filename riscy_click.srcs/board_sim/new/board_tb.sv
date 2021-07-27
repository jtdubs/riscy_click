`timescale 1ns / 1ps
`default_nettype none

module board_tb ();

// cpu signals
logic        clk;            // clock
logic        reset;          // reset
logic        halt;           // board

// IO signals
logic [ 7:0] segment_a;
logic [ 7:0] segment_c;
logic [15:0] switch;

board board (.*);

// clock generator
initial begin
    clk = 1;
    forever begin
        #50 clk <= ~clk;
    end
end

// reset pulse
initial begin
    reset = 1;
    #250 reset = 0;
end

// switches
integer i;
initial begin
    switch = 16'h0000;
    for (i=0; i<16; i++)
        #1000000 switch[i] = 1;
end

endmodule
