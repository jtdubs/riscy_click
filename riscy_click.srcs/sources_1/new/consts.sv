`timescale 1ns / 1ps
`default_nettype none

///
/// Constants
///

`timescale 1ns/1ps

package consts;

//
// CPU Architecture
//

// PC Word Sizes
typedef logic [31:0] word;
typedef logic [63:0] dword;

// Register Address
typedef logic [4:0] regaddr;


///
/// Instruction Decoding
///

// Opcodes
typedef logic [6:0] op;
parameter OP_LUI       = 7'b0110111; // Load Upper Immediate
parameter OP_AUIPC     = 7'b0010111; // Add Upper Immediate To PC
parameter OP_JAL       = 7'b1101111; // Jump And Link (use PC-ALU)
parameter OP_JALR      = 7'b1100111; // Jump and Link Register
parameter OP_BRANCH    = 7'b1100011; // Branch
parameter OP_LOAD      = 7'b0000011; // Load
parameter OP_STORE     = 7'b0100011; // Store
parameter OP_IMM       = 7'b0010011; // Integer Register-Immediate Instructions
parameter OP           = 7'b0110011; // Integer Register-Register Operations
parameter OP_MISC_MEM  = 7'b0001111; // Miscellaneous Memory Operations
parameter OP_SYSTEM    = 7'b1110011; // System Calls

// Funct3
typedef logic [2:0] funct3;
parameter F3_ADD_SUB   = 3'b000;     // Addition or Subtraction
parameter F3_SRL_SRA   = 3'b101;     // Shift Right Logical or Arithmetic
parameter F3_BEQ       = 3'b000;     // Branch if EQ
parameter F3_BNE       = 3'b001;     // Branch if NE
parameter F3_BLT       = 3'b100;     // Branch if LT (Signed)
parameter F3_BGE       = 3'b101;     // Branch if GE (Signed)
parameter F3_BLTU      = 3'b110;     // Branch if LT (Unsigned)
parameter F3_BGEU      = 3'b111;     // Branch if GE (Unsigned)
parameter F3_LB        = 3'b000;     // Load Byte (Signed Extended)
parameter F3_LH        = 3'b001;     // Load Half-Word (Signed Extended)
parameter F3_LW        = 3'b010;     // Load Word
parameter F3_LBU       = 3'b100;     // Load Byte (Unsigned)
parameter F3_LHU       = 3'b101;     // Load Half-Word (Unsigned)
parameter F3_SB        = 3'b000;     // Store Byte
parameter F3_SH        = 3'b001;     // Store Half-Word
parameter F3_SW        = 3'b010;     // Store Word



///
/// Control Signals
///

// Write-Back Source
typedef enum logic [1:0] {
    WB_SRC_ALU   = 2'b00,      // Data from ALU
    WB_SRC_PC4   = 2'b01,      // Data is Next PC
    WB_SRC_MEM   = 2'b10       // Data from Memory
} wb_src;

const wb_src WB_SRC_X = WB_SRC_ALU;

// Write-Back Destination
typedef enum logic [1:0] {
    WB_X         = 2'b00,      // No write-back
    WB_DST_REG   = 2'b01,      // Write-back to Register
    WB_DST_MEM   = 2'b10       // Write-back to Memory
} wb_dst;

// Write-Back Mode
typedef enum logic [2:0] {
    WB_MODE_B    = 3'b000,     // Byte (Signed)
    WB_MODE_H    = 3'b001,     // Half-Word (Signed)
    WB_MODE_W    = 3'b010,     // Word
    WB_MODE_BU   = 3'b100,     // Byte (Unsigned)
    WB_MODE_HU   = 3'b101      // Half-Word (Unsigned)
} wb_mode;

const wb_mode WB_MODE_X = WB_MODE_W;

// ALU Operand #1
typedef enum logic {
    ALU_OP1_RS1  = 1'b0,       // Register Source #1
    ALU_OP1_IMMU = 1'b1        // U-Type Immediate
} alu_op1;

const alu_op1 ALU_OP1_X = ALU_OP1_RS1;

// ALU Operand #2
typedef enum logic [1:0] {
    ALU_OP2_RS2  = 2'b00,      // Register Source #2
    ALU_OP2_IMMI = 2'b01,      // I-Type Immediate
    ALU_OP2_IMMS = 2'b10,      // S-Type Immediate
    ALU_OP2_PC   = 2'b11       // Program Counter
} alu_op2;

const alu_op2 ALU_OP2_X = ALU_OP2_RS2;


// ALU Mode
typedef enum logic [4:0] {
    ALU_ADD      = 5'b00000,    // Addition
    ALU_LSL      = 5'b00001,    // Logical Shift Left
    ALU_SLT      = 5'b00010,    // Less-Than (Signed)
    ALU_ULT      = 5'b00011,    // Less-Than (Unsigned)
    ALU_XOR      = 5'b00100,    // Binary XOR
    ALU_LSR      = 5'b00101,    // Logical Shift Right
    ALU_OR       = 5'b00110,    // Binary OR
    ALU_AND      = 5'b00111,    // Binary AND
    ALU_SUB      = 5'b01000,    // Subtraction
    ALU_ASR      = 5'b01101,    // Logical Shift Right
//    ALU_MUL      = 5'b10000,    // Multiply
//    ALU_MULH     = 5'b10001,    // Multiply (High)
//    ALU_MULHSU   = 5'b10010,    // Multiply (High, Signed x Unsigned)
//    ALU_MULHU    = 5'b10011,    // Multiple (High, Unsigned)
//    ALU_DIV      = 5'b10100,    // Divide
//    ALU_DIVU     = 5'b10101,    // Divide (Unsigned)
//    ALU_REM      = 5'b10110,    // Remainder
//    ALU_REMU     = 5'b10111,    // Remainder (Unsigned)
    ALU_COPY1    = 5'b11001,    // Output Operand #1
    ALU_X        = 5'b11111     // Disabled
} alu_mode;

// PC Mode
typedef enum logic [1:0] {
    PC_NEXT      = 2'b00,       // Next Instruction
    PC_JUMP_REL  = 2'b01,       // Jump (Relative)
    PC_JUMP_ABS  = 2'b10,       // Jump (Absolute)
    PC_BRANCH    = 2'b11        // ALU_ADD
} pc_mode;


//
// Control Word
//

typedef struct packed {
    logic    halt;
    alu_op1  alu_op1_sel;
    alu_op2  alu_op2_sel;
    alu_mode alu_mode_sel;
    wb_src   wb_src_sel;
    wb_dst   wb_dst_sel;
    wb_mode  wb_mode_sel;
    pc_mode  pc_mode_sel;
    // logic    pc_branch_zero;
} control_word;

endpackage
