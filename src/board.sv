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
        input  wire logic        sys_clk_i,     // 100MHz system clock
        input  wire logic [15:0] switch_i,      // hardware switch bank (async)
        input  wire logic        ps2_clk_i,     // PS2 HID clock (async)
        input  wire logic        ps2_data_i,    // PS2 HID data (async)

        // Outputs
        output wire logic [ 7:0] dsp_anode_o,   // seven segment display anodes
        output wire logic [ 7:0] dsp_cathode_o, // seven segment display cathodes
        output wire logic        halt_o,        // halt
        output wire logic [ 3:0] vga_red_o,     // VGA red color
        output wire logic [ 3:0] vga_green_o,   // VGA red color
        output wire logic [ 3:0] vga_blue_o,    // VGA red color
        output wire logic        vga_hsync_o,   // VGA hsync signal
        output wire logic        vga_vsync_o    // VGA vsync signal
    );

//
// Clocks
//

wire logic cpu_clk_w;
wire logic cpu_clk_ready_w;

cpu_clk_gen cpu_clk_gen (
    .sys_clk_i     (sys_clk_i),
    .cpu_clk_o     (cpu_clk_w),
    .ready_async_o (cpu_clk_ready_w)
);

wire logic pxl_clk_w;

pixel_clk_gen pixel_clk_gen (
    .sys_clk_i     (sys_clk_i),
    .pxl_clk_o     (pxl_clk_w),
    .ready_async_o ()
);


//
// Chipset
//

chipset chipset (
    .cpu_clk_i     (cpu_clk_w),
    .pxl_clk_i     (pxl_clk_w),
    .ps2_clk_i     (ps2_clk_i),
    .ps2_data_i    (ps2_data_i),
    .switch_i      (switch_i),
    .halt_o        (halt_o),
    .dsp_anode_o   (dsp_anode_o),
    .dsp_cathode_o (dsp_cathode_o),
    .vga_red_o     (vga_red_o),
    .vga_green_o   (vga_green_o),
    .vga_blue_o    (vga_blue_o),
    .vga_hsync_o   (vga_hsync_o),
    .vga_vsync_o   (vga_vsync_o)
);

endmodule
