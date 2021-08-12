`timescale 1ns / 1ps
`default_nettype none

package common;

//
// CPU Architecture
//

// PC Word Sizes
typedef logic [ 7:0] byte_t;
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
localparam opcode_t OP_LUI       = 7'b0110111; // Load Upper Immediate
localparam opcode_t OP_AUIPC     = 7'b0010111; // Add Upper Immediate To PC
localparam opcode_t OP_JAL       = 7'b1101111; // Jump And Link (use PC-ALU)
localparam opcode_t OP_JALR      = 7'b1100111; // Jump and Link Register
localparam opcode_t OP_BRANCH    = 7'b1100011; // Branch
localparam opcode_t OP_LOAD      = 7'b0000011; // Load
localparam opcode_t OP_STORE     = 7'b0100011; // Store
localparam opcode_t OP_IMM       = 7'b0010011; // Integer Register-Immediate Instructions
localparam opcode_t OP           = 7'b0110011; // Integer Register-Register Operations
localparam opcode_t OP_MISC_MEM  = 7'b0001111; // Miscellaneous Memory Operations
localparam opcode_t OP_SYSTEM    = 7'b1110011; // System Calls

// Funct3
typedef logic [2:0] funct3_t;

// Funct3 (OP_BRANCH)
localparam funct3_t F3_BEQ       = 3'b000;     // Branch if EQ
localparam funct3_t F3_BNE       = 3'b001;     // Branch if NE
localparam funct3_t F3_BLT       = 3'b100;     // Branch if LT (Signed)
localparam funct3_t F3_BGE       = 3'b101;     // Branch if GE (Signed)
localparam funct3_t F3_BLTU      = 3'b110;     // Branch if LT (Unsigned)
localparam funct3_t F3_BGEU      = 3'b111;     // Branch if GE (Unsigned)

// Funct3 (OP_LOAD)
localparam funct3_t F3_LB        = 3'b000;     // Load Byte (Signed Extended)
localparam funct3_t F3_LH        = 3'b001;     // Load Half-Word (Signed Extended)
localparam funct3_t F3_LW        = 3'b010;     // Load Word
localparam funct3_t F3_LBU       = 3'b100;     // Load Byte (Unsigned)
localparam funct3_t F3_LHU       = 3'b101;     // Load Half-Word (Unsigned)

// Funct3 (OP_STORE)
localparam funct3_t F3_SB        = 3'b000;     // Store Byte
localparam funct3_t F3_SH        = 3'b001;     // Store Half-Word
localparam funct3_t F3_SW        = 3'b010;     // Store Word

// Funct3 (OP_IMM and OP)
localparam funct3_t F3_ADD_SUB   = 3'b000;     // Addition or Subtraction
localparam funct3_t F3_SLT       = 3'b010;     // Signed Less-Than
localparam funct3_t F3_SLTU      = 3'b011;     // Signed Less-Than(Upper)
localparam funct3_t F3_XOR       = 3'b100;     // Binary XOR
localparam funct3_t F3_OR        = 3'b110;     // Binary OR
localparam funct3_t F3_AND       = 3'b111;     // Binary AND
localparam funct3_t F3_SLL       = 3'b001;     // Shift Left Logical
localparam funct3_t F3_SRL_SRA   = 3'b101;     // Shift Right Logical and Arithmetic

// Funct3 (OP_MISC_MEM)
localparam funct3_t F3_FENCE     = 3'b000;     // Fence
localparam funct3_t F3_FENCEI    = 3'b001;     // Fence Immediate

// Funct3 (OP_SYSTEM)
localparam funct3_t F3_PRIV      = 3'b000;     // Environment Call
localparam funct3_t F3_CSRRW     = 3'b001;     // Atomic R/W CSR
localparam funct3_t F3_CSRRS     = 3'b010;     // Atomic RSB CSR
localparam funct3_t F3_CSRRC     = 3'b011;     // Atomic RC CSR
localparam funct3_t F3_CSRRWI    = 3'b101;     // Atomic R/W Immedate CSR
localparam funct3_t F3_CSRRSI    = 3'b110;     // Atomic RSB Immedate CSR
localparam funct3_t F3_CSRRCI    = 3'b111;     // Atomic RC Immedate CSR

// Funct7
typedef logic [6:0] funct7_t;

// Funct12
typedef logic [11:0] funct12_t;
localparam funct12_t F12_ECALL   = 12'h000;     // Environment call
localparam funct12_t F12_EBREAK  = 12'h001;     // Environment breakpoint
localparam funct12_t F12_MRET    = 12'h302;     // M-mode return from trap
localparam funct12_t F12_SRET    = 12'h202;     // S-mode return from trap
localparam funct12_t F12_WFI     = 12'h105;     // Wait for interrupt


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

localparam ma_size_t MA_SIZE_X = MA_SIZE_W;

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
    logic      priv;
} control_word_t;


