`timescale 1ns / 1ps
`default_nettype none

module board_tb ();

// cpu signals
logic        sys_clk;        // clock
logic        reset_async;    // reset
logic        halt;           // board

// IO signals
logic [ 7:0] segment_a;
logic [ 7:0] segment_c;
logic [15:0] switch_async;

board board (.*);

// clock generator
initial begin
    sys_clk = 1;
    forever begin
        #5 sys_clk <= ~sys_clk;
    end
end

// reset pulse
initial begin
    reset_async = 1;
    #25 reset_async = 0;
end

// switches
integer i;
initial begin
    switch_async = 16'h9999;
//    for (i=0; i<16; i++)
//        #1000000 switch_async[i] = 1;
end

endmodule
