`timescale 1ns/1ps

///
/// RAM
///
/// Specs:
/// - 32-bit word size
/// - byte-addressed
/// - word-aligned reads/writes only
/// - supports masked writes
/// - single-cycle reads/writes
/// - uses a 2^14 word sized backing store (wraps)
///

module ram
    #(
        parameter MEMORY_IMAGE_FILE = ""    // Hex image from which to initialize memory
    )
    (
        input         clk,                  // Clock
        input  [31:2] addr,                 // Address (high 30 bits of address, as only word-aligned access is supported)
        output [31:0] read_data,            // Read Data
        input         write_enable,         // Write Enable
        input  [ 3:0] write_mask,           // Write Mask
        input  [31:0] write_data            // Write Data
    );

// addr mod 2^14 (size of backing store)
wire [13:0] addr_mod = addr[15:2];

// Memory
reg [31:0] mem [16383:0];

// Initialize from memory image, if requested
initial if (MEMORY_IMAGE_FILE) $readmemh(MEMORY_IMAGE_FILE, mem, 0, 16383);

// Reading Logic
assign read_data = mem[addr_mod];

// Clocked Writing
always @(posedge clk)
begin
    if (write_enable)
    begin
        // Only write bytes where mask is set
        if (write_mask[3]) mem[addr_mod][31:24] <= write_data[31:24];
        if (write_mask[2]) mem[addr_mod][23:16] <= write_data[23:16];
        if (write_mask[1]) mem[addr_mod][15: 8] <= write_data[15: 8];
        if (write_mask[0]) mem[addr_mod][ 7: 0] <= write_data[ 7: 0];
    end
end

endmodule