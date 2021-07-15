`timescale 1ns/1ps

///
/// I32 ALU (async)
///

module alu
    (
        input      [ 4:0] mode,      // Mode
        input      [31:0] operand1,  // Operand #1
        input      [31:0] operand2,  // Operand #2
        output reg [31:0] result,    // Result
        output            zero       // True if result is zero
    );

// Import Constants
consts c ();

// Shift Amount
wire [4:0] shamt = operand2[4:0];

// Zero Logic
assign zero = result == 32'b0 ? 1'b1 : 1'b0;

// Wide result for multiplication
reg [63:0] wide_result;

// Result Logic
always @(*) begin
    wide_result = 64'b0;

    case (mode)
        c.ALU_ADD:    result <= operand1 + operand2;
        c.ALU_SUB:    result <= operand1 - operand2;
        c.ALU_LSL:    result <= operand1 << shamt;
        c.ALU_LSR:    result <= operand1 >> shamt;
        c.ALU_ASR:    result <= operand1 >>> shamt;
        c.ALU_AND:    result <= operand1 & operand2;
        c.ALU_OR:     result <= operand1 | operand2;
        c.ALU_XOR:    result <= operand1 ^ operand2;
        c.ALU_SLT:    result <= $signed(operand1) < $signed(operand2) ? 1 : 0;
        c.ALU_ULT:    result <= operand1 < operand2 ? 1 : 0;
        c.ALU_COPY1:  result <= operand1;
        c.ALU_MUL:    result <= $signed(operand1) * $signed(operand2);
        c.ALU_MULH:   begin wide_result <= $signed(operand1) * $signed(operand2); result <= wide_result[63:32]; end
        c.ALU_MULHSU: begin wide_result <= $signed(operand1) * operand2;          result <= wide_result[63:32]; end
        c.ALU_MULHU:  begin wide_result <= operand1 * operand2;                   result <= wide_result[63:32]; end
        c.ALU_DIV:    result <= $signed(operand1) / $signed(operand2);
        c.ALU_DIVU:   result <= operand1 / operand2;
        c.ALU_REM:    result <= $signed(operand1) % $signed(operand2);
        c.ALU_REMU:   result <= operand1 % operand2;
        default:      result <= 32'b0;
    endcase;
end

endmodule