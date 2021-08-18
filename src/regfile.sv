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
    import cpu_common::*;
    (
        input  wire logic     clk_i,              // Clock

        // read port A
        input  wire regaddr_t read1_addr_i,       // Read Address
        output      word_t    read1_data_async_o, // Data Output

        // read port B
        input  wire regaddr_t read2_addr_i,       // Read Address
        output      word_t    read2_data_async_o, // Data Output

        // write port
        input  wire logic     write_enable_i,     // Write Enable
        input  wire regaddr_t write_addr_i,       // Write Address
        input  wire word_t    write_data_i        // Write Data
    );

// Memory
word_t mem_r [31:0] = '{ default: '0 };

// Read Ports
always_comb begin
    read1_data_async_o = mem_r[read1_addr_i];
    read2_data_async_o = mem_r[read2_addr_i];
end

// Write Port
always_ff @(posedge clk_i) begin
    if (write_enable_i && write_addr_i != 5'b00000) begin
        mem_r[write_addr_i] <= write_data_i;
    end
end

endmodule
