`timescale 1ns/1ps

///
/// I32 ALU (async)
///

module alu
    // Import Constants
    import consts::*;
    (
        input       alu_mode mode,
        input       word     operand1,
        input       word     operand2,
        output      word     result,
        output wire logic    zero
    );


// Shift Amount
wire [4:0] shamt = operand2[4:0];

// Zero Logic
assign zero = result == 32'b0 ? 1'b1 : 1'b0;

// Wide result for multiplication
dword wide_result;

// Result Logic
always_comb begin
    wide_result = 64'b0;

    case (mode)
        ALU_ADD:    result = operand1 + operand2;
        ALU_SUB:    result = operand1 - operand2;
        ALU_LSL:    result = operand1 << shamt;
        ALU_LSR:    result = operand1 >> shamt;
        ALU_ASR:    result = operand1 >>> shamt;
        ALU_AND:    result = operand1 & operand2;
        ALU_OR:     result = operand1 | operand2;
        ALU_XOR:    result = operand1 ^ operand2;
        ALU_SLT:    result = $signed(operand1) < $signed(operand2) ? 1 : 0;
        ALU_ULT:    result = operand1 < operand2 ? 1 : 0;
        ALU_COPY1:  result = operand1;
        ALU_MUL:    result = $signed(operand1) * $signed(operand2);
        ALU_MULH:   begin wide_result = $signed(operand1) * $signed(operand2); result = wide_result[63:32]; end
        ALU_MULHSU: begin wide_result = $signed(operand1) * operand2;          result = wide_result[63:32]; end
        ALU_MULHU:  begin wide_result = operand1 * operand2;                   result = wide_result[63:32]; end
        ALU_DIV:    result = $signed(operand1) / $signed(operand2);
        ALU_DIVU:   result = operand1 / operand2;
        ALU_REM:    result = $signed(operand1) % $signed(operand2);
        ALU_REMU:   result = operand1 % operand2;
        default:    result = 32'b0;
    endcase;
end

endmodule