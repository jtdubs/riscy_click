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
        input  wire logic        clk_cpu_i,        // 50MHz CPU clock
        input  wire logic        clk_pxl_i,        // 25.2MHz pixel clock
        input  wire logic        ps2_clk_async_i,  // PS2 HID clock (async)
        input  wire logic        ps2_data_async_i, // PS2 HID data (async)

        // Inputs
        input  wire logic        reset_async_i,    // async reset input
        input  wire logic [15:0] switch_async_i,   // async hardware switch bank input

        // Outputs
        output wire logic        halt_o,           // halt output
        output wire logic [ 7:0] dsp_anode_o,      // seven segment display anodes output
        output wire logic [ 7:0] dsp_cathode_o,    // seven segment display cathodes output
        output wire logic [ 3:0] vga_red_o,        // vga red output
        output wire logic [ 3:0] vga_green_o,      // vga green output
        output wire logic [ 3:0] vga_blue_o,       // vga blue output
        output wire logic        vga_hsync_o,      // vga horizontal sync output
        output wire logic        vga_vsync_o       // vga vertical sync output
    );


//
// Clocked Resets
//

localparam integer RESET_CYCLES = 12;
localparam logic [RESET_CYCLES-1:0] RESET_ONES = {RESET_CYCLES{1'b1}};

logic                    cpu_reset_r;
logic [RESET_CYCLES-1:0] cpu_reset_chain_r;

always_ff @(posedge clk_cpu_i) begin
    if (reset_async_i)
        // if resetting, fill the chain with ones
        { cpu_reset_r, cpu_reset_chain_r } <= { 1'b1, RESET_ONES };
    else
        // otherwise, start shifting out the ones
        { cpu_reset_r, cpu_reset_chain_r } <= { cpu_reset_chain_r, 1'b0 };
end

logic                    pxl_reset_r;
logic [RESET_CYCLES-1:0] pxl_reset_chain_r;

always_ff @(posedge clk_pxl_i) begin
    if (reset_async_i)
        // if resetting, fill the chain with ones
        { pxl_reset_r, pxl_reset_chain_r } <= { 1'b1, RESET_ONES };
    else
        // otherwise, start shifting out the ones
        { pxl_reset_r, pxl_reset_chain_r } <= { pxl_reset_chain_r, 1'b0 };
end


//
// Keyboard Controller
//

byte_t      ps2_data_w;
logic       ps2_valid_w;
kbd_event_t kbd_event_w;
logic       kbd_valid_w;

ps2_rx ps2_rx (
    .clk_i            (clk_cpu_i),
    .reset_i          (cpu_reset_r),
    .clk_ps2_async_i  (ps2_clk_async_i),
    .ps2_data_async_i (ps2_data_async_i),
    .data_o           (ps2_data_w),
    .valid_o          (ps2_valid_w)
);

ps2_kbd ps2_kbd (
    .clk_i            (clk_cpu_i),
    .reset_i          (cpu_reset_r),
    .data_i           (ps2_data_w),
    .valid_i          (ps2_valid_w),
    .event_o          (kbd_event_w),
    .valid_o          (kbd_valid_w)
);


//
// Clock in Switch States
//

logic [15:0] switch_r;

always_ff @(posedge clk_cpu_i) begin
    switch_r <= switch_async_i;
end


//
// Memory Signals
//

// Instruction Memory
wire word_t      imem_addr_w;
wire word_t      imem_data_w;

// Data Memory
wire word_t      dmem_addr_w;
     word_t      dmem_read_data_w;
wire word_t      dmem_write_data_w;
wire logic [3:0] dmem_write_mask_w;

// Write Masks
     logic [3:0] dsp_write_mask_w;
     logic [3:0] ram_write_mask_w;
     logic [3:0] vram_write_mask_w;

// Device
wire word_t      dsp_read_data_w;
wire word_t      bios_read_data_w;
wire word_t      ram_read_data_w;
wire word_t      vram_read_data_w;


//
// Devices
//

// BIOS
bios_rom #(.CONTENTS("bios.mem")) bios (
    .clk_i        (clk_cpu_i),
    .reset_i      (1'b0),
    .read1_addr_i (imem_addr_w),
    .read1_data_o (imem_data_w),
    .read2_addr_i (dmem_addr_w),
    .read2_data_o (bios_read_data_w)
);

// RAM
system_ram ram (
    .clk_i        (clk_cpu_i),
    .reset_i      (1'b0),
    .addr_i       (dmem_addr_w),
    .write_data_i (dmem_write_data_w),
    .write_mask_i (ram_write_mask_w),
    .read_data_o  (ram_read_data_w)
);

// Display
segdisplay #(.CLK_DIVISOR(50000)) disp (
    .clk_i         (clk_cpu_i),
    .reset_i       (cpu_reset_r),
    .dsp_anode_o   (dsp_anode_o),
    .dsp_cathode_o (dsp_cathode_o),
    .read_data_o   (dsp_read_data_w),
    .write_data_i  ({ 22'b0, kbd_event_w }), // dmem_write_data_w),
    .write_mask_i  ({4{kbd_valid_w}})        //   dsp_write_mask_w)
);

logic [11:0] vga_vram_addr_w;
byte_t       vga_vram_data_w;

video_ram vram (
    // cpu port
    .clk_cpu_i        (clk_cpu_i),
    .cpu_reset_i      (cpu_reset_r),
    .cpu_addr_i       (dmem_addr_w),
    .cpu_write_data_i (dmem_write_data_w),
    .cpu_write_mask_i (vram_write_mask_w),
    .cpu_read_data_o  (vram_read_data_w),

    // vga port
    .clk_pxl_i        (clk_pxl_i),
    .pxl_reset_i      (pxl_reset_r),
    .pxl_addr_i       (vga_vram_addr_w),
    .pxl_data_o       (vga_vram_data_w)
);

// VGA
vga_controller vga (
    .clk_pxl_i   (clk_pxl_i),
    .reset_i     (pxl_reset_r),
    .vram_addr_o (vga_vram_addr_w),
    .vram_data_i (vga_vram_data_w),
    .vga_red_o   (vga_red_o),
    .vga_green_o (vga_green_o),
    .vga_blue_o  (vga_blue_o),
    .vga_hsync_o (vga_hsync_o),
    .vga_vsync_o (vga_vsync_o)
);


//
// Address decoding
//
// Memory map:
// 00000000 - 0FFFFFFF: BIOS
// 10000000 - 1FFFFFFF: RAM
// 20000000 - 2FFFFFFF: Video RAM
// 30000000 - FEFFFFFF: UNMAPPED
// FF000000:            Seven Segment Display
// FF000004:            Switch Bank
// FF000008 - FFFFFFFF: UNMAPPED
//
word_t dmem_read_addr_r;

always_ff @(posedge clk_cpu_i) begin
    dmem_read_addr_r <= cpu_reset_r ? 32'h00000000 : dmem_addr_w;
end

always_comb begin
    ram_write_mask_w  = (dmem_addr_w[31:28] == 4'h1)         ? dmem_write_mask_w : 4'b0000;
    dsp_write_mask_w  = (dmem_addr_w        == 32'hFF000000) ? dmem_write_mask_w : 4'b0000;
    vram_write_mask_w = (dmem_addr_w[31:28] == 4'h2)         ? dmem_write_mask_w : 4'b0000;

    casez (dmem_read_addr_r)
    32'h0???????: begin dmem_read_data_w = bios_read_data_w;     end
    32'h1???????: begin dmem_read_data_w = ram_read_data_w;      end
    32'h2???????: begin dmem_read_data_w = vram_read_data_w;     end
    32'hFF000000: begin dmem_read_data_w = dsp_read_data_w;      end
    32'hFF000004: begin dmem_read_data_w = { 16'h00, switch_r }; end
    default:      begin dmem_read_data_w = 32'h00000000;         end
    endcase
end


//
// CPU
//

cpu cpu (
    .clk_i             (clk_cpu_i),
    .reset_i           (cpu_reset_r),
    .halt_o            (halt_o),
    .imem_addr_o       (imem_addr_w),
    .imem_data_i       (imem_data_w),
    .dmem_addr_o       (dmem_addr_w),
    .dmem_read_data_i  (dmem_read_data_w),
    .dmem_write_data_o (dmem_write_data_w),
    .dmem_write_mask_o (dmem_write_mask_w)
);

//
// Debug Counter
//

(* KEEP = "TRUE" *) word_t cycle_counter_r;

always_ff @(posedge clk_cpu_i) begin
    cycle_counter_r <= cpu_reset_r ? 32'h00000000 : (cycle_counter_r + 1);
end

endmodule
