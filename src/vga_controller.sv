`timescale 1ns / 1ps
`default_nettype none

//
// VGA Controller - 640x480@60hz
//

// was 148 cells, 211 nets

module vga_controller
    // Import Constants
    import common::*;
    (
        input  wire logic        clk_i,     // 25.2MHz pixel clock
        input  wire logic        reset_i,   // reset

        // video ram interface
        output      logic [11:0] vram_addr_o,
        input  wire byte_t       vram_data_i,

        // vga output
        output wire logic [ 3:0] vga_red_o,
        output wire logic [ 3:0] vga_green_o,
        output wire logic [ 3:0] vga_blue_o,
        output wire logic        vga_hsync_o,
        output wire logic        vga_vsync_o
    );


// character rom
logic [11:0] crom_addr_w;
logic [31:0] crom_data_w;

character_rom #(
    .CONTENTS("crom.mem")
)
crom_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .addr_i(crom_addr_w),
    .data_o(crom_data_w)
);


// keep track next two x,y coordinates
logic [9:0] x_r [1:0] = '{ default: '0 };
logic [9:0] y_r [1:0] = '{ default: '0 };

always_ff @(posedge clk_i) begin
    x_r[0] <= x_r[1];
    y_r[0] <= y_r[1];

    unique if (x_r[1] == 'd799) begin
        x_r[1] <= 'd0;
        unique if (y_r[1] == 'd524)
            y_r[1] <= 'd0;
        else
            y_r[1] <= y_r[1] + 1;
    end else
        x_r[1] <= x_r[1] + 1;

    if (reset_i) begin
        { x_r[0], x_r[1] } <= 20'b0;
        { y_r[0], y_r[1] } <= 20'b0;
    end
end


// drive memory access off of upcoming x,y
always_comb begin
    // vram lookup is two pixels ahead
    vram_addr_o = { y_r[1][8:4], x_r[1][9:3] };
    // crom lookup is one pixel ahead
    crom_addr_w = { vram_data_i, y_r[0][3:0] };
end


// determine rgb values
logic [3:0] rgb_w;

always_comb begin
    // character nibbles are 4-bit grayscale values for each pixel
    unique case (x_r[0][2:0])
    1: rgb_w = crom_data_w[31:28];
    2: rgb_w = crom_data_w[27:24];
    3: rgb_w = crom_data_w[23:20];
    4: rgb_w = crom_data_w[19:16];
    5: rgb_w = crom_data_w[15:12];
    6: rgb_w = crom_data_w[11: 8];
    7: rgb_w = crom_data_w[ 7: 4];
    0: rgb_w = crom_data_w[ 3: 0];
    endcase
end

//
// Output signals
//

logic [ 3:0] vga_red_r   = '0;
logic [ 3:0] vga_green_r = '0;
logic [ 3:0] vga_blue_r  = '0;
logic        vga_hsync_r = '1;
logic        vga_vsync_r = '1;

always_ff @(posedge clk_i) begin
    // signals are based on the NEXT x,y
    vga_red_r   <= rgb_w;
    vga_green_r <= rgb_w;
    vga_blue_r  <= rgb_w;
    vga_hsync_r <= !((x_r[0] >= 657) && (x_r[0] < 753));
    vga_vsync_r <= !((y_r[0] >= 491) && (y_r[0] < 493));

    if ((x_r[0] >= 639) || (y_r[0] >= 479)) begin
        vga_red_r   <= 4'b0000;
        vga_green_r <= 4'b0000;
        vga_blue_r  <= 4'b0000;
    end

    if (reset_i) begin
        vga_red_r   <= 4'b0000;
        vga_green_r <= 4'b0000;
        vga_blue_r  <= 4'b0000;
        vga_hsync_r <= 1'b1;
        vga_vsync_r <= 1'b1;
    end
end

assign vga_red_o   = vga_red_r;
assign vga_green_o = vga_green_r;
assign vga_blue_o  = vga_blue_r;
assign vga_hsync_o = vga_hsync_r;
assign vga_vsync_o = vga_vsync_r;

endmodule
