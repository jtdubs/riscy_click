`timescale 1ns/1ps

module cpu_tb ();
    
reg clk;
reg reset;
wire halt;
wire logic [7:0] segment_a;
wire logic [7:0] segment_c;
        
board board (
    .clk(clk),
    .reset(reset),
    .halt(halt),
    .segment_a(segment_a),
    .segment_c(segment_c)
);

integer i;

initial begin
    // reset
    clk = 0;
    reset = 1;

    // hold reset for 1ms
    for (i = 0; i < 100000; i=i+1)
    begin
        clk = 1;
        #10;
        clk = 0;
        #10;
    end

    // unreset
    clk = 1;
    #10;
    clk = 0;
    reset = 0;
    #10;

    // run until halt
    while (!halt)
    begin
        clk = 1;
        #10;
        clk = 0;
        #10;
    end

    // run for 4 extra cycles
    for (i = 0; i < 4; i=i+1)
    begin
        clk = 1;
        #10;
        clk = 0;
        #10;
    end

    $finish;
end
    
endmodule