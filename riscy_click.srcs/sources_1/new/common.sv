`timescale 1ns / 1ps
`default_nettype none

package common;

//
// CPU Architecture
//

// PC Word Sizes
typedef logic [31:0] word_t;

// Register Address
typedef logic [4:0] regaddr_t;


///
/// Instruction Decoding
///

// Opcodes
typedef logic [6:0] opcode_t;
const opcode_t OP_LUI       = 7'b0110111; // Load Upper Immediate
const opcode_t OP_AUIPC     = 7'b0010111; // Add Upper Immediate To PC
const opcode_t OP_JAL       = 7'b1101111; // Jump And Link (use PC-ALU)
const opcode_t OP_JALR      = 7'b1100111; // Jump and Link Register
const opcode_t OP_BRANCH    = 7'b1100011; // Branch
const opcode_t OP_LOAD      = 7'b0000011; // Load
const opcode_t OP_STORE     = 7'b0100011; // Store
const opcode_t OP_IMM       = 7'b0010011; // Integer Register-Immediate Instructions
const opcode_t OP           = 7'b0110011; // Integer Register-Register Operations
const opcode_t OP_MISC_MEM  = 7'b0001111; // Miscellaneous Memory Operations
const opcode_t OP_SYSTEM    = 7'b1110011; // System Calls

// Funct3
typedef logic [2:0] funct3_t;
const funct3_t F3_ADD_SUB   = 3'b000;     // Addition or Subtraction
const funct3_t F3_SRL_SRA   = 3'b101;     // Shift Right Logical or Arithmetic
const funct3_t F3_BEQ       = 3'b000;     // Branch if EQ
const funct3_t F3_BNE       = 3'b001;     // Branch if NE
const funct3_t F3_BLT       = 3'b100;     // Branch if LT (Signed)
const funct3_t F3_BGE       = 3'b101;     // Branch if GE (Signed)
const funct3_t F3_BLTU      = 3'b110;     // Branch if LT (Unsigned)
const funct3_t F3_BGEU      = 3'b111;     // Branch if GE (Unsigned)
const funct3_t F3_LB        = 3'b000;     // Load Byte (Signed Extended)
const funct3_t F3_LH        = 3'b001;     // Load Half-Word (Signed Extended)
const funct3_t F3_LW        = 3'b010;     // Load Word
const funct3_t F3_LBU       = 3'b100;     // Load Byte (Unsigned)
const funct3_t F3_LHU       = 3'b101;     // Load Half-Word (Unsigned)
const funct3_t F3_SB        = 3'b000;     // Store Byte
const funct3_t F3_SH        = 3'b001;     // Store Half-Word
const funct3_t F3_SW        = 3'b010;     // Store Word

// Funct7
typedef logic [6:0] funct7_t;


///
/// Control Signals
///

// PC Mode
typedef enum logic [1:0] {
    PC_NEXT      = 2'b00,       // Next Instruction
    PC_JUMP_REL  = 2'b01,       // Jump (Relative)
    PC_JUMP_ABS  = 2'b10,       // Jump (Absolute)
    PC_BRANCH    = 2'b11        // ALU_ADD
} pc_mode_t;


// ALU Operand #1
typedef enum logic {
    ALU_OP1_RS1  = 1'b0,       // Register Source #1
    ALU_OP1_IMMU = 1'b1        // U-Type Immediate
} alu_op1_t;

const alu_op1_t ALU_OP1_X = ALU_OP1_RS1;

// ALU Operand #2
typedef enum logic [1:0] {
    ALU_OP2_RS2  = 2'b00,      // Register Source #2
    ALU_OP2_IMMI = 2'b01,      // I-Type Immediate
    ALU_OP2_IMMS = 2'b10,      // S-Type Immediate
    ALU_OP2_PC   = 2'b11       // Program Counter
} alu_op2_t;

const alu_op2_t ALU_OP2_X = ALU_OP2_RS2;

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
} alu_mode_t;

// Memory Access Mode
typedef enum logic [1:0] {
    MA_X         = 2'b00,       // No memory access
    MA_LOAD      = 2'b01,       // Load memory to register
    MA_STORE     = 2'b10        // Store ALU in memory
} ma_mode_t;

// Memory Access Size
typedef enum logic [2:0] {
    MA_SIZE_X    = 3'b000,     // No writeback
    MA_SIZE_B    = 3'b001,     // Byte (Signed)
    MA_SIZE_H    = 3'b010,     // Half-Word (Signed)
    MA_SIZE_W    = 3'b100,     // Word
    MA_SIZE_BU   = 3'b101,     // Byte (Unsigned)
    MA_SIZE_HU   = 3'b110      // Half-Word (Unsigned)
} ma_size_t;

// Write-Back Source
typedef enum logic [1:0] {
    WB_SRC_ALU   = 2'b00,      // Data from ALU
    WB_SRC_PC4   = 2'b01,      // Data is Next PC
    WB_SRC_MEM   = 2'b10       // Data from Memory
} wb_src_t;

const wb_src_t WB_SRC_X = WB_SRC_ALU;


//
// Control Word
//

typedef struct packed {
    logic      halt;
    pc_mode_t  pc_mode;
    alu_op1_t  alu_op1;
    alu_op2_t  alu_op2;
    alu_mode_t alu_mode;
    ma_mode_t  ma_mode;
    ma_size_t  ma_size;
    wb_src_t   wb_src;
} control_word_t;


//
// NOP
//

const word_t     NOP_PC       = 32'h00000000;
const word_t     NOP_IR       = 32'h00000013;
const word_t     NOP_ALU_OP   = 32'h00000000;
const alu_mode_t NOP_ALU_MODE = ALU_ADD;
const ma_mode_t  NOP_MA_MODE  = MA_X;
const ma_size_t  NOP_MA_SIZE  = MA_SIZE_X;
const word_t     NOP_MA_DATA  = 32'h00000000;
const regaddr_t  NOP_WB_ADDR  = 5'b00000;
const wb_src_t   NOP_WB_SRC   = WB_SRC_ALU;

endpackage