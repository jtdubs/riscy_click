`timescale 1ns/1ps

///
/// I32 ALU (async)
///

module alu
    // Import Constants
    import common::*;
    (
        // Inputs
        input  wire alu_mode_t alu_mode_async_i,
        input  wire word_t     alu_op1_async_i,
        input  wire word_t     alu_op2_async_i,

        // Outputs
        output      word_t     alu_result_async_o
    );


// Shift Amount
logic [4:0] shamt_w;
always_comb shamt_w = alu_op2_async_i[4:0];

// Result Logic
always_comb begin
    unique case (alu_mode_async_i)
        ALU_ADD:   alu_result_async_o = alu_op1_async_i + alu_op2_async_i;
        ALU_SUB:   alu_result_async_o = alu_op1_async_i - alu_op2_async_i;
        ALU_AND:   alu_result_async_o = alu_op1_async_i & alu_op2_async_i;
        ALU_OR:    alu_result_async_o = alu_op1_async_i | alu_op2_async_i;
        ALU_XOR:   alu_result_async_o = alu_op1_async_i ^ alu_op2_async_i;
        ALU_LSL:   alu_result_async_o = alu_op1_async_i <<  shamt_w;
        ALU_LSR:   alu_result_async_o = alu_op1_async_i >>  shamt_w;
        ALU_ASR:   alu_result_async_o = alu_op1_async_i >>> shamt_w;
        ALU_SLT:   alu_result_async_o = (signed'(alu_op1_async_i) < signed'(alu_op2_async_i)) ? 32'b1 : 32'b0;
        ALU_ULT:   alu_result_async_o = (        alu_op1_async_i  <         alu_op2_async_i)  ? 32'b1 : 32'b0;
        ALU_COPY1: alu_result_async_o = alu_op1_async_i;
        ALU_X:     alu_result_async_o = 32'b0;
    endcase
end

endmodule
