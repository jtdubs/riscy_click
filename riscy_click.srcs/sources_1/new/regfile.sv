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
        input  wire logic     clk_i,              // Clock

        // read port A
        input  wire regaddr_t read1_addr_async_i, // Read Address
        output      word_t    read1_data_async_o, // Data Output

        // read port B
        input  wire regaddr_t read2_addr_async_i, // Read Address
        output      word_t    read2_data_async_o, // Data Output

        // write port
        input  wire logic     write_enable_i,     // Write Enable
        input  wire regaddr_t write_addr_i,       // Write Address
        input  wire word_t    write_data_i        // Write Data
    );

// Memory
word_t lc_mem [31:0];

// Initialize with Zeroes
integer i;
initial begin
    for (i=0; i<32; i=i+1) begin
        lc_mem[i] = 32'b0;
    end
end

// Read Ports
always_comb begin
    read1_data_async_o = lc_mem[read1_addr_async_i];
    read2_data_async_o = lc_mem[read2_addr_async_i];
end

// Write Port
always_ff @(posedge clk_i) begin
    if (write_enable_i && write_addr_i != 5'b00000) begin
        lc_mem[write_addr_i] <= write_data_i;
    end
end

endmodule
