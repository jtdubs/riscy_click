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

        // read port A
        input  wire logic [4:0] ia_ra_addr,   // Read Address
        output      word_t      oa_ra_data,   // Data Output

        // read port B
        input  wire logic [4:0] ia_rb_addr,   // Read Address
        output      word_t      oa_rb_data,   // Data Output

        // write port
        input  wire logic       ic_wr_en,     // Write Enable
        input  wire logic [4:0] ic_wr_addr,   // Write Address
        input  wire word_t      ic_wr_data    // Write Data
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
    oa_ra_data = lc_mem[ia_ra_addr];
    oa_rb_data = lc_mem[ia_rb_addr];
end

// Write Port
always_ff @(posedge clk) begin
    if (ic_wr_en && ic_wr_addr != 5'b00000) begin
        lc_mem[ic_wr_addr] <= ic_wr_data;
    end
end

endmodule
