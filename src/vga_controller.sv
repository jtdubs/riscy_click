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

        // video ram interface
        output      logic [11:0] vram_addr_o,
        input  wire word_t       vram_data_i,

        // vga output
        output wire logic [ 3:0] vga_red_o,
        output wire logic [ 3:0] vga_green_o,
        output wire logic [ 3:0] vga_blue_o,
        output wire logic        vga_hsync_o,
        output wire logic        vga_vsync_o
    );


//
// Display Parameters
//

localparam logic [6:0] CHAR_WIDTH    = 'd9;
localparam logic [6:0] CHAR_HEIGHT   = 'd16;

localparam logic [9:0] H_ACTIVE      = 'd726;
localparam logic [9:0] H_FRONT_PORCH = 'd15;
localparam logic [9:0] H_SYNC_PULSE  = 'd108;
localparam logic [9:0] H_BACK_PORCH  = 'd51;
localparam logic [9:0] H_TOTAL       = (H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH);

localparam logic [9:0] V_ACTIVE      = 'd404;
localparam logic [9:0] V_FRONT_PORCH = 'd11;
localparam logic [9:0] V_SYNC_PULSE  = 'd2;
localparam logic [9:0] V_BACK_PORCH  = 'd32;
localparam logic [9:0] V_TOTAL       = (V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH);


//
// Computed Parameters
//

localparam logic [6:0] H_CHAR_MAX = 'd99; // { (H_TOTAL / {3'b0, CHAR_WIDTH}) - '1 }[6:0];

localparam logic [9:0] H_MAX = H_TOTAL - 1;
localparam logic [9:0] V_MAX = V_TOTAL - 1;

localparam logic [9:0] H_SYNC_START = H_ACTIVE + H_FRONT_PORCH;
localparam logic [9:0] H_SYNC_STOP  = H_SYNC_START + H_SYNC_PULSE;

localparam logic [9:0] V_SYNC_START = V_ACTIVE + V_FRONT_PORCH;
localparam logic [9:0] V_SYNC_STOP  = V_SYNC_START + V_SYNC_PULSE;


// frame counter
logic [4:0] frame_counter_r = '0;


// character rom
logic [11:0] crom_addr_w;
logic [35:0] crom_data_w;

character_rom #(
    .CONTENTS("crom.mem")
)
crom_inst (
    .clk_i(clk_i),
    .read_enable_i(1'b1),
    .read_addr_i(crom_addr_w),
    .read_data_o(crom_data_w)
);


// keep track next two x,y coordinates
logic [9:0] x_r [1:0] = '{ default: '0 };
logic [9:0] y_r [1:0] = '{ default: '0 };

always_ff @(posedge clk_i) begin
    x_r[0] <= x_r[1];
    y_r[0] <= y_r[1];

    unique if (x_r[1] == H_MAX) begin
        x_r[1] <= 'd0;

        unique if (y_r[1] == V_MAX) begin
            y_r[1] <= 'd0;
            frame_counter_r <= frame_counter_r + 1;
        end else begin
            y_r[1] <= y_r[1] + 1;
        end

    end else begin
        x_r[1] <= x_r[1] + 1;
    end
end

// also keep track of the next two x char indexes and offsets
logic [3:0] x_offset_r [1:0] = '{ default: '0 };
logic [6:0] x_index_r  [1:0] = '{ default: '0 };

always_ff @(posedge clk_i) begin
    x_offset_r[0] <= x_offset_r[1];
    x_index_r[0]  <= x_index_r[1];

    unique if (x_offset_r[1] == 'd8) begin
        x_offset_r[1] <= 4'd0;
        if (x_index_r[1] == H_CHAR_MAX)
            x_index_r[1] <= 7'd0;
        else
            x_index_r[1] <= x_index_r[1] + 1;
    end else begin
        x_offset_r[1] <= x_offset_r[1] + 1;
    end
end


// unpack video ram data
byte_t      character_w;
logic [2:0] fg_red_w;
logic [3:0] fg_green_w;
logic [2:0] fg_blue_w;
logic [2:0] bg_red_w;
logic [3:0] bg_green_w;
logic [2:0] bg_blue_w;
logic       underline_w;
logic       blink_w;

always_comb begin
    {
        blink_w,
        underline_w,
        bg_blue_w,
        bg_green_w,
        bg_red_w,
        fg_blue_w,
        fg_green_w,
        fg_red_w,
        character_w
    } = vram_data_i[29:0];
end


// drive memory access off of upcoming x,y
always_comb begin
    // vram lookup is two pixels ahead
    vram_addr_o = { y_r[1][8:4], x_index_r[1] };
    // crom lookup is one pixel ahead
    crom_addr_w = { character_w, y_r[0][3:0] };
end


// determine rgb values
logic [3:0] alpha_w;

always_comb begin
    // character nibbles are 4-bit alpha blend values for each pixel
    unique case (x_offset_r[0])
    0: alpha_w = crom_data_w[ 3: 0];
    1: alpha_w = crom_data_w[35:32];
    2: alpha_w = crom_data_w[31:28];
    3: alpha_w = crom_data_w[27:24];
    4: alpha_w = crom_data_w[23:20];
    5: alpha_w = crom_data_w[19:16];
    6: alpha_w = crom_data_w[15:12];
    7: alpha_w = crom_data_w[11: 8];
    8: alpha_w = crom_data_w[ 7: 4];
    endcase

    // in underline mode, draw a solid line 14 pixels down
    if (y_r[0][3:0] == 14 && underline_w)
        alpha_w = 4'b1111;

    // hide character every 16 frames
    if (blink_w && frame_counter_r[4])
        alpha_w = 4'b0000;
end

logic [3:0] red_w;
logic [3:0] green_w;
logic [3:0] blue_w;

logic [7:0] alpha_wide_w;
logic [7:0] neg_alpha_wide_w;

always_comb begin
    alpha_wide_w     = { 4'b0,         alpha_w  };
    neg_alpha_wide_w = { 4'b0, (4'hF - alpha_w) };

    red_w   = { ((alpha_wide_w * fg_red_w)   + (neg_alpha_wide_w * bg_red_w))   }[6:3];
    green_w = { ((alpha_wide_w * fg_green_w) + (neg_alpha_wide_w * bg_green_w)) }[7:4];
    blue_w  = { ((alpha_wide_w * fg_blue_w)  + (neg_alpha_wide_w * bg_blue_w))  }[6:3];
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
    vga_red_r   <= red_w;
    vga_green_r <= green_w;
    vga_blue_r  <= blue_w;
    vga_hsync_r <= !((x_r[0] >= (H_SYNC_START-1)) && (x_r[0] < (H_SYNC_STOP-1)));
    vga_vsync_r <= !((y_r[0] >= (V_SYNC_START-1)) && (y_r[0] < (V_SYNC_STOP-1)));

    if ((x_r[0] > H_ACTIVE) || (y_r[0] > V_ACTIVE)) begin
        vga_red_r   <= 4'b0000;
        vga_green_r <= 4'b0000;
        vga_blue_r  <= 4'b0000;
    end

    // $strobe("VGA (%0d, %0d) H:%0d V:%0d", x_r[0], y_r[0], vga_hsync_r, vga_vsync_r);
end

assign vga_red_o   = vga_red_r;
assign vga_green_o = vga_green_r;
assign vga_blue_o  = vga_blue_r;
assign vga_hsync_o = vga_hsync_r;
assign vga_vsync_o = vga_vsync_r;

endmodule
