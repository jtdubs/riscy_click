`timescale 1ns / 1ps
`default_nettype none

`ifdef VERILATOR
module board_tb ( input logic clk_sys_i, input logic reset_async_i );

wire logic halt_o;
wire logic [ 7:0] dsp_anode_o;
wire logic [ 7:0] dsp_cathode_o;
logic [15:0] switch_async_i;
logic [3:0] vga_red_o, vga_green_o, vga_blue_o;
logic vga_hsync_o, vga_vsync_o;

board board (.*);

initial begin
    switch_async_i = 16'h9999;
end

endmodule

`else
module board_tb ();

logic clk_sys_i;
logic reset_async_i;
wire logic halt_o;
wire logic [ 7:0] dsp_anode_o;
wire logic [ 7:0] dsp_cathode_o;
logic [15:0] switch_async_i;
logic [3:0] vga_red_o, vga_green_o, vga_blue_o;
logic vga_hsync_o, vga_vsync_o;

board board (.*);

// clock generator
initial begin
    clk_sys_i = 1;
    forever begin
        #5 clk_sys_i = ~clk_sys_i;
    end
end

// reset_i pulse
initial begin
    reset_async_i = 1;
    #25 reset_async_i = 0;
end

// switches
initial begin
    switch_async_i = 16'h9999;
end

endmodule
`endif
