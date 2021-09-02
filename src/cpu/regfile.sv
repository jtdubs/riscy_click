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
        input  wire regaddr_t ra_addr_i,       // Read Address
        output      word_t    ra_data_async_o, // Data Output

        // read port B
        input  wire regaddr_t rb_addr_i,       // Read Address
        output      word_t    rb_data_async_o, // Data Output

        // write port
        input  wire logic     wr_enable_i,     // Write Enable
        input  wire regaddr_t wr_addr_i,       // Write Address
        input  wire word_t    wr_data_i        // Write Data
    );

// Memory
word_t mem_r [31:0] = '{ default: '0 };

// Read Ports
always_comb begin
    ra_data_async_o = mem_r[ra_addr_i];
    rb_data_async_o = mem_r[rb_addr_i];
end

// Write Port
always_ff @(posedge clk_i) begin
    if (wr_enable_i && wr_addr_i != 5'b00000) begin
        mem_r[wr_addr_i] <= wr_data_i;
    end
end

endmodule
