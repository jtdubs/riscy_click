`timescale 1ns / 1ps
`default_nettype none

module cpu_if_tb
    // Import Constants
    import consts::*;
    ();

// cpu_if signals
logic clk, reset, halt;         // board
word mem_addr, mem_data;        // bus
word id_jmp_addr;                // in
logic id_jmp_valid, id_ready;   // in
word if_pc, if_ir;              // out
logic if_valid;                 // out

// cpu_if under test
cpu_if #(.MEM_ACCESS_CYCLES(1)) cpu_if (
    .clk(clk),
    .reset(reset),
    .halt(halt),
    .mem_addr(mem_addr),
    .mem_data(mem_data),
    .id_jmp_addr(id_jmp_addr),
    .id_jmp_valid(id_jmp_valid),
    .id_ready(id_ready),
    .if_pc(if_pc),
    .if_ir(if_ir),
    .if_valid(if_valid)
);

// block rom to test against
block_rom #(.CONTENTS("d:/dev/riscy_click/bios/tb_bios.coe")) rom (
    .clk(clk),
    .reset(reset),
    .addr_a(mem_addr),
    .data_a(mem_data),
    .addr_b(32'h00000000),
    .data_b()
);

// clock generator
initial begin
    clk = 1;
    forever begin
        #50 clk <= ~clk;
    end
end

// reset pulse
initial begin
    reset = 1;
    #250 reset = 0;
end

// halt eventually
initial begin
    halt = 0;
    #3050 halt = 1;
end

// test backpressure
initial begin
    id_ready = 1'b1;

    #2400
    @(posedge clk) id_ready = 1'b0;
    @(posedge clk);
    @(posedge clk) id_ready = 1'b1;
end

// do some jumps
initial begin
    id_jmp_addr = 32'hXXXX;
    id_jmp_valid = 1'b0;

    #700
    @(posedge clk) begin
        id_jmp_addr = 32'h0100;
        id_jmp_valid = 1'b1;
    end
    @(posedge clk) begin
        id_jmp_addr = 32'hXXXX;
        id_jmp_valid = 1'b0;
    end
    
    #600
    @(posedge clk) begin
        id_jmp_addr = 32'h0080;
        id_jmp_valid = 1'b1;
    end
    @(posedge clk) begin
        id_jmp_addr = 32'hXXXX;
        id_jmp_valid = 1'b0;
    end
end

endmodule
