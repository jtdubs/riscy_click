`timescale 1ns / 1ps
`default_nettype none

module cpu_if_tb
    // Import Constants
    import common::*;
    ();

// cpu signals
logic       clk;            // clock
logic       reset;          // reset
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
    .clk(clk),
    .reset(reset),
    .addr_a(imem_addr),
    .data_a(imem_data),
    .addr_b(32'h00000000),
    .data_b()
);

// Fetch Stage
cpu_if #(.MEM_ACCESS_CYCLES(1)) cpu_if (.*);


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
