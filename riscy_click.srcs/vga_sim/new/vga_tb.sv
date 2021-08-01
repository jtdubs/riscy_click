`timescale 1ns / 1ps
`default_nettype none

module vga_tb ();

logic clk_pxl_i;
logic reset_i;
logic [3:0] vga_red_o, vga_green_o, vga_blue_o;
logic vga_hsync_o, vga_vsync_o;
logic [11:0] vram_addr_o;
logic [ 7:0] vram_data_i;

video_ram #(.CONTENTS("vram.mem")) vram (
    // cpu port
    .clk_cpu_i        (),
    .cpu_reset_i      (),
    .cpu_addr_i       (),
    .cpu_write_data_i (),
    .cpu_write_mask_i (),
    .cpu_read_data_o  (),
    
    // vga port
    .clk_pxl_i        (clk_pxl_i),
    .pxl_reset_i      (reset_i),
    .pxl_addr_i       (vram_addr_o),
    .pxl_data_o       (vram_data_i)
);

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
