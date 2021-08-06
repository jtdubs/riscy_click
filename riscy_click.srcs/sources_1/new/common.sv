`timescale 1ns / 1ps
`default_nettype none

package common;

//
// CPU Architecture
//

// PC Word Sizes
typedef logic [31:0] word_t;
typedef logic [63:0] dword_t;

// Register Address
typedef logic [4:0]  regaddr_t;

// CSR Address
typedef logic [11:0] csr_t;


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

// Funct3 (OP_BRANCH)
const funct3_t F3_BEQ       = 3'b000;     // Branch if EQ
const funct3_t F3_BNE       = 3'b001;     // Branch if NE
const funct3_t F3_BLT       = 3'b100;     // Branch if LT (Signed)
const funct3_t F3_BGE       = 3'b101;     // Branch if GE (Signed)
const funct3_t F3_BLTU      = 3'b110;     // Branch if LT (Unsigned)
const funct3_t F3_BGEU      = 3'b111;     // Branch if GE (Unsigned)

// Funct3 (OP_LOAD)
const funct3_t F3_LB        = 3'b000;     // Load Byte (Signed Extended)
const funct3_t F3_LH        = 3'b001;     // Load Half-Word (Signed Extended)
const funct3_t F3_LW        = 3'b010;     // Load Word
const funct3_t F3_LBU       = 3'b100;     // Load Byte (Unsigned)
const funct3_t F3_LHU       = 3'b101;     // Load Half-Word (Unsigned)

// Funct3 (OP_STORE)
const funct3_t F3_SB        = 3'b000;     // Store Byte
const funct3_t F3_SH        = 3'b001;     // Store Half-Word
const funct3_t F3_SW        = 3'b010;     // Store Word

// Funct3 (OP_IMM and OP)
const funct3_t F3_ADD_SUB   = 3'b000;     // Addition or Subtraction
const funct3_t F3_SLT       = 3'b010;     // Signed Less-Than
const funct3_t F3_SLTU      = 3'b011;     // Signed Less-Than(Upper)
const funct3_t F3_XOR       = 3'b100;     // Binary XOR
const funct3_t F3_OR        = 3'b110;     // Binary OR
const funct3_t F3_AND       = 3'b111;     // Binary AND
const funct3_t F3_SLL       = 3'b001;     // Shift Left Logical
const funct3_t F3_SRL_SRA   = 3'b101;     // Shift Right Logical and Arithmetic

// Funct3 (OP_MISC_MEM)
const funct3_t F3_FENCE     = 3'b000;     // Fence
const funct3_t F3_FENCEI    = 3'b001;     // Fence Immediate

// Funct3 (OP_SYSTEM)
const funct3_t F3_PRIV      = 3'b000;     // Environment Call
const funct3_t F3_CSRRW     = 3'b001;     // Atomic R/W CSR
const funct3_t F3_CSRRS     = 3'b010;     // Atomic RSB CSR
const funct3_t F3_CSRRC     = 3'b011;     // Atomic RC CSR
const funct3_t F3_CSRRWI    = 3'b101;     // Atomic R/W Immedate CSR
const funct3_t F3_CSRRSI    = 3'b110;     // Atomic RSB Immedate CSR
const funct3_t F3_CSRRCI    = 3'b111;     // Atomic RC Immedate CSR

// Funct7
typedef logic [6:0] funct7_t;

// CSR
const csr_t CSR_FFLAGS      = 12'h001;     // Floating-Point Accrued Exceptions
const csr_t CSR_FRM         = 12'h002;     // Floating-Point Dynamic Rounding Mode
const csr_t CSR_FCSR        = 12'h003;     // Floating-Point Control and Status Registers
const csr_t CSR_CYCLE       = 12'hC00;     // Cycle Counter for RDCYCLE instruction
const csr_t CSR_TIME        = 12'hC01;     // Timer for RDTIME instruction
const csr_t CSR_INSTRET     = 12'hC02;     // Instructions-retired counter for RDINSTRET instruction
const csr_t CSR_CYCLEH      = 12'hC80;     // Upper 32 bits of cycle, RV32I only
const csr_t CSR_TIMEH       = 12'hC81;     // Upper 32 bits of time, RV32I only
const csr_t CSR_INSTRETH    = 12'hC82;     // Upper 32 bits of instret, RV32I only

// Funct12
typedef logic [11:0] funct12_t;
const funct12_t F12_ECALL   = 12'h000;     // Environment call
const funct12_t F12_EBREAK  = 12'h001;     // Environment breakpoint


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
typedef enum logic [1:0] {
    ALU_OP1_X    = 2'b00,      // Disabled
    ALU_OP1_RS1  = 2'b01,      // Register Source #1
    ALU_OP1_IMMU = 2'b10       // U-Type Immediate
} alu_op1_t;

// ALU Operand #2
typedef enum logic [2:0] {
    ALU_OP2_X    = 3'b000,     // Disabled
    ALU_OP2_RS2  = 3'b001,     // Register Source #2
    ALU_OP2_IMMI = 3'b010,     // I-Type Immediate
    ALU_OP2_IMMS = 3'b011,     // S-Type Immediate
    ALU_OP2_PC   = 3'b100      // Program Counter
} alu_op2_t;

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
    MA_SIZE_B    = 3'b000,     // Byte (Signed)
    MA_SIZE_H    = 3'b001,     // Half-Word (Signed)
    MA_SIZE_W    = 3'b010,     // Word
    MA_SIZE_BU   = 3'b100,     // Byte (Unsigned)
    MA_SIZE_HU   = 3'b101      // Half-Word (Unsigned)
} ma_size_t;

const ma_size_t MA_SIZE_X = MA_SIZE_W;

// Write-Back Source
typedef enum logic [1:0] {
    WB_SRC_X     = 2'b00,      // Disabled
    WB_SRC_ALU   = 2'b01,      // Data from ALU
    WB_SRC_PC4   = 2'b10,      // Data is Next PC
    WB_SRC_MEM   = 2'b11       // Data from Memory
} wb_src_t;


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
    logic      ra_used;
    logic      rb_used;
    logic      csr_used;
} control_word_t;


//
// NOP
//

const word_t     NOP_PC       = 32'hFFFFFFFF;
const word_t     NOP_IR       = 32'h00000013;
const word_t     NOP_ALU_OP1  = ALU_OP1_X;
const word_t     NOP_ALU_OP2  = ALU_OP2_X;
const alu_mode_t NOP_ALU_MODE = ALU_X;
const ma_mode_t  NOP_MA_MODE  = MA_X;
const ma_size_t  NOP_MA_SIZE  = MA_SIZE_X;
const word_t     NOP_MA_DATA  = 32'h00000000;
const regaddr_t  NOP_WB_ADDR  = 5'b00000;
const wb_src_t   NOP_WB_SRC   = WB_SRC_X;
const logic      NOP_WB_VALID = 1'b0;

endpackage
