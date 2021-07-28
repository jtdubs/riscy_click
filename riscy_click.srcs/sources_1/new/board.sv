`timescale 1ns / 1ps
`default_nettype none

///
/// Board
///

module board
    // Import Constants
    import common::*;
    (
        input  wire logic clk,   // clock
        input  wire logic reset, // reset
        output wire logic halt,  // halt

        // I/O
        output wire logic [ 7:0] segment_a, // seven segment display anodes
        output wire logic [ 7:0] segment_c, // seven segment display cathodes
        input  wire logic [15:0] switch     // hardware switch bank
    );


//
// Memory Signals
//

// Instruction Memory
wire word_t imem_addr;
wire word_t imem_data;

// Data Memory
wire word_t      dmem_addr;
     word_t      dmem_read_data;
wire word_t      dmem_write_data;
wire logic [3:0] dmem_write_mask;

// Write Masks
logic [3:0] dsp_write_mask;
logic [3:0] ram_write_mask;

// Device
wire word_t dsp_read_data;
wire word_t bios_read_data;
wire word_t ram_read_data;


//
// Devices
//

// BIOS
block_rom #(.CONTENTS("d:/dev/riscy_click/bios/bios.coe")) rom (
    .clk(clk),
    .reset(reset),
    .addr_a(imem_addr),
    .data_a(imem_data),
    .addr_b(dmem_addr),
    .data_b(bios_read_data)
);

// RAM
block_ram ram (
    .clk(clk),
    .reset(reset),
    .addr(dmem_addr),
    .read_data(ram_read_data),
    .write_data(dmem_write_data),
    .write_mask(ram_write_mask)
);

// Display
segdisplay #(.CLK_DIVISOR(10000)) disp (
    .clk(clk),
    .reset(reset),
    .a(segment_a),
    .c(segment_c),
    .addr(dmem_addr),
    .read_data(dsp_read_data),
    .write_data(dmem_write_data),
    .write_mask(dsp_write_mask)
);


//
// Address decoding
//
// Memory map:
// 00000000 - 0FFFFFFF: BIOS
// 10000000 - 1FFFFFFF: RAM
// 20000000 - FEFFFFFF: UNMAPPED
// FF000000:            Seven Segment Display
// FF000004:            Switch Bank
//
word_t dmem_return_addr;

always_ff @(posedge clk) begin
    dmem_return_addr <= reset ? 32'h00000000 : dmem_addr;
end

always_comb begin
    casez (dmem_addr)
    32'h0???????: begin ram_write_mask <= 4'b0000;         dsp_write_mask <= 4'b0000;         end
    32'h1???????: begin ram_write_mask <= dmem_write_mask; dsp_write_mask <= 4'b0000;         end
    32'hFF000000: begin ram_write_mask <= 4'b0000;         dsp_write_mask <= dmem_write_mask; end
    32'hFF000004: begin ram_write_mask <= 4'b0000;         dsp_write_mask <= 4'b0000;         end
    default:      begin ram_write_mask <= 4'b0000;         dsp_write_mask <= 4'b0000;         end
    endcase
    
    casez (dmem_return_addr)
    32'h0???????: begin dmem_read_data <= bios_read_data;     end
    32'h1???????: begin dmem_read_data <= ram_read_data;      end
    32'hFF000000: begin dmem_read_data <= dsp_read_data;      end
    32'hFF000004: begin dmem_read_data <= { 16'h00, switch }; end
    default:      begin dmem_read_data <= 32'h00000000;       end
    endcase
end


//
// CPU
//

cpu cpu (.*);


//
// Debug Counter
//

word_t cycle_counter;

always_ff @(posedge clk) begin
    cycle_counter <= reset ? 32'h00000000 : cycle_counter + 1;
end

endmodule
