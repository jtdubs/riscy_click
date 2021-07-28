`timescale 1ns/1ps

///
/// I32 ALU (async)
///

module alu
    // Import Constants
    import common::*;
    (
        // Inputs
        input  wire alu_mode_t mode,
        input  wire word_t     operand1,
        input  wire word_t     operand2,
        
        // Outputs
        output      word_t   result,
        output      logic    zero
    );


// Shift Amount
wire logic [4:0] shamt = operand2[4:0];

// Zero Logic
always_comb zero = (result == 32'b0) ? 1'b1 : 1'b0;

// Result Logic
always_comb begin
    unique case (mode)
        ALU_ADD:   result = operand1 + operand2;
        ALU_SUB:   result = operand1 - operand2;
        ALU_LSL:   result = operand1 << shamt;
        ALU_LSR:   result = operand1 >> shamt;
        ALU_ASR:   result = operand1 >>> shamt;
        ALU_AND:   result = operand1 & operand2;
        ALU_OR:    result = operand1 | operand2;
        ALU_XOR:   result = operand1 ^ operand2;
        ALU_SLT:   result = (signed'(operand1) < signed'(operand2)) ? 1 : 0;
        ALU_ULT:   result = (operand1 < operand2) ? 1 : 0;
        ALU_COPY1: result = operand1;
        ALU_X:     result = 32'b0;
    endcase;
end

endmodule
