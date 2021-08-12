`timescale 1ns / 1ps
`default_nettype none

module board_tb ();

     logic        clk_sys_i;
     logic        reset_async_i;
     logic [15:0] switch_async_i;
     logic        ps2_clk_async_i;
     logic        ps2_data_async_i;
wire logic        halt_o;
wire logic [ 7:0] dsp_anode_o;
wire logic [ 7:0] dsp_cathode_o;
wire logic [ 3:0] vga_red_o;
wire logic [ 3:0] vga_green_o;
wire logic [ 3:0] vga_blue_o;
wire logic        vga_hsync_o;
wire logic        vga_vsync_o;

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
    #10000 reset_async_i = 0;
end

// switches
initial begin
    switch_async_i = 16'h9999;
end

// ps2
initial begin
    ps2_clk_async_i  = 1'b1;
    ps2_data_async_i = 1'b0;
end

endmodule