//
// NOP
//

localparam word_t     NOP_PC       = 32'hFFFFFFFF;
localparam word_t     NOP_IR       = 32'h00000013;
localparam alu_op1_t  NOP_ALU_OP1  = ALU_OP1_X;
localparam alu_op2_t  NOP_ALU_OP2  = ALU_OP2_X;
localparam alu_mode_t NOP_ALU_MODE = ALU_X;
localparam ma_mode_t  NOP_MA_MODE  = MA_X;
localparam ma_size_t  NOP_MA_SIZE  = MA_SIZE_X;
localparam word_t     NOP_MA_DATA  = 32'h00000000;
localparam regaddr_t  NOP_WB_ADDR  = 5'b00000;
localparam wb_src_t   NOP_WB_SRC   = WB_SRC_X;
localparam logic      NOP_WB_VALID = 1'b0;


//
// CSR Listing
//

// Machine Information Registers
localparam csr_t CSR_MVENDORID      = 12'hF11; // Implemented
localparam csr_t CSR_MARCHID        = 12'hF12; // Implemented
localparam csr_t CSR_MIMPID         = 12'hF13; // Implemented
localparam csr_t CSR_MHARTID        = 12'hF14; // Implemented

// Machine Trap Setup
localparam csr_t CSR_MSTATUS        = 12'h300; // Implemented
localparam csr_t CSR_MISA           = 12'h301; // Implemented
localparam csr_t CSR_MEDELEG        = 12'h302; // Not Applicable
localparam csr_t CSR_MIDELEG        = 12'h303; // Not Applicable
localparam csr_t CSR_MIE            = 12'h304; // Implemented
localparam csr_t CSR_MTVEC          = 12'h305; // Implemented
localparam csr_t CSR_MCOUNTEREN     = 12'h306; // Not Applicable
localparam csr_t CSR_MSTATUSH       = 12'h310; // Implemented

// Machine Trap Handling
localparam csr_t CSR_MSCRATCH       = 12'h340; // Implemented
localparam csr_t CSR_MEPC           = 12'h341; // Implemented
localparam csr_t CSR_MCAUSE         = 12'h342; // Implemented
localparam csr_t CSR_MTVAL          = 12'h343; // Implemented
localparam csr_t CSR_MIP            = 12'h344; // Implemented
localparam csr_t CSR_MTINST         = 12'h34A; // Implemented
localparam csr_t CSR_MTVAL2         = 12'h34B; // Implemented

// Machine Memory Protection
localparam csr_t CSR_PMPCFG0        = 12'h3A0; // Implemented
localparam csr_t CSR_PMPCFG15       = 12'h3AF; // Implemented
localparam csr_t CSR_PMPADDR0       = 12'h3B0; // Implemented
localparam csr_t CSR_PMPADDR63      = 12'h3EF; // Implemented

// Machine Counters/Timers
localparam csr_t CSR_MCYCLE         = 12'hB00; // Implemented
localparam csr_t CSR_MINSTRET       = 12'hB02; // Implemented
localparam csr_t CSR_MHPMCOUNTER3   = 12'hB03; // Not Implemented
localparam csr_t CSR_MHPMCOUNTER31  = 12'hB1F; // Not Implemented
localparam csr_t CSR_MCYCLEH        = 12'hB80; // Implemented
localparam csr_t CSR_MINSTRETH      = 12'hB82; // Implemented
localparam csr_t CSR_MHPMCOUNTER3H  = 12'hB83; // Not Implemented
localparam csr_t CSR_MHPMCOUNTER31H = 12'hB9F; // Not Implemented

// Machine Counter Setup
localparam csr_t CSR_MCOUNTINHIBIT  = 12'h320; // Implemented
localparam csr_t CSR_MHPMEVENT3     = 12'h323; // Not Implemented
localparam csr_t CSR_MHPMEVENT31    = 12'h33F; // Not Implemented

// Unprivileged Counters/Timers
localparam csr_t CSR_CYCLE          = 12'hC00; // Implemented
localparam csr_t CSR_TIME           = 12'hC01; // Implemented
localparam csr_t CSR_INSTRET        = 12'hC02; // Implemented
localparam csr_t CSR_HPMCOUNTER3    = 12'hC03; // Not Implemented
localparam csr_t CSR_HPMCOUNTER31   = 12'hC1F; // Not Implemented
localparam csr_t CSR_CYCLEH         = 12'hC80; // Implemented
localparam csr_t CSR_TIMEH          = 12'hC81; // Implemented
localparam csr_t CSR_INSTRETH       = 12'hC82; // Implemented
localparam csr_t CSR_HPMCOUNTER3H   = 12'hC83; // Not Implemented
localparam csr_t CSR_HPMCOUNTER31H  = 12'hC9F; // Not Implemented


//
// Exception Causes
//

