`timescale 1ns / 1ps
`default_nettype none

module cpu_if_tb
    // Import Constants
    import common::*;
    ();

// cpu signals
logic       clk_i;            // clock
logic       reset_i;          // reset_i
logic       halt;           // halt

// IF memory access
word_t      imem_addr;      // address
word_t      imem_data;      // data


// ID stage inputs
word_t      if_pc;          // program counter
word_t      if_ir;          // instruction register
logic       if_valid;       // fetch stage data is valid

// ID stage outputs (to IF)
logic       id_ready;       // stage ready for new inputs
word_t      id_jmp_addr;    // jump address
logic       id_jmp_valid;   // jump address valid

// Instruction Memory
block_rom #(.CONTENTS("d:/dev/riscy_click/bios/tb_bios.coe")) rom (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .addr_a(imem_addr),
    .data_a(imem_data),
    .addr_b(32'h00000000),
    .data_b()
);

// Fetch Stage
cpu_if #(.MEM_ACCESS_CYCLES(1)) cpu_if (.*);


// clock generator
initial begin
    clk_i = 1;
    forever begin
        #50 clk_i <= ~clk_i;
    end
end

// reset_i pulse
initial begin
    reset_i = 1;
    #250 reset_i = 0;
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
    @(posedge clk_i) id_ready = 1'b0;
    @(posedge clk_i);
    @(posedge clk_i) id_ready = 1'b1;
end

// do some jumps
initial begin
    id_jmp_addr = 32'hXXXX;
    id_jmp_valid = 1'b0;

    #700
    @(posedge clk_i) begin
        id_jmp_addr = 32'h0100;
        id_jmp_valid = 1'b1;
    end
    @(posedge clk_i) begin
        id_jmp_addr = 32'hXXXX;
        id_jmp_valid = 1'b0;
    end
    
    #600
    @(posedge clk_i) begin
        id_jmp_addr = 32'h0080;
        id_jmp_valid = 1'b1;
    end
    @(posedge clk_i) begin
        id_jmp_addr = 32'hXXXX;
        id_jmp_valid = 1'b0;
    end
end

endmodule
