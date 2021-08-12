`timescale 1ns / 1ps
`default_nettype none

///
/// Board
///

module board
    // Import Constants
    import common::*;
    (
        // Inputs
        input  wire logic        clk_sys_i,        // 100MHz system clock
        input  wire logic        reset_async_i,    // reset (async)
        input  wire logic [15:0] switch_async_i,   // hardware switch bank (async)
        input  wire logic        ps2_clk_async_i,  // PS2 HID clock (async)
        input  wire logic        ps2_data_async_i, // PS2 HID data (async)

        // Outputs
        output wire logic [ 7:0] dsp_anode_o,      // seven segment display anodes
        output wire logic [ 7:0] dsp_cathode_o,    // seven segment display cathodes
        output wire logic        halt_o,           // halt
        output wire logic [ 3:0] vga_red_o,        // VGA red color
        output wire logic [ 3:0] vga_green_o,      // VGA red color
        output wire logic [ 3:0] vga_blue_o,       // VGA red color
        output wire logic        vga_hsync_o,      // VGA hsync signal
        output wire logic        vga_vsync_o       // VGA vsync signal
    );

//
// Clocks
//

wire logic clk_cpu_w;
wire logic clk_reset;

cpu_clk_gen cpu_clk_gen (
    .clk_sys_i     (clk_sys_i),
    .reset_async_i (1'b0),
    .clk_cpu_o     (clk_cpu_w),
    .ready_async_o ()
);

wire logic clk_pxl_w;

pixel_clk_gen pixel_clk_gen (
    .clk_sys_i     (clk_sys_i),
    .reset_async_i (1'b0),
    .clk_pxl_o     (clk_pxl_w),
    .ready_async_o ()
);


//
// Chipset
//

chipset chipset (
    .clk_cpu_i        (clk_cpu_w),
    .clk_pxl_i        (clk_pxl_w),
    .reset_async_i    (reset_async_i),
    .ps2_clk_async_i  (ps2_clk_async_i),
    .ps2_data_async_i (ps2_data_async_i),
    .switch_async_i   (switch_async_i),
    .halt_o           (halt_o),
    .dsp_anode_o      (dsp_anode_o),
    .dsp_cathode_o    (dsp_cathode_o),
    .vga_red_o        (vga_red_o),
    .vga_green_o      (vga_green_o),
    .vga_blue_o       (vga_blue_o),
    .vga_hsync_o      (vga_hsync_o),
    .vga_vsync_o      (vga_vsync_o)
);

endmodule
