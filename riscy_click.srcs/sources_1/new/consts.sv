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

// PC Mode
typedef enum logic [1:0] {
    PC_NEXT      = 2'b00,       // Next Instruction
    PC_JUMP_REL  = 2'b01,       // Jump (Relative)
    PC_JUMP_ABS  = 2'b10,       // Jump (Absolute)
    PC_BRANCH    = 2'b11        // ALU_ADD
} pc_mode;


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
    ALU_COPY1    = 5'b11001,    // Output Operand #1
    ALU_X        = 5'b11111     // Disabled
} alu_mode;

// Memory Access Mode
typedef enum logic [1:0] {
    MA_X         = 2'b00,       // No memory access
    MA_LOAD      = 2'b01,       // Load memory to register
    MA_STORE     = 2'b10        // Store ALU in memory
} ma_mode;

// Memory Access Size
typedef enum logic [2:0] {
    MA_SIZE_X    = 3'b000,     // No writeback
    MA_SIZE_B    = 3'b001,     // Byte (Signed)
    MA_SIZE_H    = 3'b010,     // Half-Word (Signed)
    MA_SIZE_W    = 3'b100,     // Word
    MA_SIZE_BU   = 3'b101,     // Byte (Unsigned)
    MA_SIZE_HU   = 3'b110      // Half-Word (Unsigned)
} ma_size;

// Write-Back Source
typedef enum logic [1:0] {
    WB_SRC_ALU   = 2'b00,      // Data from ALU
    WB_SRC_PC4   = 2'b01,      // Data is Next PC
    WB_SRC_MEM   = 2'b10       // Data from Memory
} wb_src;

const wb_src WB_SRC_X = WB_SRC_ALU;


//
// Control Word
//

typedef struct packed {
    logic    halt;
    pc_mode  pc_mode_sel;
    alu_op1  alu_op1_sel;
    alu_op2  alu_op2_sel;
    alu_mode alu_mode_sel;
    ma_mode  ma_mode_sel;
    ma_size  ma_size_sel;
    wb_src   wb_src_sel;
} control_word;

endpackage
