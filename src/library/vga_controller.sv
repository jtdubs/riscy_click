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
logic [31:0] crom_data_w;

character_rom #(
`ifdef VERILATOR
    .CONTENTS("../roms/character_rom/crom.mem")
`else
    .CONTENTS("crom.mem")
`endif
)
crom_inst (
    .clk_i(clk_pxl_i),
    .reset_i(reset_i),
    .addr_i(crom_addr_w),
    .data_o(crom_data_w)
);


// keep track of x & y coordinates
logic [9:0] x_r, x_w, x_lookahead_w;
logic [9:0] y_r, y_w, y_lookahead_w;

// next pixel needed to plan new RGB values
always_comb begin
    x_w = x_r + 1;
    y_w = y_r;

    if (x_w >= 10'd800) begin
        x_w = x_w - 10'd800;
        y_w = y_r + 1;
    end

    if (y_w >= 525)
        y_w = 10'd0;
end

// 8 pixels from now needed to start memory lookups for next tile
always_comb begin
    x_lookahead_w = x_r + 8;
    y_lookahead_w = y_r;

    if (x_lookahead_w >= 10'd800) begin
        x_lookahead_w = x_lookahead_w - 10'd800;
        y_lookahead_w = y_lookahead_w + 1;
    end

    if (y_lookahead_w >= 525)
        y_lookahead_w = 10'd0;
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


// keep track of character location
logic [2:0] x_char_offset_w;

logic [6:0] x_lookahead_char_index_w;
logic [4:0] y_lookahead_char_index_w;
logic [3:0] y_lookahead_char_offset_w;

always_comb begin
    x_char_offset_w = x_w[2:0];
    x_lookahead_char_index_w = x_lookahead_w[9:3];
    { y_lookahead_char_index_w, y_lookahead_char_offset_w } = y_lookahead_w[8:0];
end


// keep track of character row
logic [31:0] char_row_r, char_row_w;

always_comb begin
    vram_addr_o = { y_lookahead_char_index_w[4:0], x_lookahead_char_index_w };
    crom_addr_w = { vram_data_i, y_lookahead_char_offset_w };
    char_row_w  = crom_data_w;
end

always_ff @(posedge clk_pxl_i) begin
    if (x_char_offset_w == 3'b111)
        char_row_r <= char_row_w;

    if (reset_i)
        char_row_r <= 32'b0;
end


// determine rgb values
logic [3:0] rgb_w;

always_comb begin
    unique case (x_char_offset_w)
    0: rgb_w = char_row_r[31:28];
    1: rgb_w = char_row_r[27:24];
    2: rgb_w = char_row_r[23:20];
    3: rgb_w = char_row_r[19:16];
    4: rgb_w = char_row_r[15:12];
    5: rgb_w = char_row_r[11: 8];
    6: rgb_w = char_row_r[ 7: 4];
    7: rgb_w = char_row_r[ 3: 0];
    endcase
end

always_ff @(posedge clk_pxl_i) begin
    vga_hsync_o <= !hsync_w;
    vga_vsync_o <= !vsync_w;
    vga_red_o   <= display_area_w ? rgb_w : 4'b0000;
    vga_green_o <= display_area_w ? rgb_w : 4'b0000;
    vga_blue_o  <= display_area_w ? rgb_w : 4'b0000;
end


endmodule
