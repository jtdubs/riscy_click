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

// clock generator
initial begin
    clk = 0;
    forever begin
        #10 clk <= ~clk;
    end
end

// reset pulse (4 cycles)
initial begin
    reset = 1;
    #40 reset = 0;
end

endmodule