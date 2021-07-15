`timescale 1ns/1ps

///
/// Risc-V Controller
///
/// Supports RV32I, RV32E
///

module ctl
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


// Import Constants
consts c ();

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
    {1'b1, 7'b???????, 3'b???,       7'b???????}:    cw <= { 1'b0, c.ALU_OP1_X,    c.ALU_OP2_X,    c.ALU_X,     c.WB_SRC_X,   c.WB_X,       c.PC_NEXT,     1'b0 };
    {1'b?, 7'b0?00000, c.F3_SRL_SRA, c.OP_IMM}:      cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_IMMI, alu_mode7,   c.WB_SRC_ALU, c.WB_DST_REG, c.PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,       c.OP_IMM}:      cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_IMMI, alu_mode3,   c.WB_SRC_ALU, c.WB_DST_REG, c.PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,       c.OP_LUI}:      cw <= { 1'b0, c.ALU_OP1_IMMU, c.ALU_OP2_RS2,  c.ALU_COPY1, c.WB_SRC_ALU, c.WB_DST_REG, c.PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,       c.OP_AUIPC}:    cw <= { 1'b0, c.ALU_OP1_IMMU, c.ALU_OP2_PC,   c.ALU_ADD,   c.WB_SRC_ALU, c.WB_DST_REG, c.PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,       c.OP}:          cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_RS2,  alu_mode7,   c.WB_SRC_ALU, c.WB_DST_REG, c.PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,       c.OP_JAL}:      cw <= { 1'b0, c.ALU_OP1_X,    c.ALU_OP2_X,    c.ALU_X,     c.WB_SRC_PC4, c.WB_DST_REG, c.PC_JUMP_REL, 1'b0 };
    {1'b?, 7'b???????, 3'b???,       c.OP_JALR}:     cw <= { 1'b0, c.ALU_OP1_X,    c.ALU_OP2_X,    c.ALU_X,     c.WB_SRC_PC4, c.WB_DST_REG, c.PC_JUMP_ABS, 1'b0 };
    {1'b?, 7'b???????, c.F3_BEQ,     c.OP_BRANCH}:   cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_RS2,  c.ALU_SUB,   c.WB_SRC_X,   c.WB_X,       c.PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, c.F3_BNE,     c.OP_BRANCH}:   cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_RS2,  c.ALU_SUB,   c.WB_SRC_X,   c.WB_X,       c.PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, c.F3_BLT,     c.OP_BRANCH}:   cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_RS2,  c.ALU_SLT,   c.WB_SRC_X,   c.WB_X,       c.PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, c.F3_BGE,     c.OP_BRANCH}:   cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_RS2,  c.ALU_SLT,   c.WB_SRC_X,   c.WB_X,       c.PC_BRANCH,   1'b1 };
    {1'b?, 7'b???????, c.F3_BLTU,    c.OP_BRANCH}:   cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_RS2,  c.ALU_ULT,   c.WB_SRC_X,   c.WB_X,       c.PC_BRANCH,   1'b0 };
    {1'b?, 7'b???????, c.F3_BGEU,    c.OP_BRANCH}:   cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_RS2,  c.ALU_ULT,   c.WB_SRC_X,   c.WB_X,       c.PC_BRANCH,   1'b1 };
    {1'b?, 7'b???????, 3'b???,       c.OP_LOAD}:     cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_IMMI, c.ALU_ADD,   c.WB_SRC_MEM, c.WB_DST_REG, c.PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,       c.OP_STORE}:    cw <= { 1'b0, c.ALU_OP1_RS1,  c.ALU_OP2_IMMS, c.ALU_ADD,   c.WB_SRC_ALU, c.WB_DST_MEM, c.PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,       c.OP_MISC_MEM}: cw <= { 1'b0, c.ALU_OP1_X,    c.ALU_OP2_X,    c.ALU_X,     c.WB_SRC_X,   c.WB_X,       c.PC_NEXT,     1'b0 };
    {1'b?, 7'b???????, 3'b???,       c.OP_SYSTEM}:   cw <= { 1'b0, c.ALU_OP1_X,    c.ALU_OP2_X,    c.ALU_X,     c.WB_SRC_X,   c.WB_X,       c.PC_NEXT,     1'b0 };
    default:                                         cw <= { 1'b1, c.ALU_OP1_X,    c.ALU_OP2_X,    c.ALU_X,     c.WB_SRC_X,   c.WB_X,       c.PC_NEXT,     1'b0 };
    endcase
end

endmodule