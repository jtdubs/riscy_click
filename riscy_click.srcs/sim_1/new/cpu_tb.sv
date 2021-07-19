`timescale 1ns/1ps

module cpu_tb ();

reg clk;
reg reset;
wire halt;
wire logic [7:0] segment_a;
wire logic [7:0] segment_c;
logic [15:0] switch;

board board (
    .clk(clk),
    .reset(reset),
    .halt(halt),
    .segment_a(segment_a),
    .segment_c(segment_c),
    .switch(switch)
);

// clock generator
initial begin
    clk = 0;
    forever begin
        #500 clk <= ~clk;
    end
end

// reset pulse (4 cycles)
initial begin
    reset = 1;
    #4000 reset = 0;
end

// switches
integer i;
initial begin
    switch = 16'h0000;
    for (i=0; i<16; i++)
        #1000000 switch[i] = 1;
end

endmodule
