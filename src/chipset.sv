`timescale 1ns / 1ps
`default_nettype none

///
/// Chips and Supporting Circuitry
///

module chipset
    // Import Constants
    import common::*;
    (
        // Clocks
        input  wire logic        cpu_clk_i,      // 50MHz CPU clock
        input  wire logic        pxl_clk_i,      // 25.2MHz pixel clock
        input  wire logic        ps2_clk_i,      // PS2 HID clock (async)
        input  wire logic        ps2_data_i,     // PS2 HID data (async)

        // Inputs
        input  wire logic [15:0] switch_i,       // async hardware switch bank input

        // Outputs
        output wire logic        halt_o,         // halt output
        output wire logic [ 7:0] dsp_anode_o,    // seven segment display anodes output
        output wire logic [ 7:0] dsp_cathode_o,  // seven segment display cathodes output
        output wire logic [ 3:0] vga_red_o,      // vga red output
        output wire logic [ 3:0] vga_green_o,    // vga green output
        output wire logic [ 3:0] vga_blue_o,     // vga blue output
        output wire logic        vga_hsync_o,    // vga horizontal sync output
        output wire logic        vga_vsync_o     // vga vertical sync output
    );


//
// CPU
//

wire logic       interrupt_w;
wire word_t      imem_addr_w;
wire word_t      imem_data_w;
wire word_t      dmem_addr_w;
     word_t      dmem_read_data_w;
wire word_t      dmem_write_data_w;
wire logic [3:0] dmem_write_mask_w;

cpu cpu (
    .clk_i             (cpu_clk_i),
    .interrupt_i       (interrupt_w),
    .halt_o            (halt_o),
    .imem_addr_o       (imem_addr_w),
    .imem_data_i       (imem_data_w),
    .dmem_addr_o       (dmem_addr_w),
    .dmem_read_data_i  (dmem_read_data_w),
    .dmem_write_data_o (dmem_write_data_w),
    .dmem_write_mask_o (dmem_write_mask_w)
);


//
// Chip Select
//

typedef struct packed {
    logic bios;
    logic ram;
    logic vram;
    logic keyboard;
    logic display;
    logic switches;
} chip_select_t;

chip_select_t chip_select_w;
chip_select_t chip_select_r;

wire word_t bios_read_data_w;
wire word_t ram_read_data_w;
wire word_t vram_read_data_w;
wire word_t kbd_read_data_w;
wire word_t dsp_read_data_w;
wire word_t sw_read_data_w;

always_ff @(posedge cpu_clk_i) begin
    chip_select_r <= chip_select_w;
end

always_comb begin
    unique casez (dmem_addr_w)
    32'h0???????: chip_select_w = '{ bios:     1'b1, default: 1'b0 };
    32'h1???????: chip_select_w = '{ ram:      1'b1, default: 1'b0 };
    32'h2???????: chip_select_w = '{ vram:     1'b1, default: 1'b0 };
    32'hFF000000: chip_select_w = '{ display:  1'b1, default: 1'b0 };
    32'hFF000004: chip_select_w = '{ switches: 1'b1, default: 1'b0 };
    32'hFF000008: chip_select_w = '{ keyboard: 1'b1, default: 1'b0 };
    default:      chip_select_w = '{                 default: 1'b0 };
    endcase
end

always_comb begin
    if (chip_select_r.bios)
        dmem_read_data_w = bios_read_data_w;
    else if (chip_select_r.ram)
        dmem_read_data_w = ram_read_data_w;
    else if (chip_select_r.vram)
        dmem_read_data_w = vram_read_data_w;
    else if (chip_select_r.keyboard)
        dmem_read_data_w = kbd_read_data_w;
    else if (chip_select_r.display)
        dmem_read_data_w = dsp_read_data_w;
    else if (chip_select_r.switches)
        dmem_read_data_w = sw_read_data_w;
    else
        dmem_read_data_w = 32'b0;
end


//
// Devices
//


// Switches
logic [31:0] switch_r = '0;

always_ff @(posedge cpu_clk_i) begin
    switch_r[15:0] <= switch_i;
end

assign sw_read_data_w = switch_r;


// Keyboard Controller
kbd_event_t kbd_event_w;
logic       kbd_valid_w;

kbd_controller kbd (
    .clk_i         (cpu_clk_i),
    .ps2_clk_i     (ps2_clk_i),
    .ps2_data_i    (ps2_data_i),
    .read_enable_i (chip_select_w.keyboard),
    .read_data_o   (kbd_event_w),
    .read_valid_o  (kbd_valid_w),
    .interrupt_o   (interrupt_w)
);

assign kbd_read_data_w = { 15'b0, kbd_valid_w, 7'b0, kbd_event_w };


// BIOS
bios_rom #(.CONTENTS("bios.mem")) bios (
    .clk_i          (cpu_clk_i),
    .read1_enable_i (1'b1),
    .read1_addr_i   (imem_addr_w),
    .read1_data_o   (imem_data_w),
    .read2_enable_i (chip_select_w.bios),
    .read2_addr_i   (dmem_addr_w),
    .read2_data_o   (bios_read_data_w)
);


// RAM
system_ram ram (
    .clk_i         (cpu_clk_i),
    .chip_select_i (chip_select_w.ram),
    .addr_i        (dmem_addr_w),
    .write_data_i  (dmem_write_data_w),
    .write_mask_i  (dmem_write_mask_w),
    .read_data_o   (ram_read_data_w)
);


// Display
segdisplay #(.CLK_DIVISOR(50000)) disp (
    .clk_i         (cpu_clk_i),
    .dsp_anode_o   (dsp_anode_o),
    .dsp_cathode_o (dsp_cathode_o),
    .chip_select_i (chip_select_w.display),
    .read_data_o   (dsp_read_data_w),
    .write_data_i  (dmem_write_data_w),
    .write_mask_i  (dmem_write_mask_w)
);


// Video RAM
logic [11:0] vga_vram_addr_w;
byte_t       vga_vram_data_w;

video_ram vram (
    // cpu port
    .cpu_clk_i         (cpu_clk_i),
    .cpu_chip_select_i (chip_select_w.vram),
    .cpu_addr_i        (dmem_addr_w),
    .cpu_write_data_i  (dmem_write_data_w),
    .cpu_write_mask_i  (dmem_write_mask_w),
    .cpu_read_data_o   (vram_read_data_w),

    // vga port
    .pxl_clk_i         (pxl_clk_i),
    .pxl_chip_select_i (1'b1),
    .pxl_addr_i        (vga_vram_addr_w),
    .pxl_data_o        (vga_vram_data_w)
);


// VGA
vga_controller vga (
    .clk_i       (pxl_clk_i),
    .vram_addr_o (vga_vram_addr_w),
    .vram_data_i (vga_vram_data_w),
    .vga_red_o   (vga_red_o),
    .vga_green_o (vga_green_o),
    .vga_blue_o  (vga_blue_o),
    .vga_hsync_o (vga_hsync_o),
    .vga_vsync_o (vga_vsync_o)
);


endmodule
