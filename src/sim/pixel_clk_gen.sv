`timescale 1ns / 1ps
`default_nettype none

module pixel_clk_gen
    // Import Constants
    import common::*;
    (
        input  wire logic clk_sys_i,     // 100MHz system clock
        input  wire logic reset_async_i, // reset

        // cpu clock output
        output wire logic clk_pxl_o,     // 25.2MHz VGA pixel clock
        output wire logic ready_async_o  // cpu clock ready
    );

logic [1:0] counter;

initial counter = 2'b0;

always_ff @(posedge clk_sys_i) begin
    counter = counter + 1;
end

always_comb begin
    clk_pxl_o = counter[1];
    ready_async_o = 1'b1;
end

endmodule
