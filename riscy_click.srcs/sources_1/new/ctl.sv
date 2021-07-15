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
        input        clk,           // Clock
        input        reset,         // Reset
        input  [6:0] opcode,        // Opcode from IR
        input  [2:0] funct3,        // Funct3 from IR
        input  [6:0] funct7,        // Funct7 from IR
        output       halt,          // Halt
        output       alu_op1_sel,   // ALU Operand 1 Selector
        output [1:0] alu_op2_sel,   // ALU Operand 2 Selector
        output [4:0] alu_mode,      // ALU Mode
        output [1:0] wb_src_sel,    // Write-Back Source Selector
        output [1:0] wb_dst_sel,    // Write-Back Destination Selector
        output [2:0] wb_mode,       // Write-Back Mode
        output [1:0] pc_mode_sel,   // PC Mode Selector
        output       pc_branch_zero // PC Branch Mode
    );


// Control Signal Logic
reg [17:0] cw;
assign halt           = cw[15];
assign alu_op1_sel    = cw[14];
assign alu_op2_sel    = cw[13:12];
assign alu_mode       = cw[11:7];
assign wb_src_sel     = cw[6:5];
assign wb_dst_sel     = cw[4:3];
assign wb_mode        = funct3;
assign pc_mode_sel    = cw[2:1];
assign pc_branch_zero = cw[0];

// Decoded ALU Mode
wire [4:0] alu_mode7 = { funct7[0], funct7[5], funct3 };
wire [4:0] alu_mode3 = { 2'b0, funct3 };

always @(*) begin
    casez ({reset, funct7, funct3, opcode})
    {1'b1, 7'b???????, 3'b???,     7'b???????}:  cw <= { 1'b0, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_X,   WB_X,       PC_NEXT,     1'b0 };
    {1'b?, 7'b0?00000, F3_SRL_SRA, OP_IMM}:      cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode7, WB_SRC_ALU, WB_DST_REG, PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_IMM}:      cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode3, WB_SRC_ALU, WB_DST_REG, PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_LUI}:      cw <= { 1'b0, ALU_OP1_IMMU, ALU_OP2_RS2,  ALU_COPY1, WB_SRC_ALU, WB_DST_REG, PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_AUIPC}:    cw <= { 1'b0, ALU_OP1_IMMU, ALU_OP2_PC,   ALU_ADD,   WB_SRC_ALU, WB_DST_REG, PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP}:          cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  alu_mode7, WB_SRC_ALU, WB_DST_REG, PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_JAL}:      cw <= { 1'b0, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_PC4, WB_DST_REG, PC_JUMP_REL, 1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_JALR}:     cw <= { 1'b0, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_PC4, WB_DST_REG, PC_JUMP_ABS, 1'b0 };
    {1'b?, 7'b???????, F3_BEQ,     OP_BRANCH}:   cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SUB,   WB_SRC_X,   WB_X,       PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, F3_BNE,     OP_BRANCH}:   cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SUB,   WB_SRC_X,   WB_X,       PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, F3_BLT,     OP_BRANCH}:   cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SLT,   WB_SRC_X,   WB_X,       PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, F3_BGE,     OP_BRANCH}:   cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SLT,   WB_SRC_X,   WB_X,       PC_BRANCH,   1'b1 };
    {1'b?, 7'b???????, F3_BLTU,    OP_BRANCH}:   cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_ULT,   WB_SRC_X,   WB_X,       PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, F3_BGEU,    OP_BRANCH}:   cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_ULT,   WB_SRC_X,   WB_X,       PC_BRANCH,   1'b1 };
    {1'b?, 7'b???????, 3'b???,     OP_LOAD}:     cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_IMMI, ALU_ADD,   WB_SRC_MEM, WB_DST_REG, PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_STORE}:    cw <= { 1'b0, ALU_OP1_RS1,  ALU_OP2_IMMS, ALU_ADD,   WB_SRC_ALU, WB_DST_MEM, PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_MISC_MEM}: cw <= { 1'b0, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_X,   WB_X,       PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,     OP_SYSTEM}:   cw <= { 1'b0, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_X,   WB_X,       PC_NEXT,     1'b0 };
    default:                                     cw <= { 1'b1, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     WB_SRC_X,   WB_X,       PC_NEXT,     1'b0 };
    endcase
end

endmodule