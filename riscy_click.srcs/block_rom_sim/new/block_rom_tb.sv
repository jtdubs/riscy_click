`timescale 1ns / 1ps

module block_rom_tb ();

logic clk, reset;
logic [31:0] addr, data;

block_rom #(.CONTENTS("d:/dev/riscy_click/bios/tb_bios.coe")) rom (
    .clk(clk),
    .reset(reset),
    .addr(addr),
    .data(data)
);

// clock generator
initial begin
    clk = 1;
    forever begin
        #50 clk <= ~clk;
    end
end

// reset pulse (2 cycle)
initial begin
    reset = 1;
    #150 reset = 0;
end

// input side
logic [31:0] next_addr;
assign next_addr = reset ? 0 : addr + 4;

always_ff @(negedge clk) begin
    addr <= next_addr;
end

endmodule
