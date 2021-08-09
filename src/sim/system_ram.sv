`timescale 1ns / 1ps
`default_nettype none

module system_ram
    // Import Constants
    import common::*;
    (
        input  wire logic       clk_i,
        input  wire logic       reset_i,

        // read/write port
        input  wire word_t      addr_i,
        input  wire word_t      write_data_i,
        input  wire logic [3:0] write_mask_i,
        output      word_t      read_data_o
    );

logic [31:0] ram [0:1023];

integer i;
initial begin
    for (i=0; i<1024; i++) begin
        ram[i] = 32'b0;
    end
end

always_ff @(posedge clk_i) begin
    read_data_o <= reset_i ? 32'b0 : ram[addr_i[11:2]];

    if (write_mask_i[0]) ram[addr_i[11:2]][ 7: 0] <= write_data_i[ 7: 0];
    if (write_mask_i[1]) ram[addr_i[11:2]][15: 8] <= write_data_i[15: 8];
    if (write_mask_i[2]) ram[addr_i[11:2]][23:16] <= write_data_i[23:16];
    if (write_mask_i[3]) ram[addr_i[11:2]][31:24] <= write_data_i[31:24];
end

endmodule
