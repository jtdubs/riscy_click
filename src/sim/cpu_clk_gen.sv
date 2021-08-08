`timescale 1ns / 1ps
`default_nettype none

module cpu_clk_gen
    // Import Constants
    import common::*;
    (
        input  wire logic clk_sys_i,     // 100MHz system clock
        input  wire logic reset_async_i, // reset

        // cpu clock output
        output wire logic clk_cpu_o,     // 50MHz cpu clock
        output wire logic ready_async_o  // cpu clock ready
    );

logic [1:0] counter;

initial counter = 2'b0;

always_ff @(posedge clk_sys_i) begin
    counter = counter + 1;
end

always_comb begin
    clk_cpu_o = counter[0];
    ready_async_o = 1'b1;
end

endmodule
