`timescale 1ns/1ps

///
/// Register File (32 x 32-bit)
///
/// Specs:
/// 2-port async read
/// 1-port sync write
///

module regfile
    // Import Constants
    import consts::*;
    (
        input       logic       clk,          // Clock

        // read port 1
        input       logic [4:0] read_addr1,   // Read Address #1
        output wire word        read_data1,   // Data Output #1

        // read port 2
        input       logic [4:0] read_addr2,   // Read Address #2
        output wire word        read_data2,   // Data Output #2

        // write port
        input       logic       write_enable, // Write Enable
        input       logic [4:0] write_addr,   // Write Address
        input       word        write_data    // Write Data
    );

// Memory
word mem [31:0];

// Initialize with Zeroes
integer i;
initial begin
    for (i=0; i<32; i=i+1) begin
        mem[i] <= 32'b0;
    end
end

// Reading Logic
assign read_data1 = read_addr1 == 5'b0 ? 32'b0 : mem[read_addr1];
assign read_data2 = read_addr2 == 5'b0 ? 32'b0 : mem[read_addr2];

// Clocked Writing
always_ff @(posedge clk)
begin
    if (write_enable && write_addr != 5'b0)
    begin
        mem[write_addr] <= write_data;
    end
end

endmodule