`timescale 1ns / 1ps
`default_nettype none

///
/// CPU with Chip Select logic
///

module chipset
    // Import Constants
    import common::*;
    (
        // Clock
        input  wire logic         clk_i,

        // CPU Signals
        output wire logic         halt_o,            // halt
        input  wire logic         interrupt_i,       // internal interrupt

        // Instruction Bus
        output wire word_t        imem_addr_o,
        input  wire word_t        imem_data_i,

        // Data Bus
        output      chip_select_t bus_chip_select_o, // chip select
        output wire word_t        bus_addr_o,        // r/w address
        input       word_t        bus_read_data_i,   // read data
        output wire logic         bus_read_enable_o, // read enable
        output wire word_t        bus_write_data_o,  // write data
        output wire logic [3:0]   bus_write_mask_o   // write mask
    );


//
// CPU
//

wire word_t bus_addr;
assign      bus_addr_o = bus_addr;

cpu cpu (
    .clk_i              (clk_i),
    .interrupt_i        (interrupt_i),
    .halt_o             (halt_o),
    .imem_addr_o        (imem_addr_o),
    .imem_data_i        (imem_data_i),
    .dmem_addr_o        (bus_addr),
    .dmem_read_data_i   (bus_read_data_i),
    .dmem_read_enable_o (bus_read_enable_o),
    .dmem_write_data_o  (bus_write_data_o),
    .dmem_write_mask_o  (bus_write_mask_o)
);


//
// Chip Select
//

// FFFF0000 - R   - Interrupt Controller Pending
// FFFF0004 - R/W - Interrupt Controller Enabled
// FFFF0008 - R   - Interrupt Controller Active
// FFFF0100 - R/W - UART Config  { baud, parity, etc. }
// FFFF0104 - R   - UART Status  { tx fifo status, rx fifo status, break indicator }
// FFFF0108 - R   - UART Rx Data { data available, data }
// FFFF010C - W   - UART Tx Data { data }
// FFFF0200 - R/W - Seven Segment Display Control { enabled }
// FFFF0204 - R/W - Seven Segment Display Value
// FFFF0300 - R   - Switches
// FFFF0400 - R   - PS/2 Keyboard Status  { data available, make/break, keycode }
// FFFF0404 - W   - PS/2 Keyboard Control { caps, num, scroll }
// FFFF0500 - W   - VGA Font Select

always_comb begin
    bus_chip_select_o = '{ default: '0 };
    unique casez (bus_addr)
    32'h0???????: bus_chip_select_o.bios     = '1;
    32'h1???????: bus_chip_select_o.ram      = '1;
    32'h2???????: bus_chip_select_o.vram     = '1;
    32'hFFFF00??: bus_chip_select_o.irq      = '1;
    32'hFFFF01??: bus_chip_select_o.uart     = '1;
    32'hFFFF02??: bus_chip_select_o.display  = '1;
    32'hFFFF03??: bus_chip_select_o.switches = '1;
    32'hFFFF04??: bus_chip_select_o.keyboard = '1;
    32'hFFFF05??: bus_chip_select_o.vga      = '1;
    default: ;
    endcase
end

endmodule
