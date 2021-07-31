`timescale 1ns / 1ps
`default_nettype none

///
/// Board
///

module board
    // Import Constants
    import common::*;
    (
        input  wire logic clk_sys_i,            // 100MHz system clock
        input  wire logic reset_async_i,        // reset (async)
        output wire logic halt_o,               // halt

        // I/O
        output wire logic [ 7:0] dsp_anode_o,   // seven segment display anodes
        output wire logic [ 7:0] dsp_cathode_o, // seven segment display cathodes
        input  wire logic [15:0] switch_async_i // hardware switch bank (async)
    );


//
// Clocks
//

wire logic clk_cpu_w;
wire logic ready_async_w;

cpu_clk_gen cpu_clk_gen (
    .clk_sys_i(clk_sys_i),
    .reset_async_i(1'b0),
    .clk_cpu_o(clk_cpu_w),
    .ready_async_o(ready_async_w)
);


//
// Clocked Resets
//

localparam integer RESET_CYCLES = 12;
const logic [RESET_CYCLES-1:0] RESET_ONES = {RESET_CYCLES{1'b1}};

logic cpu_rst_r;
logic [RESET_CYCLES-1:0] cpu_rst_chain_r;

always_ff @(posedge clk_cpu_w, posedge reset_async_i) begin
    if (reset_async_i)
        // if resetting, fill the chain with ones
        { cpu_rst_r, cpu_rst_chain_r } <= { 1'b1, RESET_ONES };
    else
        // otherwise, start shifting out the ones
        { cpu_rst_r, cpu_rst_chain_r } <= { cpu_rst_chain_r, 1'b0 };
end


//
// Clock in Switch States
//

logic [15:0] switch_r;

always_ff @(posedge clk_cpu_w) begin
    switch_r <= switch_async_i;
end


//
// Memory Signals
//

// Instruction Memory
wire word_t imem_addr_w;
wire word_t imem_data_w;

// Data Memory
wire word_t      dmem_addr_w;
     word_t      dmem_read_data_w;
wire word_t      dmem_write_data_w;
wire logic [3:0] dmem_write_mask_w;

// Write Masks
logic [3:0] dsp_write_mask_w;
logic [3:0] ram_write_mask_w;

// Device
wire word_t dsp_read_data_w;
wire word_t bios_read_data_w;
wire word_t ram_read_data_w;


//
// Devices
//

// BIOS
block_rom #(.CONTENTS("bios.mem")) rom (
    .clk_i(clk_cpu_w),
    .reset_i(1'b0),
    .read1_addr_i(imem_addr_w),
    .read1_data_o(imem_data_w),
    .read2_addr_i(dmem_addr_w),
    .read2_data_o(bios_read_data_w)
);

// RAM
block_ram ram (
    .clk_i(clk_cpu_w),
    .reset_i(1'b0),
    .addr_i(dmem_addr_w),
    .write_data_i(dmem_write_data_w),
    .write_mask_i(ram_write_mask_w),
    .read_data_o(ram_read_data_w)
);

// Display
segdisplay #(.CLK_DIVISOR(50000)) disp (
    .clk_i(clk_cpu_w),
    .reset_i(cpu_rst_r),
    .dsp_anode_o(dsp_anode_o),
    .dsp_cathode_o(dsp_cathode_o),
    .read_data_o(dsp_read_data_w),
    .write_data_i(dmem_write_data_w),
    .write_mask_i(dsp_write_mask_w)
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
word_t dmem_read_addr_r;

always_ff @(posedge clk_cpu_w) begin
    dmem_read_addr_r <= cpu_rst_r ? 32'h00000000 : dmem_addr_w;
end

always_comb begin
    casez (dmem_addr_w)
    32'h0???????: begin ram_write_mask_w <= 4'b0000;       dsp_write_mask_w <= 4'b0000;           end
    32'h1???????: begin ram_write_mask_w <= dmem_write_mask_w; dsp_write_mask_w <= 4'b0000;       end
    32'hFF000000: begin ram_write_mask_w <= 4'b0000;       dsp_write_mask_w <= dmem_write_mask_w; end
    32'hFF000004: begin ram_write_mask_w <= 4'b0000;       dsp_write_mask_w <= 4'b0000;           end
    default:      begin ram_write_mask_w <= 4'b0000;       dsp_write_mask_w <= 4'b0000;           end
    endcase
    
    casez (dmem_read_addr_r)
    32'h0???????: begin dmem_read_data_w <= bios_read_data_w;     end
    32'h1???????: begin dmem_read_data_w <= ram_read_data_w;      end
    32'hFF000000: begin dmem_read_data_w <= dsp_read_data_w;      end
    32'hFF000004: begin dmem_read_data_w <= { 16'h00, switch_r }; end
    default:      begin dmem_read_data_w <= 32'h00000000;         end
    endcase
end


//
// CPU
//

cpu cpu (
    .clk_i(clk_cpu_w),
    .reset_i(cpu_rst_r),
    .halt_o(halt_o),
    .imem_addr_o(imem_addr_w),
    .imem_data_i(imem_data_w),
    .dmem_addr_o(dmem_addr_w),
    .dmem_read_data_i(dmem_read_data_w),
    .dmem_write_data_o(dmem_write_data_w),
    .dmem_write_mask_o(dmem_write_mask_w)
);

//
// Debug Counter
//

(* KEEP = "TRUE" *) word_t cycle_counter_r;

always_ff @(posedge clk_cpu_w) begin
    cycle_counter_r <= cpu_rst_r ? 32'h00000000 : (cycle_counter_r + 1);
end

endmodule
