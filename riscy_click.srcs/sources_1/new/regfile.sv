`timescale 1ns / 1ps
`default_nettype none

///
/// Register File (32 x 32-bit)
///
/// Specs:
/// 2-port async read
/// 1-port sync write
///

module regfile
    // Import Constants
    import common::*;
    (
        input  wire logic       clk,          // Clock

        // read port 1
        input  wire logic [4:0] read_addr1,   // Read Address #1
        output      word_t      read_data1,   // Data Output #1

        // read port 2
        input  wire logic [4:0] read_addr2,   // Read Address #2
        output      word_t      read_data2,   // Data Output #2

        // write port
        input  wire logic       write_enable, // Write Enable
        input  wire logic [4:0] write_addr,   // Write Address
        input  wire word_t      write_data    // Write Data
    );

// Memory
word_t mem [31:0];

// Initialize with Zeroes
integer i;
initial begin
    for (i=0; i<32; i=i+1) begin
        mem[i] = 32'b0;
    end
end

// Reading Logic
always_comb begin
    read_data1 = read_addr1 == 5'b0 ? 32'b0 : mem[read_addr1];
    read_data2 = read_addr2 == 5'b0 ? 32'b0 : mem[read_addr2];
end

// Clocked Writing
always_ff @(posedge clk) begin
    if (write_enable && write_addr != 5'b00000) begin
        mem[write_addr] <= write_data;
    end
end

endmodule
