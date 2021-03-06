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
        input  wire logic        clk_i,

        // video ram interface
        output      logic [11:0] vram_addr_o,
        input  wire word_t       vram_data_i,

        // vga output
        output wire logic [ 3:0] vga_red_o,
        output wire logic [ 3:0] vga_green_o,
        output wire logic [ 3:0] vga_blue_o,
        output wire logic        vga_hsync_o,
        output wire logic        vga_vsync_o,

        // Bus Interface
        input  wire logic       bus_clk_i,
        input  wire logic       chip_select_i,
        input  wire logic [3:0] addr_i,
        input  wire logic       read_enable_i,
        output wire word_t      read_data_o,
        input  wire word_t      write_data_i,
        input  wire logic [3:0] write_mask_i
    );


//
// Display Parameters
//

localparam logic [6:0] CHAR_WIDTH    = 'd9;
localparam logic [6:0] CHAR_HEIGHT   = 'd16;
localparam logic [6:0] H_CHAR_MAX    = 'd99;

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


localparam logic [9:0] H_MAX = H_TOTAL - 1;
localparam logic [9:0] V_MAX = V_TOTAL - 1;

localparam logic [9:0] H_SYNC_START = H_ACTIVE + H_FRONT_PORCH;
localparam logic [9:0] H_SYNC_STOP  = H_SYNC_START + H_SYNC_PULSE;

localparam logic [9:0] V_SYNC_START = V_ACTIVE + V_FRONT_PORCH;
localparam logic [9:0] V_SYNC_STOP  = V_SYNC_START + V_SYNC_PULSE;


//
// Bus Access
//

// ports
typedef enum logic [3:0] {
    PORT_FONT = 4'b0000
} port_t;

// registers
logic [1:0] bus_font_r = '0;
logic [1:0] font_r [1:0];

// read
word_t read_data_r = '0;
assign read_data_o = read_data_r;
always_ff @(posedge bus_clk_i) begin
    if (chip_select_i && read_enable_i) begin
        case (addr_i)
        PORT_FONT: read_data_r <= { 30'b0, bus_font_r };
        default:   read_data_r <= 32'b0;
        endcase
    end
end

// write
always_ff @(posedge bus_clk_i) begin
    if (chip_select_i) begin
        case (addr_i)
        PORT_FONT:
            begin
                if (write_mask_i[0]) bus_font_r <= write_data_i[1:0];
            end
        default: ;
        endcase
    end
end

// clock domain transfer
always_ff @(posedge clk_i) begin
    font_r <= '{ bus_font_r, font_r[1] };
end


//
// VGA Logic
//

// frame counter
logic [4:0] frame_counter_r = '0;


// character roms
logic [11:0] crom_addr;
logic [8:0] crom_data [3:0];

character_rom #(
    .CONTENTS("crom1.mem")
) crom_inst_1 (
    .clk_i(clk_i),
    .read_enable_i(1'b1),
    .read_addr_i(crom_addr),
    .read_data_o(crom_data[0])
);

character_rom #(
    .CONTENTS("crom2.mem")
) crom_inst_2 (
    .clk_i(clk_i),
    .read_enable_i(1'b1),
    .read_addr_i(crom_addr),
    .read_data_o(crom_data[1])
);

character_rom #(
    .CONTENTS("crom3.mem")
) crom_inst_3 (
    .clk_i(clk_i),
    .read_enable_i(1'b1),
    .read_addr_i(crom_addr),
    .read_data_o(crom_data[2])
);

character_rom #(
    .CONTENTS("crom4.mem")
) crom_inst_4 (
    .clk_i(clk_i),
    .read_enable_i(1'b1),
    .read_addr_i(crom_addr),
    .read_data_o(crom_data[3])
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
byte_t      character;
logic [2:0] fg_red;
logic [3:0] fg_green;
logic [2:0] fg_blue;
logic [2:0] bg_red;
logic [3:0] bg_green;
logic [2:0] bg_blue;
logic       underline;
logic       blink;

always_comb begin
    {
        blink,
        underline,
        bg_blue,
        bg_green,
        bg_red,
        fg_blue,
        fg_green,
        fg_red,
        character
    } = vram_data_i[29:0];
end


// drive memory access off of upcoming x,y
always_comb begin
    // vram lookup is two pixels ahead
    vram_addr_o = { y_r[1][8:4], x_index_r[1] };
    // crom lookup is one pixel ahead
    crom_addr = { character, y_r[0][3:0] };
end


// font selection
logic [8:0] selected_crom_data;
always_comb selected_crom_data = crom_data[font_r[0]];

// determine rgb values
logic alpha;

always_comb begin
    // character nibbles are 4-bit alpha blend values for each pixel
    unique case (x_offset_r[0])
    0: alpha = selected_crom_data[8];
    1: alpha = selected_crom_data[7];
    2: alpha = selected_crom_data[6];
    3: alpha = selected_crom_data[5];
    4: alpha = selected_crom_data[4];
    5: alpha = selected_crom_data[3];
    6: alpha = selected_crom_data[2];
    7: alpha = selected_crom_data[1];
    8: alpha = selected_crom_data[0];
    endcase

    // in underline mode, draw a solid line 14 pixels down
    if (y_r[0][3:0] == 14 && underline)
        alpha = 1'b1;

    // hide character every 16 frames
    if (blink && frame_counter_r[4])
        alpha = 1'b0;
end

logic [3:0] red;
logic [3:0] green;
logic [3:0] blue;

always_comb begin
    red   = { (alpha ? fg_red   : bg_red),  1'b0 };
    green =   (alpha ? fg_green : bg_green);
    blue  = { (alpha ? fg_blue  : bg_blue), 1'b0 };
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
    vga_red_r   <= red;
    vga_green_r <= green;
    vga_blue_r  <= blue;
    vga_hsync_r <= !((x_r[0] >= H_SYNC_START) && (x_r[0] < H_SYNC_STOP));
    vga_vsync_r <= !((y_r[0] >= V_SYNC_START) && (y_r[0] < V_SYNC_STOP));

    if ((x_r[0] >= H_ACTIVE) || (y_r[0] >= V_ACTIVE)) begin
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
