`timescale 1ns / 1ps
`default_nettype none

///
/// Top
///

module ps2_top
    // Import Constants
    import common::*;
    (
`ifdef USE_EXTERNAL_CLOCKS
        // Clocks
        input  wire logic        cpu_clk_i,      // CPU clock
        input  wire logic        pxl_clk_i,      // Pixel clock
`else
        // Clocks
        input  wire logic        sys_clk_i,      // CPU clock
`endif

        // LEDs
        output wire logic [15:0] led_o,         // LEDs

        // USB PS/2
        input  wire logic        usb_ps2_clk_i,      // USB PS2 HID clock (async)
        input  wire logic        usb_ps2_data_i,     // USB PS2 HID data (async)

        // PS/2
        inout  tri  logic        ps2_clk_io,      // USB PS2 HID clock (async)
        inout  tri  logic        ps2_data_io,     // USB PS2 HID data (async)

        // UART
        input  wire logic        uart_rxd_i,
        output wire logic        uart_txd_o,

        // Switches
        input  wire logic [15:0] switch_i,       // async hardware switch bank input

        // Seven Segment Display
        output wire logic [ 7:0] dsp_anode_o,    // seven segment display anodes output
        output wire logic [ 7:0] dsp_cathode_o,  // seven segment display cathodes output

        // VGA
        output wire logic [ 3:0] vga_red_o,      // vga red output
        output wire logic [ 3:0] vga_green_o,    // vga green output
        output wire logic [ 3:0] vga_blue_o,     // vga blue output
        output wire logic        vga_hsync_o,    // vga horizontal sync output
        output wire logic        vga_vsync_o     // vga vertical sync output
    );

assign vga_red_o = '0;
assign vga_green_o = '0;
assign vga_blue_o = '0;
assign vga_hsync_o = '0;
assign vga_vsync_o = '0;
assign dsp_anode_o = '0;
assign dsp_cathode_o = '0;
assign uart_txd_o = '0;

// PS2 Controller
ps2_controller ps2_controller (
    .clk_i(sys_clk_i),
    .ps2_clk_io(ps2_clk_io),
    .ps2_data_io(ps2_data_io),
    .debug_o(led_o)
);

endmodule
