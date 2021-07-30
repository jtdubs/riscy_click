`timescale 1ns/1ps

///
/// I32 ALU (async)
///

module alu
    // Import Constants
    import common::*;
    (
        // Inputs
        input  wire alu_mode_t ia_alu_mode,
        input  wire word_t     ia_alu_operand1,
        input  wire word_t     ia_alu_operand2,
        
        // Outputs
        output      word_t     oa_alu_result,
        output      logic      oa_alu_zero
    );


// Shift Amount
logic [4:0] a_shamt;
always_comb a_shamt = ia_alu_operand2[4:0];

// Zero Logic
always_comb oa_alu_zero = (oa_alu_result == 32'b0);

// Result Logic
always_comb begin
    unique case (ia_alu_mode)
        ALU_ADD:   oa_alu_result = ia_alu_operand1 + ia_alu_operand2;
        ALU_SUB:   oa_alu_result = ia_alu_operand1 - ia_alu_operand2;
        ALU_AND:   oa_alu_result = ia_alu_operand1 & ia_alu_operand2;
        ALU_OR:    oa_alu_result = ia_alu_operand1 | ia_alu_operand2;
        ALU_XOR:   oa_alu_result = ia_alu_operand1 ^ ia_alu_operand2;
        ALU_LSL:   oa_alu_result = ia_alu_operand1 <<  a_shamt;
        ALU_LSR:   oa_alu_result = ia_alu_operand1 >>  a_shamt;
        ALU_ASR:   oa_alu_result = ia_alu_operand1 >>> a_shamt;
        ALU_SLT:   oa_alu_result = (signed'(ia_alu_operand1) < signed'(ia_alu_operand2)) ? 32'b1 : 32'b0;
        ALU_ULT:   oa_alu_result = (        ia_alu_operand1  <         ia_alu_operand2)  ? 32'b1 : 32'b0;
        ALU_COPY1: oa_alu_result = ia_alu_operand1;
        ALU_X:     oa_alu_result = 32'b0;
    endcase;
end

endmodule
