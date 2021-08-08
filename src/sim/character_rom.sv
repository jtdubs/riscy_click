`timescale 1ns / 1ps
`default_nettype none

module character_rom
    // Import Constants
    import common::*;
    #(
        CONTENTS = ""
    )
    (
        input  wire logic        clk_i,
        input  wire logic        reset_i,

        // port
        input  wire logic [11:0] addr_i,
        output wire logic [31:0] data_o
    );

logic [31:0] rom [0:4095];

initial begin
    $readmemh(CONTENTS, rom);
end

always_ff @(posedge clk_i) begin
    data_o <= reset_i ? 32'b0 : rom[addr_i];
end

endmodule
