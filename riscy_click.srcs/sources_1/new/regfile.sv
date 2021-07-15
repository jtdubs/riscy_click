`timescale 1ns/1ps

///
/// Register File (32 x 32-bit)
///
/// Specs:
/// 2-port async read
/// 1-port sync write
///

module regfile
    (
        input         clk,          // Clock

        // read port 1
        input  [ 4:0] read_addr1,   // Read Address #1
        output [31:0] read_data1,   // Data Output #1

        // read port 2
        input  [ 4:0] read_addr2,   // Read Address #2
        output [31:0] read_data2,   // Data Output #2

        // write port
        input         write_enable, // Write Enable
        input  [ 4:0] write_addr,   // Write Address
        input  [31:0] write_data    // Write Data
    );

// Memory
reg [31:0] mem [31:0];

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
always @(posedge clk)
begin
    if (write_enable && write_addr != 5'b0)
    begin
        mem[write_addr] <= write_data;
    end
end

endmodule