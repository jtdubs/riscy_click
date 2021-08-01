`timescale 1ns / 1ps
`default_nettype none

module vga_tb ();

logic clk_pxl_i;
logic reset_i;
logic [3:0] vga_red_o, vga_green_o, vga_blue_o;
logic vga_hsync_o, vga_vsync_o;

vga_controller vga (.*);

// clock generator
initial begin
    clk_pxl_i = 1;
    forever begin
        #20 clk_pxl_i <= ~clk_pxl_i;
    end
end

// reset pulse
initial begin
    reset_i = 1;
    @(posedge clk_pxl_i) reset_i = 0;
end

endmodule
