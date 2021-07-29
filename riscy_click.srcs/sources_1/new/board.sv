`timescale 1ns / 1ps
`default_nettype none

///
/// Board
///

module board
    // Import Constants
    import common::*;
    (
        input  wire logic sys_clk,            // 100MHz system clock
        input  wire logic reset_async,        // reset (async)
        output wire logic halt,               // halt

        // I/O
        output wire logic [ 7:0] segment_a,   // seven segment display anodes
        output wire logic [ 7:0] segment_c,   // seven segment display cathodes
        input  wire logic [15:0] switch_async // hardware switch bank (async)
    );


//
// Clocks
//

wire logic cpu_clk;
wire logic cpu_clk_ready;

cpu_clk_gen cpu_clk_gen (
    .sys_clk(sys_clk),
    .reset(1'b0),
    .cpu_clk(cpu_clk),
    .cpu_clk_ready(cpu_clk_ready)
);


//
// Clocked Resets
//

localparam integer RESET_CYCLES = 12;
const logic [RESET_CYCLES-1:0] RESET_ONES = {RESET_CYCLES{1'b1}};

logic cpu_reset;
logic [RESET_CYCLES-1:0] cpu_reset_chain;

always_ff @(posedge cpu_clk, posedge reset_async) begin
    if (reset_async)
        // if resetting, fill the chain with ones
        { cpu_reset, cpu_reset_chain } <= { 1'b1, RESET_ONES };
    else
        // otherwise, start shifting out the ones
        { cpu_reset, cpu_reset_chain } <= { cpu_reset_chain, 1'b0 };
end


//
// Clock in Switch States
//

logic [15:0] cpu_switch;

always_ff @(posedge cpu_clk) begin
    cpu_switch <= switch_async;
end


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
block_rom #(.CONTENTS("bios.mem")) rom (
    .clk(cpu_clk),
    .reset(cpu_reset),
    .addr_a(imem_addr),
    .data_a(imem_data),
    .addr_b(dmem_addr),
    .data_b(bios_read_data)
);

// RAM
block_ram ram (
    .clk(cpu_clk),
    .reset(cpu_reset),
    .addr(dmem_addr),
    .read_data(ram_read_data),
    .write_data(dmem_write_data),
    .write_mask(ram_write_mask)
);

// Display
segdisplay #(.CLK_DIVISOR(50000)) disp (
    .clk(cpu_clk),
    .reset(cpu_reset),
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

always_ff @(posedge cpu_clk) begin
    dmem_return_addr <= cpu_reset ? 32'h00000000 : dmem_addr;
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
    32'h0???????: begin dmem_read_data <= bios_read_data;         end
    32'h1???????: begin dmem_read_data <= ram_read_data;          end
    32'hFF000000: begin dmem_read_data <= dsp_read_data;          end
    32'hFF000004: begin dmem_read_data <= { 16'h00, cpu_switch }; end
    default:      begin dmem_read_data <= 32'h00000000;           end
    endcase
end


//
// CPU
//

cpu cpu (
    .clk(cpu_clk),
    .reset(cpu_reset),
    .halt(halt),
    .imem_addr(imem_addr),
    .imem_data(imem_data),
    .dmem_addr(dmem_addr),
    .dmem_read_data(dmem_read_data),
    .dmem_write_data(dmem_write_data),
    .dmem_write_mask(dmem_write_mask)
);

//
// Debug Counter
//

(* KEEP = "TRUE" *) word_t cycle_counter;

always_ff @(posedge cpu_clk) begin
    cycle_counter <= cpu_reset ? 32'h00000000 : cycle_counter + 1;
end

endmodule
