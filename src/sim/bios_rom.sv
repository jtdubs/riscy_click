`timescale 1ns / 1ps
`default_nettype none

module bios_rom
    // Import Constants
    import common::*;
    #(
        CONTENTS = ""
    )
    (
        input  wire logic  clk_i,
        input  wire logic  reset_i,

        // read port a
        input  wire word_t read1_addr_i,
        output      word_t read1_data_o,

        // read port b
        input  wire word_t read2_addr_i,
        output      word_t read2_data_o
    );

logic [31:0] rom [0:1023];

initial begin
    $readmemh(CONTENTS, rom);
end

always_ff @(posedge clk_i) begin
    read1_data_o <= reset_i ? 32'b0 : rom[read1_addr_i[11:2]];
    read2_data_o <= reset_i ? 32'b0 : rom[read2_addr_i[11:2]];
end

endmodule
