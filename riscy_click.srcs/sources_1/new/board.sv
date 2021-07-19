`timescale 1ns/1ps

///
/// Board
///

module board
    // Import Constants
    import consts::*;
    (
        input       logic clk,   // clock
        (* mark_debug = "true" *) input       logic reset, // reset
        (* mark_debug = "true" *) output wire logic halt,  // halt

        // I/O
        output wire logic [7:0] segment_a,
        output wire logic [7:0] segment_c,
        input       logic [15:0] switch
    );


//
// Instruction Memory Bus (BIOS)
//

// Signals
wire word ibus_addr;
wire word ibus_read_data;

// Component
bios_rom bios (
    .a(ibus_addr[9:2]),
    .spo(ibus_read_data)
);


//
// Data Memory Bus
//

// Signals
(* mark_debug = "true" *) wire word   dbus_addr;
(* mark_debug = "true" *) word        dbus_read_data;
(* mark_debug = "true" *) word        dbus_write_data;
(* mark_debug = "true" *) logic [3:0] dbus_write_mask;
(* mark_debug = "true" *) logic       dbus_write_enable;
logic ram_write_enable;
logic dsp_write_enable;
wire word ram_read_data;
wire word dsp_read_data;
wire word bios_read_data;

// Components
data_ram dram (
    .clk(clk),
    .a(dbus_addr[8:2]),
    .d(dbus_write_data),
    .we(ram_write_enable),
    .spo(ram_read_data)
//    .write_mask(dbus_write_mask),
);

segdisplay #(.CLK_DIVISOR(1000)) disp (
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

bios_rom bios_copy (
    .a(dbus_addr[9:2]),
    .spo(bios_read_data)
);

// Chip Select (ish)
always_comb
begin
    casez (dbus_addr)
    32'h0???????: begin ram_write_enable <= 1'b0;              dsp_write_enable <= 1'b0;              dbus_read_data <= bios_read_data;     end
    32'h1???????: begin ram_write_enable <= dbus_write_enable; dsp_write_enable <= 1'b0;              dbus_read_data <= ram_read_data;      end
    32'hFF000000: begin ram_write_enable <= 1'b0;              dsp_write_enable <= dbus_write_enable; dbus_read_data <= dsp_read_data;      end
    32'hFF000004: begin ram_write_enable <= 1'b0;              dsp_write_enable <= 1'b0;              dbus_read_data <= { 16'h00, switch }; end
    default:      begin ram_write_enable <= 1'b0;              dsp_write_enable <= 1'b0;              dbus_read_data <= 32'h00000000;       end
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