typedef logic [30:0] exc_t;

localparam exc_t INT_S_SOFTWARE = 31'd1;
localparam exc_t INT_M_SOFTWARE = 31'd3;
localparam exc_t INT_S_TIMER    = 31'd5;
localparam exc_t INT_M_TIMER    = 31'd7;
localparam exc_t INT_S_EXTERNAL = 31'd9;
localparam exc_t INT_M_EXTERNAL = 31'd11;

localparam exc_t EXC_INSTR_MISALIGNED = 31'd0;
localparam exc_t EXC_INSTR_FAULT      = 31'd1;
localparam exc_t EXC_INSTR_ILLEGAL    = 31'd2;
localparam exc_t EXC_BREAKPOINT       = 31'd3;
localparam exc_t EXC_LOAD_MISALIGNED  = 31'd4;
localparam exc_t EXC_LOAD_FAULT       = 31'd5;
localparam exc_t EXC_STORE_MISALIGNED = 31'd6;
localparam exc_t EXC_STORE_FAULT      = 31'd7;
localparam exc_t ECALL_U              = 31'd8;
localparam exc_t ECALL_S              = 31'd9;
localparam exc_t ECALL_M              = 31'd11;
localparam exc_t EXC_PAGE_FAULT_INSTR = 31'd12;
localparam exc_t EXC_PAGE_FAULT_LOAD  = 31'd13;
localparam exc_t EXC_PAGE_FAULT_STORE = 31'd15;


//
// CSR Structures
//

typedef struct packed {
    logic       reserved_0;
    logic       sie;          // S-mode interrupt enable
    logic       reserved_2;
    logic       mie;          // M-mode interrupt enable
    logic       reserved_4;
    logic       spie;         // S-mode prior interrupt enable
    logic       ube;          // U-mode data endian (0=little-endian, 1=big-endian),
    logic       mpie;         // M-mode prior interrupt enable
    logic       spp;          // S-mode prior privilege level
    logic [1:0] reserved_9;
    logic [1:0] mpp;          // M-mode prior privilege level
    logic [1:0] fs;           // FPU State
    logic [1:0] xs;           // FPU State
    logic       mprv;         // Modify Privilege (0=current, 1=prior)
    logic       sum;          // Supervisor User Memory (N/A)
    logic       mxr;          // Make eXecutable Reader (0=r^x, 1=r|x)
    logic       tvm;          // Trap Virtual Memory
    logic       tw;           // Timeout Wait
    logic       tsr;          // Trap SRET
    logic [7:0] reserved_23;
    logic       sd;           // FPU State
} mstatus_t;

typedef struct packed {
    logic        reserved_0;
    logic        sbe;         // ZERO: S-mode data endian (0=little-endian, 1=big-endian)
    logic        mbe;         // ZERO: M-mode data endian (0=little-endian, 1=big-endian)
    logic [28:0] reserved_6;
} mstatush_t;

typedef enum logic {
    MTVEC_MODE_DIRECT   = 1'b0,
    MTVEC_MODE_VECTORED = 1'b1
} mtvec_mode_t;

typedef struct packed {
    mtvec_mode_t mode;
    logic        reserved_1;
    logic [29:0] base;
} mtvec_t;

typedef struct packed {
    logic [30:0] exception_code;
    logic        is_interrupt;
} mcause_t;

typedef enum logic [1:0] {
    PMPCFG_A_OFF =   2'b00, // Null Region
    PMPCFG_A_TOR   = 2'b01, // Top of Range
    PMPCFG_A_NA4   = 2'b10, // Naturally Aligned Four-Byte Region
    PMPCFG_A_NAPOT = 2'b11  // Naturally Aligned Power-of-Two Region
} matching_mode_t;

typedef struct packed {
    logic [2:0]     rwx;
    matching_mode_t matching_mode;
    logic [1:0]     reserved_5;
    logic           locked;
} pmpcfg_t;

typedef struct packed {
    word_t   addr;
    pmpcfg_t cfg;
} pmp_entry_t;

localparam logic [2:0] R = 3'b001;
localparam logic [2:0] W = 3'b010;
localparam logic [2:0] X = 3'b100;

typedef struct packed {
    logic        reserved_0;
    logic        ssi;         // System software interrupt
    logic        reserved_2;
    logic        msi;         // Machine software interrupt
    logic        reserved_3;
    logic        sti;         // System timer interrupt
    logic        reserved_6;
    logic        mti;         // Machine timer interrupt
    logic        reserved_8;
    logic        sei;         // System external interrupt
    logic        reserved_10;
    logic        mei;         // Machine external interrupt
    logic [ 3:0] reserved_12;
    logic [15:0] reserved_16;
} mi_t;


//
// Keyboard Events
//

typedef struct packed {
    byte_t scancode;
    logic  extended;
    logic  is_break;
} kbd_event_t;

endpackage
