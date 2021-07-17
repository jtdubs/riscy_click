`timescale 1ns/1ps

module cpu_tb ();
    
reg clk;
reg reset;
wire halt;

cpu cpu (
    .clk(clk),
    .reset(reset),
    .halt(halt)
);

integer i;

initial begin
    // reset
    clk = 0;
    reset = 1;

    // hold reset for 2 cycles
    for (i = 0; i < 2; i=i+1)
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