`timescale 1ns/1ps

///
/// Board
///

module board
    // Import Constants
    import consts::*;
    (
        input       logic clk,   // clock
        input       logic reset, // reset
        output wire logic halt,  // halt
        
        // I/O
        output wire logic [7:0] segment_a,
        output wire logic [7:0] segment_c
        // input       logic [7:0] switches,
    );

    
//
// Instruction Memory Bus (BIOS)
//

// Signals
wire word ibus_addr;
wire word ibus_read_data;

// Component
ram #(.MEMORY_IMAGE_FILE("iram.mem")) bios (
    .addr(ibus_addr[31:2]),
    .read_data(ibus_read_data),
    .write_data(32'b0),
    .write_mask(4'b1111),
    .write_enable(1'b0),
    .clk(clk)
);


//
// Data Memory Bus
//

// Signals
wire word   dbus_addr;
word   dbus_read_data;
word        dbus_write_data;
logic [3:0] dbus_write_mask;
logic       dbus_write_enable;
logic ram_write_enable;
logic dsp_write_enable;
wire word ram_read_data;
wire word dsp_read_data;

// Components
ram #(.MEMORY_IMAGE_FILE("dram.mem")) dram (
    .addr(dbus_addr[31:2]),
    .read_data(ram_read_data),
    .write_data(dbus_write_data),
    .write_mask(dbus_write_mask),
    .write_enable(ram_write_enable),
    .clk(clk)
);

segdisplay #(.CLK_DIVISOR(10000)) disp (
    .clk(clk),
    .reset(reset),
    .a(segment_a),
    .c(segment_c),
    .addr(dbus_addr),
    .read_data(dsp_read_data),
    .write_data(dbus_write_data),
    .write_enable(dsp_write_enable),
    .write_mask(dbus_write_mask)
);

// Chip Select (ish)
always_comb
begin
    case (dbus_addr)
    32'hFF000000: begin ram_write_enable <= 1'b0;              dsp_write_enable <= dbus_write_enable; dbus_read_data <= dsp_read_data; end
    default:      begin ram_write_enable <= dbus_write_enable; dsp_write_enable <= 1'b0;              dbus_read_data <= ram_read_data; end
    endcase
end


//
// CPU
//

cpu cpu (
    .clk(clk),
    .reset(reset),
    .halt(halt),
    .ibus_addr(ibus_addr),
    .ibus_read_data(ibus_read_data),
    .dbus_addr(dbus_addr),
    .dbus_read_data(dbus_read_data),
    .dbus_write_data(dbus_write_data),
    .dbus_write_mask(dbus_write_mask),
    .dbus_write_enable(dbus_write_enable)
);

endmodule