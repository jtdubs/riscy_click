`timescale 1ns / 1ps
`default_nettype none

///
/// Top
///

module top
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

        // Halt
        output wire logic        halt_o,         // halt output

        // PS/2
        input  wire logic        ps2_clk_i,      // PS2 HID clock (async)
        input  wire logic        ps2_data_i,     // PS2 HID data (async)

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


//
// Clocks
//

`ifndef USE_EXTERNAL_CLOCKS
wire logic cpu_clk_i;
wire logic pxl_clk_i;

clk_gen clk_gen (
    .sys_clk_i     (sys_clk_i),
    .cpu_clk_o     (cpu_clk_i),
    .pxl_clk_o     (pxl_clk_i),
    .ready_async_o ()
);
`endif


//
// CPU
//

wire logic         interrupt;
wire word_t        imem_addr;
wire word_t        imem_data;
wire chip_select_t chip_select;
wire word_t        bus_addr;
     word_t        bus_read_data;
wire logic         bus_read_enable;
wire word_t        bus_write_data;
wire logic [3:0]   bus_write_mask;

chipset chipset (
    .clk_i              (cpu_clk_i),
    .interrupt_i        (interrupt),
    .halt_o             (halt_o),
    .imem_addr_o        (imem_addr),
    .imem_data_i        (imem_data),
    .bus_chip_select_o  (chip_select),
    .bus_addr_o         (bus_addr),
    .bus_read_data_i    (bus_read_data),
    .bus_read_enable_o  (bus_read_enable),
    .bus_write_data_o   (bus_write_data),
    .bus_write_mask_o   (bus_write_mask)
);


//
// Chip Select
//

chip_select_t chip_select_r;

wire word_t bios_read_data;
wire word_t ram_read_data;
wire word_t vram_read_data;
wire word_t kbd_read_data;
wire word_t dsp_read_data;
wire word_t sw_read_data;
wire word_t uart_read_data;
wire word_t irq_read_data;
wire word_t vga_read_data;

always_ff @(posedge cpu_clk_i) begin
    chip_select_r <= chip_select;
end

always_comb begin
    if (chip_select_r.bios)
        bus_read_data = bios_read_data;
    else if (chip_select_r.ram)
        bus_read_data = ram_read_data;
    else if (chip_select_r.vram)
        bus_read_data = vram_read_data;
    else if (chip_select_r.keyboard)
        bus_read_data = kbd_read_data;
    else if (chip_select_r.display)
        bus_read_data = dsp_read_data;
    else if (chip_select_r.switches)
        bus_read_data = sw_read_data;
    else if (chip_select_r.uart)
        bus_read_data = uart_read_data;
    else if (chip_select_r.irq)
        bus_read_data = irq_read_data;
    else if (chip_select_r.vga)
        bus_read_data = vga_read_data;
    else
        bus_read_data = 32'b0;
end


//
// Bus Devices
//

// BIOS
bios_rom #(.CONTENTS("bios.mem")) bios (
    .clk_i             (cpu_clk_i),
    .read1_enable_i    (1'b1),
    .read1_addr_i      (imem_addr),
    .read1_data_o      (imem_data),
    .read2_enable_i    (chip_select.bios),
    .read2_addr_i      (bus_addr),
    .read2_data_o      (bios_read_data)
);

// RAM
system_ram ram (
    .clk_i             (cpu_clk_i),
    .chip_select_i     (chip_select.ram),
    .addr_i            (bus_addr),
    .read_data_o       (ram_read_data),
    .write_data_i      (bus_write_data),
    .write_mask_i      (bus_write_mask)
);

// Video RAM
logic [11:0] vga_vram_addr;
word_t       vga_vram_data;

video_ram vram (
    // cpu port
    .cpu_clk_i         (cpu_clk_i),
    .cpu_chip_select_i (chip_select.vram),
    .cpu_addr_i        (bus_addr),
    .cpu_read_data_o   (vram_read_data),
    .cpu_write_data_i  (bus_write_data),
    .cpu_write_mask_i  (bus_write_mask),

    // vga port
    .pxl_clk_i         (pxl_clk_i),
    .pxl_chip_select_i (1'b1),
    .pxl_addr_i        (vga_vram_addr),
    .pxl_data_o        (vga_vram_data)
);

// Keyboard Controller
wire logic kbd_interrupt;

keyboard_controller keyboard (
    .clk_i             (cpu_clk_i),
    .interrupt_o       (kbd_interrupt),
    .ps2_clk_i         (ps2_clk_i),
    .ps2_data_i        (ps2_data_i),
    .chip_select_i     (chip_select.keyboard),
    .addr_i            (bus_addr[5:2]),
    .read_enable_i     (bus_read_enable),
    .read_data_o       (kbd_read_data),
    .write_data_i      (bus_write_data),
    .write_mask_i      (bus_write_mask)
);

// Display
segment_display #(.CLK_DIVISOR(50000)) segment_display (
    .clk_i             (cpu_clk_i),
    .dsp_anode_o       (dsp_anode_o),
    .dsp_cathode_o     (dsp_cathode_o),
    .chip_select_i     (chip_select.display),
    .addr_i            (bus_addr[5:2]),
    .read_enable_i     (bus_read_enable),
    .read_data_o       (dsp_read_data),
    .write_data_i      (bus_write_data),
    .write_mask_i      (bus_write_mask)
);

// Switches
logic sw_interrupt;

switches switches (
    .clk_i             (cpu_clk_i),
    .interrupt_o       (sw_interrupt),
    .switch_i          (switch_i),
    .chip_select_i     (chip_select.switches),
    .addr_i            (bus_addr[5:2]),
    .read_enable_i     (bus_read_enable),
    .read_data_o       (sw_read_data),
    .write_data_i      (bus_write_data),
    .write_mask_i      (bus_write_mask)
);

// UART
logic uart_interrupt;

uart uart (
    .clk_i             (cpu_clk_i),
    .interrupt_o       (uart_interrupt),
    .rxd_i             (uart_rxd_i),
    .txd_o             (uart_txd_o),
    .chip_select_i     (chip_select.uart),
    .addr_i            (bus_addr[5:2]),
    .read_enable_i     (bus_read_enable),
    .read_data_o       (uart_read_data),
    .write_data_i      (bus_write_data),
    .write_mask_i      (bus_write_mask)
);

// IRQ
interrupt_controller irq (
    .clk_i             (cpu_clk_i),
    .interrupt_i       ({ 29'b0, sw_interrupt, kbd_interrupt, uart_interrupt }),
    .interrupt_o       (interrupt),
    .chip_select_i     (chip_select.irq),
    .addr_i            (bus_addr[5:2]),
    .read_enable_i     (bus_read_enable),
    .read_data_o       (irq_read_data),
    .write_data_i      (bus_write_data),
    .write_mask_i      (bus_write_mask)
);

// VGA
vga_controller vga (
    .clk_i             (pxl_clk_i),
    .vram_addr_o       (vga_vram_addr),
    .vram_data_i       (vga_vram_data),
    .vga_red_o         (vga_red_o),
    .vga_green_o       (vga_green_o),
    .vga_blue_o        (vga_blue_o),
    .vga_hsync_o       (vga_hsync_o),
    .vga_vsync_o       (vga_vsync_o),
    .bus_clk_i         (cpu_clk_i),
    .chip_select_i     (chip_select.vga),
    .addr_i            (bus_addr[5:2]),
    .read_enable_i     (bus_read_enable),
    .read_data_o       (vga_read_data),
    .write_data_i      (bus_write_data),
    .write_mask_i      (bus_write_mask)
);


endmodule
