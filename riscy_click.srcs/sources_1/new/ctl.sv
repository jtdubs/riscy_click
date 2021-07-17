`timescale 1ns/1ps

///
/// Risc-V Controller
///
/// Supports RV32I, RV32E
///

module ctl
    // Import Constants
    import consts::*;
    (
        input  logic        clk,    // Clock
        input  logic        reset,  // Reset
        input  op           opcode, // Opcode from IR
        input  funct3       f3,     // Funct3 from IR
        input  logic [6:0]  f7,     // Funct7 from IR
        output control_word cw      // Control Word
    );

// Decoded ALU Mode
wire alu_mode alu_mode7 = alu_mode'({ f7[0], f7[5], f3 });
wire alu_mode alu_mode3 = alu_mode'({ 2'b0, f3 });

always_comb begin
    casez ({reset, f7, f3, opcode})
    {1'b1, 7'b???????, 3'b???,     7'b???????}:  cw <= '{ 1'b0, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_X,   WB_X,       WB_MODE_X,    PC_NEXT,     1'b0 };
    {1'b?, 7'b0?00000, F3_SRL_SRA, OP_IMM}:      cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode7, WB_SRC_ALU, WB_DST_REG, WB_MODE_W,    PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_IMM}:      cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode3, WB_SRC_ALU, WB_DST_REG, WB_MODE_W,    PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_LUI}:      cw <= '{ 1'b0, ALU_OP1_IMMU, ALU_OP2_RS2,  ALU_COPY1, WB_SRC_ALU, WB_DST_REG, WB_MODE_W,    PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_AUIPC}:    cw <= '{ 1'b0, ALU_OP1_IMMU, ALU_OP2_PC,   ALU_ADD,   WB_SRC_ALU, WB_DST_REG, WB_MODE_W,    PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP}:          cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  alu_mode7, WB_SRC_ALU, WB_DST_REG, WB_MODE_W,    PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_JAL}:      cw <= '{ 1'b0, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_PC4, WB_DST_REG, WB_MODE_W,    PC_JUMP_REL, 1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_JALR}:     cw <= '{ 1'b0, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_PC4, WB_DST_REG, WB_MODE_W,    PC_JUMP_ABS, 1'b0 };
    {1'b?, 7'b???????, F3_BEQ,     OP_BRANCH}:   cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SUB,   WB_SRC_X,   WB_X,       WB_MODE_X,    PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, F3_BNE,     OP_BRANCH}:   cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SUB,   WB_SRC_X,   WB_X,       WB_MODE_X,    PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, F3_BLT,     OP_BRANCH}:   cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SLT,   WB_SRC_X,   WB_X,       WB_MODE_X,    PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, F3_BGE,     OP_BRANCH}:   cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SLT,   WB_SRC_X,   WB_X,       WB_MODE_X,    PC_BRANCH,   1'b1 };
    {1'b?, 7'b???????, F3_BLTU,    OP_BRANCH}:   cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_ULT,   WB_SRC_X,   WB_X,       WB_MODE_X,    PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, F3_BGEU,    OP_BRANCH}:   cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_ULT,   WB_SRC_X,   WB_X,       WB_MODE_X,    PC_BRANCH,   1'b1 };
    {1'b?, 7'b???????, 3'b???,     OP_LOAD}:     cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_IMMI, ALU_ADD,   WB_SRC_MEM, WB_DST_REG, WB_MODE_W,    PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_STORE}:    cw <= '{ 1'b0, ALU_OP1_RS1,  ALU_OP2_IMMS, ALU_ADD,   WB_SRC_ALU, WB_DST_MEM, wb_mode'(f3), PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_MISC_MEM}: cw <= '{ 1'b0, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_X,   WB_X,       WB_MODE_X,    PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_SYSTEM}:   cw <= '{ 1'b0, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_X,   WB_X,       WB_MODE_X,    PC_NEXT,     1'b0 };
    default:                                     cw <= '{ 1'b1, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_X,   WB_X,       WB_MODE_X,    PC_NEXT,     1'b0 };
    endcase
end

endmodule