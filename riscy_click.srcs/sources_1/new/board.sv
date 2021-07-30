`timescale 1ns / 1ps
`default_nettype none

///
/// Board
///

module board
    // Import Constants
    import common::*;
    (
        input  wire logic clk_sys,             // 100MHz system clock
        input  wire logic ia_rst,              // reset (async)
        output wire logic oa_halt,             // halt

        // I/O
        output wire logic [ 7:0] oc_segment_a, // seven segment display anodes
        output wire logic [ 7:0] oc_segment_c, // seven segment display cathodes
        input  wire logic [15:0] ia_switch     // hardware switch bank (async)
    );


//
// Clocks
//

wire logic clk_cpu;
wire logic a_clk_ready;

cpu_clk_gen cpu_clk_gen (
    .clk_sys(clk_sys),
    .ia_rst(1'b0),
    .clk_cpu(clk_cpu),
    .oa_ready(a_clk_ready)
);


//
// Clocked Resets
//

localparam integer RESET_CYCLES = 12;
const logic [RESET_CYCLES-1:0] RESET_ONES = {RESET_CYCLES{1'b1}};

logic c_cpu_rst;
logic [RESET_CYCLES-1:0] c_cpu_rst_chain;

always_ff @(posedge clk_cpu, posedge ia_rst) begin
    if (ia_rst)
        // if resetting, fill the chain with ones
        { c_cpu_rst, c_cpu_rst_chain } <= { 1'b1, RESET_ONES };
    else
        // otherwise, start shifting out the ones
        { c_cpu_rst, c_cpu_rst_chain } <= { c_cpu_rst_chain, 1'b0 };
end


//
// Clock in Switch States
//

logic [15:0] c_cpu_switch;

always_ff @(posedge clk_cpu) begin
    c_cpu_switch <= ia_switch;
end


//
// Memory Signals
//

// Instruction Memory
wire word_t a_imem_addr;
wire word_t a_imem_data;

// Data Memory
wire word_t      a_dmem_addr;
     word_t      a_dmem_rddata;
wire word_t      a_dmem_wrdata;
wire logic [3:0] a_dmem_wrmask;

// Write Masks
logic [3:0] a_dsp_wrmask;
logic [3:0] a_ram_wrmask;

// Device
wire word_t a_dsp_rddata;
wire word_t a_bios_rddata;
wire word_t a_ram_rddata;


//
// Devices
//

// BIOS
block_rom #(.CONTENTS("bios.mem")) rom (
    .clk(clk_cpu),
    .ic_rst(c_cpu_rst),
    .ic_ra_addr(a_imem_addr),
    .oa_ra_data(a_imem_data),
    .ic_rb_addr(a_dmem_addr),
    .oa_rb_data(a_bios_rddata)
);

// RAM
block_ram ram (
    .clk(clk_cpu),
    .ic_rst(c_cpu_rst),
    .ic_rw_addr(a_dmem_addr),
    .ic_rw_wrdata(a_dmem_wrdata),
    .ic_rw_wrmask(a_ram_wrmask),
    .oa_rw_rddata(a_ram_rddata)
);

// Display
segdisplay #(.CLK_DIVISOR(50000)) disp (
    .clk(clk_cpu),
    .ic_rst(c_cpu_rst),
    .oc_dsp_a(oc_segment_a),
    .oc_dsp_c(oc_segment_c),
    .oc_rd_data(a_dsp_rddata),
    .ic_wr_data(a_dmem_wrdata),
    .ic_wr_mask(a_dsp_wrmask)
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
word_t c_dmem_return_addr;

always_ff @(posedge clk_cpu) begin
    c_dmem_return_addr <= c_cpu_rst ? 32'h00000000 : a_dmem_addr;
end

always_comb begin
    casez (a_dmem_addr)
    32'h0???????: begin a_ram_wrmask <= 4'b0000;       a_dsp_wrmask <= 4'b0000;       end
    32'h1???????: begin a_ram_wrmask <= a_dmem_wrmask; a_dsp_wrmask <= 4'b0000;       end
    32'hFF000000: begin a_ram_wrmask <= 4'b0000;       a_dsp_wrmask <= a_dmem_wrmask; end
    32'hFF000004: begin a_ram_wrmask <= 4'b0000;       a_dsp_wrmask <= 4'b0000;       end
    default:      begin a_ram_wrmask <= 4'b0000;       a_dsp_wrmask <= 4'b0000;       end
    endcase
    
    casez (c_dmem_return_addr)
    32'h0???????: begin a_dmem_rddata <= a_bios_rddata;            end
    32'h1???????: begin a_dmem_rddata <= a_ram_rddata;             end
    32'hFF000000: begin a_dmem_rddata <= a_dsp_rddata;             end
    32'hFF000004: begin a_dmem_rddata <= { 16'h00, c_cpu_switch }; end
    default:      begin a_dmem_rddata <= 32'h00000000;             end
    endcase
end


//
// CPU
//

cpu cpu (
    .clk(clk_cpu),
    .ic_rst(c_cpu_rst),
    .oa_halt(oa_halt),
    .oa_imem_addr(a_imem_addr),
    .ia_imem_data(a_imem_data),
    .oa_dmem_addr(a_dmem_addr),
    .ia_dmem_rddata(a_dmem_rddata),
    .oa_dmem_wrdata(a_dmem_wrdata),
    .oa_dmem_wrmask(a_dmem_wrmask)
);

//
// Debug Counter
//

(* KEEP = "TRUE" *) word_t c_cycle_counter;

always_ff @(posedge clk_cpu) begin
    c_cycle_counter <= c_cpu_rst ? 32'h00000000 : (c_cycle_counter + 1);
end

endmodule
