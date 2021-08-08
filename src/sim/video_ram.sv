`timescale 1ns / 1ps
`default_nettype none

module video_ram
    // Import Constants
    import common::*;
    #(
        CONTENTS = "none"
    )
    (
        // cpu interface
        input  wire logic        clk_cpu_i,
        input  wire logic        cpu_reset_i,
        input  wire word_t       cpu_addr_i,
        input  wire word_t       cpu_write_data_i,
        input  wire logic [ 3:0] cpu_write_mask_i,
        output wire word_t       cpu_read_data_o,

        // vga controller interface
        input  wire logic        clk_pxl_i,
        input  wire logic        pxl_reset_i,
        input  wire logic [11:0] pxl_addr_i,
        output wire logic [ 7:0] pxl_data_o
    );

logic [7:0] ram [0:4095];

integer i;
initial begin
    for (i=0; i<4096; i++) begin
        ram[i] = 8'b0;
    end
end

always_ff @(posedge clk_cpu_i) begin
    cpu_read_data_o <= cpu_reset_i ? 32'b0 : { ram[cpu_addr_i+3], ram[cpu_addr_i+2], ram[cpu_addr_i+1], ram[cpu_addr_i+0] };

    if (cpu_write_mask_i[0]) ram[cpu_addr_i+0] <= cpu_write_data_i[ 7: 0];
    if (cpu_write_mask_i[1]) ram[cpu_addr_i+1] <= cpu_write_data_i[15: 8];
    if (cpu_write_mask_i[2]) ram[cpu_addr_i+2] <= cpu_write_data_i[23:16];
    if (cpu_write_mask_i[3]) ram[cpu_addr_i+3] <= cpu_write_data_i[31:24];
end

always_ff @(posedge clk_pxl_i) begin
    pxl_data_o <= pxl_reset_i ? 8'b0 : ram[pxl_addr_i];
end

endmodule
