`timescale 1ns / 1ps
`default_nettype none

module block_rom_tb ();

logic clk, reset;
logic [31:0] addr_a, addr_b, data_a, data_b;

block_rom #(.CONTENTS("d:/dev/riscy_click/bios/tb_bios.coe")) rom (.*);

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
    #200 @(negedge clk) reset = 0;
end

// input side
logic [31:0] next_addr_a, next_addr_b;
assign next_addr_a = reset ? 0 : addr_a + 4;
assign next_addr_b = reset ? 32 : addr_b + 8;

initial begin
    addr_a = 'd0;
    addr_b = 'd0;
end

always_ff @(negedge clk) begin
    addr_a <= next_addr_a;
    addr_b <= next_addr_b;
end

endmodule