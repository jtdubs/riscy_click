`timescale 1ns / 1ps
`default_nettype none

//
// VGA Controller - 640x480@60hz
//

module vga_controller
    // Import Constants
    import common::*;
    (
        input  wire logic        clk_pxl_i, // 100MHz system clock
        input  wire logic        reset_i,   // reset
        
        // video ram interface
        output      logic [11:0] vram_addr_o,
        input  wire logic [ 7:0] vram_data_i,
    
        // vga output
        output      logic [ 3:0] vga_red_o,
        output      logic [ 3:0] vga_green_o,
        output      logic [ 3:0] vga_blue_o,
        output      logic        vga_hsync_o,
        output      logic        vga_vsync_o
    );


// character rom
logic [11:0] crom_addr_w;
logic [ 7:0] crom_data_w;    

character_rom #(
    .CONTENTS("crom.mem")
)
crom_inst (
    .clk_i(clk_pxl_i),
    .reset_i(reset_i),
    .addr_i(crom_addr_w),
    .data_o(crom_data_w)
);


// keep track of x & y coordinates
logic [9:0] x_r, x_w;
logic [9:0] y_r, y_w;

always_comb begin
    if (x_r == 10'd799) begin
        x_w = 10'b0;
        if (y_r == 10'd524)
            y_w = 10'b0;
        else
            y_w = y_r + 1;
    end else begin
        x_w = x_r + 1;
        y_w = y_r; 
    end 
end

always_ff @(posedge clk_pxl_i) begin
    x_r <= reset_i ? 10'd799 : x_w;
    y_r <= reset_i ? 10'd524 : y_w;
end


// determine display area & sync signals
logic display_area_w;
logic hsync_w;
logic vsync_w;

always_comb begin
    //horizontal:
    //[  0-639] - active
    //[640-655] - blank
    //[656-751] - hsync
    //[752-799] - blank
    
    //vertical:
    //[  0-479] - active
    //[480-489] - blank
    //[490-491] - vsync
    //[492-524] - blank
    
    display_area_w = (x_w <= 640) && (y_w <= 480);
    hsync_w = (x_w >= 656) && (x_w <= 751);
    vsync_w = (y_w >= 490) && (y_w <= 491); 
end


// determine rgb values
logic [3:0] r_w, g_w, b_w;

always_comb begin
    r_w = x_w[7:4];
    g_w = y_w[7:4];
    b_w = y_w[8:5];
end

always_ff @(posedge clk_pxl_i) begin
    vga_hsync_o <= !hsync_w;
    vga_vsync_o <= !vsync_w;
    vga_red_o   <= display_area_w ? r_w : 4'b0000;
    vga_green_o <= display_area_w ? g_w : 4'b0000;
    vga_blue_o  <= display_area_w ? b_w : 4'b0000;
end


endmodule
