`timescale 1ns / 1ps
`default_nettype none

module stage_decode_tb
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

// ID stage inputs (data hazards)
regaddr_t     hz_ex_wb_addr;     // write-back register address
word_t      hz_ex_wb_data;     // write-back register value
logic       hz_ex_wb_valid;    // write-back data valid
regaddr_t     hz_ma_wb_addr;     // write-back register address
word_t      hz_ma_wb_data;     // write-back register value
logic       hz_ma_wb_valid;    // write-back data valid
regaddr_t     hz_wb_addr;        // write-back register address
word_t      hz_wb_data;        // write-back register value

// ID stage outputs (to IF)
logic       id_ready;       // stage ready for new inputs
word_t      id_jmp_addr;    // jump address
logic       id_jmp_valid;   // jump address valid

// ID stage outputs (to EX)
word_t      id_ir;          // instruction register
word_t      id_alu_op1;     // ALU operand 1
word_t      id_alu_op2;     // ALU operand 2
alu_mode_t  id_alu_mode;    // ALU mode
ma_mode_t   id_ma_mode;     // memory access mode
ma_size_t   id_ma_size;     // memory access size
word_t      id_ma_data;     // memory access data
wb_src_t    id_wb_src;      // write-back register address


// Instruction Memory
block_rom #(.CONTENTS("d:/dev/riscy_click/bios/bios.coe")) rom (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .addr_a(imem_addr),
    .data_a(imem_data),
    .addr_b(32'h00000000),
    .data_b()
);

// Fetch Stage
stage_fetch stage_fetch (.*);

// Decode Stage
stage_decode stage_decode (.id_halt(halt), .*);

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

// write-back logic
initial begin
    hz_ex_wb_addr = 5'b00000;
    hz_ex_wb_data = 32'h00000000;
    hz_ex_wb_valid = 1'b1;

    hz_ma_wb_addr = 5'b00000;
    hz_ma_wb_data = 32'h00000000;
    hz_ma_wb_valid = 1'b1;

    hz_wb_addr = 5'b00000;
    hz_wb_data = 32'h00000000;
end

endmodule
